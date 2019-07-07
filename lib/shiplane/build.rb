require 'fileutils'
require 'dotenv'

require_relative 'checkout_artifact'
require_relative 'convert_compose_file'
require_relative 'convert_dockerfile'
require_relative 'configuration'

module Shiplane
  class Build
    extend Forwardable
    attr_accessor :sha, :postfix, :tag_latest

    delegate %i(build_config project_config) => :shiplane_config

    def initialize(sha, postfix:, tag_latest: false)
      @sha = sha
      @tag_latest = tag_latest
      @postfix = postfix

      Dotenv.overload File.join(Dir.pwd, build_config.fetch('environment_file', '.env'))
    end

    def appname
      @appname ||= project_config['appname']
    end

    def project_folder_name
      @project_folder_name ||= "#{appname}-#{sha}"
    end

    def project_folder
      @project_folder ||= File.join(Dir.pwd, 'docker_builds', appname, project_folder_name)
    end

    def shiplane_config
      @shiplane_config ||= Shiplane::Configuration.new
    end

    def docker_config
      @docker_config ||= YAML.load(File.new(File.join(project_folder, 'docker-compose.yml')))
    end

    def buildable_artifacts
      build_config.fetch('artifacts', {})
    end

    def build!
      unless File.exist?(File.join(project_folder, Shiplane::SHIPLANE_CONFIG_FILENAME))
        Shiplane::CheckoutArtifact.checkout!(sha)
        Shiplane::ConvertComposeFile.convert_output!(project_folder, sha)
      end

      buildable_artifacts.each do |(artifact_name, attributes)|
        compose_context = docker_config.fetch('services', {}).fetch(artifact_name.to_s, {})
        Shiplane::ConvertDockerfile.convert_output!(project_folder, attributes, compose_context)

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
      raise if ENV['RAISE_EXCEPTIONS_ON_FAILED_BUILD']
    end

    def steps(artifact_name, attributes)
      [
        { command: "docker-compose build --no-cache #{artifact_name}", notify_before: "Building Artifact: #{artifact_name}...", notify_after: "Docker Compose Built", stop_on_failure: true },
        { command: "docker tag #{attributes['repo']}:#{sha} #{attributes['repo']}:#{postfix}-#{sha}", notify_before: "Tagging Build...", stop_on_failure: true, condition: !!postfix },
        { command: "docker tag #{attributes['repo']}:#{sha} #{attributes['repo']}:#{postfix}-latest", notify_before: "Tagging Build...", stop_on_failure: true, condition: !!postfix && tag_latest },
        { command: "docker tag #{attributes['repo']}:#{sha} #{attributes['repo']}:latest", notify_before: "Tagging Latest Build...", stop_on_failure: true, condition: tag_latest },
        { command: "echo '#{ENV['DOCKERHUB_PASSWORD']}' | docker login --username #{ENV['DOCKERHUB_USERNAME']} --password-stdin", notify_before: "Logging into DockerHub...", stop_on_failure: true },
        { command: "docker push '#{attributes['repo']}:#{sha}'", notify_before: "Pushing Image", notify_after: "Completed Artifact: #{artifact_name}...", stop_on_failure: true },
        { command: "docker push '#{attributes['repo']}:#{postfix}-#{sha}'", notify_before: "Pushing #{postfix} Image", notify_after: "Completed Artifact: #{artifact_name}...", stop_on_failure: true, condition: !!postfix },
        { command: "docker push '#{attributes['repo']}:#{postfix}-latest'", notify_before: "Pushing Latest #{postfix} Image", notify_after: "Completed Latest Artifact: #{artifact_name}...", stop_on_failure: true, condition: !!postfix && tag_latest },
        { command: "docker push '#{attributes['repo']}:latest'", notify_before: "Pushing Latest Image", notify_after: "Completed Latest Artifact: #{artifact_name}...", stop_on_failure: true, condition: tag_latest },
      ]
    end

    def self.build!(sha, postfix = nil)
      new(sha, postfix: postfix).build!
    end

    def self.build_latest!(sha, postfix = nil)
      new(sha, postfix: postfix, tag_latest: true).build!
    end
  end
end

class StepFailureException < RuntimeError
  def initialize(command, artifact_name)
    message = "Command [#{command}] failed for artifact: #{artifact_name}" if artifact_name
    super(message)
  end
end
