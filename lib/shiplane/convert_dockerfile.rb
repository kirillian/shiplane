require_relative 'configuration'

module Shiplane
  class ConvertDockerfile
    extend Forwardable
    attr_accessor :artifact_context, :compose_context, :project_folder
    attr_reader :shiplane_config

    delegate %i(build_config project_config) => :shiplane_config

    def initialize(project_folder, artifact_context, compose_context, config: nil)
      @project_folder = project_folder
      @artifact_context = artifact_context
      @compose_context = compose_context
      @shiplane_config = config || Shiplane::Configuration.new
    end

    def appname
      @appname ||= project_config['appname']
    end

    def dockerfile_name
      @dockerfile_name ||= compose_context.fetch('build', {}).fetch('context', '.').tap do |filename|
        filename.gsub!(/^\.$/, 'Dockerfile')
      end
    end

    def dockerfile_filepath
      @dockerfile_filepath ||= File.join(project_folder, dockerfile_name)
    end

    def dockerfile_production_stages_filepath
      @dockerfile_production_stages_filepath ||= File.join(Dir.pwd, build_config.fetch('settings_folder', '.shiplane'), Shiplane::DEFAULT_PRODUCTION_DOCKERFILE_STAGES_FILEPATH)
    end

    def entrypoint
      @entrypoint ||= artifact_context.fetch('command', compose_context.fetch('command', "bin/rails s"))
    end

    def converted_output
      @converted_output ||= [
        File.read(dockerfile_filepath),
        File.read(dockerfile_production_stages_filepath),
        # "ENTRYPOINT #{entrypoint}",
      ].join("\n\n")
    end

    def convert_output!
      puts "Converting Dockerfile..."
      File.write(dockerfile_filepath, converted_output)
      puts "Dockerfile Converted..."
    end

    def self.convert_output!(project_folder, artifact_context, compose_context, config: nil)
      new(project_folder, artifact_context, compose_context, config: config).convert_output!
    end
  end
end
