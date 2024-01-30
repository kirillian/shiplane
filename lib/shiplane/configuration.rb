require_relative 'safe_yaml_loading'

module Shiplane
  class Configuration
    attr_accessor :project_folder, :stage

    def initialize(project_folder: nil, stage: 'production')
      @project_folder = project_folder || Dir.pwd
      @stage = stage
    end

    def shiplane_config_file
      @shiplane_config_file ||= File.join(project_folder, Shiplane::SHIPLANE_CONFIG_FILENAME)
    end

    def config
      @config ||= Shiplane::SafeYamlLoading.load_file(shiplane_config_file)
    end

    def build_config
      @build_config ||= config.fetch('build', {})
    end

    def bootstrap_config
      @bootstrap_config ||= config.fetch('bootstrap', {})
    end

    def deploy_config
      @deploy_config ||= config.fetch('deploy', {})
    end

    def project_config
      @project_config ||= config.fetch('project', {})
    end

    def build_environment_filepath
      return @build_environment_filepath if defined? @build_environment_filepath

      @build_environment_filepath = build_config.fetch('environment_file', '.env')
      @build_environment_filepath = File.join(project_folder, "#{@build_environment_filepath}.#{stage}") if File.exist?(File.join(project_folder, "#{@build_environment_filepath}.#{stage}"))

      @build_environment_filepath
    end

    def self.config(project_folder = nil)
      new(project_folder).config
    end
  end
end
