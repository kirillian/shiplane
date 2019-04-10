module Shiplane
  class Configuration
    attr_accessor :project_folder

    def initialize(project_folder = nil)
      @project_folder = project_folder || Dir.pwd
    end

    def shiplane_config_file
      @shiplane_config_file ||= File.join(project_folder, Shiplane::SHIPLANE_CONFIG_FILENAME)
    end

    def config
      @config ||= YAML.load_file(shiplane_config_file)
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

    def self.config(project_folder = nil)
      new(project_folder).config
    end
  end
end
