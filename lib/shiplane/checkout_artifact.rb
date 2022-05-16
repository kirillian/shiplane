require 'fileutils'

module Shiplane
  class CheckoutArtifact
    extend Forwardable
    attr_accessor :sha
    attr_reader :shiplane_config

    delegate %i(build_config project_config) => :shiplane_config

    def initialize(sha, config: nil)
      @sha = sha
      @shiplane_config = config || Shiplane::Configuration.new

      # call this before changing directories.
      # This prevents race conditions where the config file is accessed before being downloaded
      @shiplane_config
    end

    def appname
      @appname ||= project_config['appname']
    end

    def bitbucket_origin?
      project_config['version_control_host'] == 'bitbucket'
    end

    def github_origin?
      project_config['version_control_host'] == 'github'
    end

    def github_token
      @github_token ||= ENV['GITHUB_TOKEN']
    end

    def bitbucket_token
      @bitbucket_token ||= ENV['BITBUCKET_APP_PASSWORD']
    end

    def bitbucket_username
      @bitbucket_username ||= ENV['BITBUCKET_APP_USERNAME']
    end

    def git_url
      return github_url if github_origin?
      return bitbucket_url if bitbucket_origin?
    end

    def github_url
      "https://#{github_token ? "#{github_token}@" : ''}github.com/#{project_config['origin']}/archive/#{sha}.tar.gz"
    end

    def bitbucket_url
      "https://#{bitbucket_token ? "#{bitbucket_username}:#{bitbucket_token}@" : ''}bitbucket.org/#{project_config['origin']}/get/#{sha}.tar.gz"
    end

    def app_directory
      @app_directory ||= File.join(Dir.pwd, 'docker_builds', appname)
    end

    def build_directory
      @build_directory ||= File.join(app_directory, "#{appname}-#{sha}")
    end

    def make_directory
      FileUtils.mkdir_p app_directory
    end

    def checkout!
      return if File.exist?(File.join(build_directory, Shiplane::SHIPLANE_CONFIG_FILENAME))

      puts "Checking out Application #{appname}[#{sha}]..."
      make_directory

      success = system("echo 'Downloading #{git_url}/archive/#{sha}.tar.gz --output #{archive_filename}'")
      success = success && download_archive
      success = success && unpack_archive

      raise "Errors encountered while downloading archive" unless success
      puts "Finished checking out Application"
      tasks.each(&method(:send))
    end

    def archive_filename
      @archive_filename ||= "#{appname}-#{sha}.tar.gz"
    end

    def archive_path
      @archive_path ||= File.join(app_directory, archive_filename)
    end

    def download_archive
      return true if File.exist? archive_path

      system("curl -L #{git_url} --output #{archive_path}")
    end

    def unpack_archive
      FileUtils.rm_rf(build_directory) if File.directory?(build_directory)
      FileUtils.mkdir_p build_directory

      success = true
      FileUtils.cd app_directory do
        success = success && system("tar -xzf #{appname}-#{sha}.tar.gz -C .")
      end
      success
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
              FileUtils.mkdir_p File.join(build_directory, File.dirname(filepath))
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

    def self.checkout!(sha, config: nil)
      new(sha, config: config).checkout!
    end
  end
end
