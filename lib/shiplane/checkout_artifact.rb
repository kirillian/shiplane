require 'fileutils'

module Shiplane
  class CheckoutArtifact
    extend Forwardable
    attr_accessor :sha

    delegate %i(build_config project_config) => :shiplane_config

    def initialize(sha)
      @sha = sha

      # call this before changing directories.
      # This prevents race conditions where the config file is accessed before being downloaded
      shiplane_config
    end

    def appname
      @appname ||= project_config['appname']
    end

    def shiplane_config
      @shiplane_config ||= Shiplane::Configuration.new
    end

    def github_token
      @github_token ||= ENV['GITHUB_TOKEN']
    end

    def git_url
      "https://#{github_token ? "#{github_token}@" : ''}github.com/#{project_config['origin']}"
    end

    def app_directory
      @app_directory ||= File.join(Dir.pwd, 'docker_builds', appname)
    end

    def build_directory
      @build_directory ||= File.join(app_directory, "#{appname}-#{sha}")
    end

    def make_directory
      FileUtils.mkdir_p build_directory
    end

    def checkout!
      return if File.exist?(File.join(build_directory, Shiplane::SHIPLANE_CONFIG_FILENAME))

      puts "Checking out Application #{appname}[#{sha}]..."
      make_directory

      success = true
      FileUtils.cd app_directory do
        success = success && system("echo 'Downloading #{git_url}/archive/#{sha}.tar.gz --output #{appname}-#{sha}.tar.gz'")
        success = success && system("curl -L #{git_url}/archive/#{sha}.tar.gz --output #{appname}-#{sha}.tar.gz")
        success = success && system("tar -xzf #{appname}-#{sha}.tar.gz -C .")
      end

      raise "Errors encountered while downloading archive" unless success
      puts "Finished checking out Application"
      tasks.each(&method(:send))
    end

    def tasks
      [:make_directories, :copy_env_files, :copy_insert_on_build_files, :unignore_required_directories]
    end

    def make_directories
      FileUtils.cd build_directory do
        required_directories.each do |directory|
          FileUtils.mkdir_p directory
        end
      end
    end

    def copy_env_files
      puts "Copying in environment files..."
      FileUtils.cp File.join(Dir.pwd, build_config.fetch('environment_file', '.env')), File.join(build_directory, '.env')
      puts "Environment Files Copied"
    end

    def copy_insert_on_build_files
      puts "Copying application configuration files..."

      if Dir.exist? File.join(build_config.fetch('settings_folder', '.shiplane'), "insert_on_build")
        FileUtils.cd File.join(build_config.fetch('settings_folder', '.shiplane'), "insert_on_build") do
          Dir["*/**"].each do |filepath|
            if File.extname(filepath) == ".erb"
              copy_erb_file(filepath)
            else
              FileUtils.mkdir_p File.join(build_directory, filepath)
              FileUtils.cp filepath, File.join(build_directory, filepath)
            end
          end
        end
      end
      puts "Configuration Files Copied"
    end

    def copy_erb_file(filepath)
      File.write(File.join(build_directory, filepath.gsub(".erb","")), ERB.new(File.read(filepath)).result, mode: 'w')
    end

    def unignore_required_directories
      puts "Adding Required Directories as explicit inclusions in ignore file..."
      File.open(File.join(build_directory, '.dockerignore'), 'a') do |file|
        required_directories.each do |directory|
          file.puts "!#{directory}/*"
        end
      end
      puts "Finished including required directories..."
    end

    def required_directories
      ['vendor']
    end

    def self.checkout!(sha)
      new(sha).checkout!
    end
  end
end
