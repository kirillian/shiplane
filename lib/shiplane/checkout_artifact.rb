require 'fileutils'
require 'open3'

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

    def current_sha
      stdout, *_ = Open3.capture3("git rev-parse HEAD")

      stdout
    end

    def current_short_sha
      stdout, *_ = Open3.capture3("git rev-parse --short HEAD")

      stdout
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
      @bitbucket_token ||= ENV['BITBUCKET_TOKEN']
    end

    def bitbucket_username
      @bitbucket_username ||= ENV['BITBUCKET_USERNAME']
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

      success = send(checkout_strategy[:method])

      raise "Errors encountered while downloading archive" unless success
      puts "Finished checking out Application"
      tasks.each(&method(:send))
    end

    def checkout_strategies
      @checkout_strategies ||= [
        { method: :archive_and_unpack_commit, conditions: -> { commit_exists? } },
        { method: :download_archive, conditions: -> { !bitbucket_origin? } },
        { method: :checkout_via_git, conditions: -> { true } },
      ]
    end

    def checkout_strategy
      @checkout_strategy ||= checkout_strategies.find{|strategy| strategy[:conditions].call }
    end

    def archive_filename
      @archive_filename ||= "#{appname}-#{sha}.tar.gz"
    end

    def archive_path
      @archive_path ||= File.join(app_directory, archive_filename)
    end

    def download_archive
      puts "Downloading #{git_url} --output #{archive_filename}"
      puts "Deploying SHA different from current version. Checking out from Git Repository"

      success = system("curl -L #{git_url} --output #{archive_path}")
      success && unpack_archive
    end

    def git_host_url
      return "bitbucket.org" if bitbucket_origin?
      return "github.com" if github_origin?

      # TODO
      raise 'Gitlab needs fixing'
    end

    def target_sha_is_current?
      sha == current_short_sha.strip || sha == current_sha.strip
    end

    def copy_current_directory
      puts "Current directory is target SHA. Copying for build"

      FileUtils.cp_r(".", build_directory)
    end

    def archive_and_unpack_commit
      puts "Creating archive from local git repo in #{archive_filename}..."
      success = system("git archive --format=tar.gz -o #{archive_path} #{sha}")

      puts "Unpacking archive to #{build_directory}..."
      FileUtils.rm_rf(build_directory) if File.directory?(build_directory)
      FileUtils.mkdir_p build_directory

      success && system("(cd #{app_directory} && tar -xzf #{appname}-#{sha}.tar.gz -C #{build_directory})")
    end

    def git_clone_url
      "https://#{bitbucket_username}:#{bitbucket_token}@#{git_host_url}/#{project_config['origin']}.git"
    end

    def target_sha_is_current?
      sha == current_short_sha.strip || sha == current_sha.strip
    end

    def commit_exists?
      system("git rev-parse #{sha}")
    end

    def checkout_via_git
      FileUtils.rm_rf(build_directory) if File.directory?(build_directory)
      FileUtils.mkdir_p build_directory

      success = true
      puts "Cloning from #{git_clone_url}..."
      success = success && system("git clone --depth=1 #{git_clone_url} #{build_directory}")
      FileUtils.cd build_directory do
        puts "Fetching Single SHA"
        fetch_success = system("git fetch origin #{sha} && git reset --hard FETCH_HEAD")

        unless fetch_success
          puts "Unable to fetch single commit. Fetching FULL history"
          fetch_success = system("git fetch --unshallow && git fetch origin #{sha} && git reset --hard #{sha}")
        end

        success = success && fetch_success

        puts "Removing Git folders before building..."
        success = success && FileUtils.rm_rf("#{build_directory}/.git")
      end
      success
    end

    def unpack_archive
      puts "Unpacking archive to #{build_directory}..."
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
