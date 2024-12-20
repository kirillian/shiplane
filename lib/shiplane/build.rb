require 'fileutils'
require 'dotenv'

require_relative 'checkout_artifact'
require_relative 'convert_compose_file'
require_relative 'convert_dockerfile'
require_relative 'configuration'
require_relative 'safe_yaml_loading'

module Shiplane
  class Build
    extend Forwardable
    attr_accessor :sha, :postfix, :tag_latest, :stage, :build_environment_variables, :run_folder

    delegate %i(build_config project_config build_environment_filepath) => :shiplane_config

    def initialize(sha, postfix:, tag_latest: false, stage: nil)
      @sha = sha
      @tag_latest = tag_latest
      @postfix = postfix
      @stage = stage
      @run_folder = Dir.pwd

      Dotenv.overload File.join(Dir.pwd, build_environment_filepath)

      # Add any ENV variable overrides from the capistrano configuration
      build_environment_variables = fetch(:shiplane_build_environment_variables, {})
      build_environment_variables.each do |key, value|
        if value.is_a? Proc
          ENV[key.to_s] = value.call
        else
          ENV[key.to_s] = value
        end
      end
    end

    def build!
      unless File.exist?(File.join(project_folder, Shiplane::SHIPLANE_CONFIG_FILENAME))
        Shiplane::CheckoutArtifact.checkout!(sha, config: shiplane_config)
        Shiplane::ConvertComposeFile.convert_output!(project_folder, sha, config: shiplane_config)
      end

      buildable_artifacts.each do |(artifact_name, attributes)|
        compose_context = docker_config.fetch('services', {}).fetch(artifact_name.to_s, {})
        Shiplane::ConvertDockerfile.convert_output!(project_folder, attributes, compose_context, config: shiplane_config)

        FileUtils.cd project_folder do
          steps(artifact_name, attributes).select{|step| step.fetch(:condition, true) }.each do |step|
            puts step[:notify_before] if step.has_key? :notify_before
            success = system(step[:command])
            raise StepFailureException.new(step[:command], artifact_name) unless success
            puts step[:notify_after] if step.has_key? :notify_after
          end
        end
      end
    rescue StepFailureException => e
      puts e.message
      raise if ENV['RAISE_EXCEPTIONS_ON_FAILED_BUILD'] == 'true'
    end

    def steps(artifact_name, attributes)
      [
        { command: build_command(artifact_name), notify_before: "Building Artifact: #{artifact_name}...", notify_after: "Docker Compose Built", stop_on_failure: true },
        { command: tag_command(artifact_name, attributes, sha), notify_before: "Tagging Build [#{sha}]...", stop_on_failure: true },
        { command: tag_command(artifact_name, attributes, "#{postfix}-#{sha}"), notify_before: "Tagging Build [#{postfix}-#{sha}]...", stop_on_failure: true, condition: !!postfix },
        { command: tag_command(artifact_name, attributes, "#{postfix}-latest"), notify_before: "Tagging Build [#{postfix}-latest]...", stop_on_failure: true, condition: !!postfix && tag_latest },
        { command: tag_command(artifact_name, attributes), notify_before: "Tagging Build [latest]...", stop_on_failure: true, condition: tag_latest },
        { command: token_login_command , notify_before: "Logging into Container Registry...", stop_on_failure: true },
        { command: push_command(attributes, "#{sha}"), notify_before: "Pushing Image", notify_after: "Completed Artifact: #{artifact_name}...", stop_on_failure: true },
        { command: push_command(attributes, "#{postfix}-#{sha}"), notify_before: "Pushing #{postfix} Image", notify_after: "Completed Artifact: #{artifact_name}...", stop_on_failure: true, condition: !!postfix },
        { command: push_command(attributes, "#{postfix}-latest"), notify_before: "Pushing Latest #{postfix} Image", notify_after: "Completed Latest Artifact: #{artifact_name}...", stop_on_failure: true, condition: !!postfix && tag_latest },
        { command: push_command(attributes, "latest"), notify_before: "Pushing Latest Image", notify_after: "Completed Latest Artifact: #{artifact_name}...", stop_on_failure: true, condition: tag_latest },
      ]
    end

    # Commands
    def build_command(artifact_name)
      [
        'docker-compose',
        '-f',
        docker_compose_filepath,
        '--env-file',
        File.join(run_folder, build_environment_filepath),
        'build',
        build_cache_option,
        artifact_name,
      ].compact.join(' ')
    end

    def token_login_command
      @token_login_command ||= [
        'echo',
        "\"#{login_token}\"",
        '|',
        'docker',
        'login',
        registry_url,
        '--username',
        login_username,
        '--password-stdin',
      ].compact.join(' ')
    end

    def tag_command(artifact_name, attributes, tag='latest')
      [
        'docker',
        'tag',
        build_output_image_name(artifact_name),
        "#{repo_name(attributes)}:#{tag}",
      ].compact.join(' ')
    end

    def push_command(attributes, tag='latest')
      [
        'docker',
        'push',
        "#{repo_name(attributes)}:#{tag}",
      ].compact.join(' ')
    end

    # Properties
    def appname
      @appname ||= project_config['appname']
    end

    def project_folder_name
      @project_folder_name ||= "#{appname}-#{sha}"
    end

    def project_folder
      @project_folder ||= File.join(run_folder, 'docker_builds', appname, project_folder_name)
    end

    def shiplane_config
      @shiplane_config ||= Shiplane::Configuration.new(stage: stage)
    end

    def docker_compose_filepath
      @docker_compose_filepath ||= File.join(project_folder, 'docker-compose.yml')
    end

    def docker_config
      @docker_config ||= Shiplane::SafeYamlLoading.load_file(docker_compose_filepath)
    end

    def buildable_artifacts
      build_config.fetch('artifacts', {})
    end

    def default_registry_configuration
      {
        'url' => :dockerhub,
        'auth_method' => 'token',
      }
    end

    def dockerhub?
      registry_configuration['url'].to_s == 'dockerhub'
    end

    def token_auth?
      registry_configuration['auth_method'] == 'token'
    end

    def registry_configuration
      @registry_configuration ||= default_registry_configuration.merge(build_config.fetch('registry', {}))
    end

    def registry_url
      @registry_url ||= dockerhub? ? nil : registry_configuration['url']
    end

    def repo_name(attributes)
      [
        registry_url,
        attributes['repo'],
      ].compact.join('/')
    end

    def login_token
      return ENV['DOCKERHUB_PASSWORD'] if dockerhub? && token_auth?

      ENV['SHIPLANE_CONTAINER_REGISTRY_TOKEN']
    end

    def login_username
      return ENV['DOCKERHUB_USERNAME'] if dockerhub? && token_auth?

      ENV['SHIPLANE_CONTAINER_REGISTRY_USERNAME']
    end

    def build_output_image_name(artifact_name)
      @build_output_image_name ||= "#{appname}-#{sha}#{docker_compose_separator}#{artifact_name}:latest"
    end

    def build_cache_option
      ENV['USE_BUILD_CACHE'] == 'true' ? nil : "--no-cache"
    end

    def docker_compose_separator
      return '_' if ENV['DOCKER_COMPOSE_V1_COMPATIBILITY'] && ENV['DOCKER_COMPOSE_V1_COMPATIBILITY'] == 'true'

      '-'
    end

    # API Helper Methods
    def self.build!(sha, postfix: nil, stage: nil)
      new(sha, postfix: postfix, stage: stage).build!
    end

    def self.build_latest!(sha, postfix: nil, stage: nil)
      new(sha, postfix: postfix, tag_latest: true, stage: stage).build!
    end
  end
end

class StepFailureException < RuntimeError
  def initialize(command, artifact_name, error_message: nil)
    message = "Command [#{command}] failed for artifact: #{artifact_name}#{error_message ? "\nError Message Received: #{error_message}" : ''}" if artifact_name
    super(message)
  end
end
