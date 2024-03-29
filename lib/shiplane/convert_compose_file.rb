require 'facets/hash/traverse'
require_relative 'configuration'
require_relative 'compose_hash'

module Shiplane
  class ConvertComposeFile
    extend Forwardable
    attr_accessor :project_folder, :sha
    attr_reader :shiplane_config

    delegate %i(build_config) => :shiplane_config

    def initialize(project_folder, sha, config: nil)
      @project_folder = project_folder
      @sha = sha
      @shiplane_config = config || Shiplane::Configuration.new
    end

    def compose_config
      @compose_config ||= build_config.fetch('compose', {})
    end

    def compose_filepath
      @compose_filepath ||= File.join(project_folder, build_config.fetch('compose_filepath', Shiplane::DEFAULT_COMPOSEFILE_FILEPATH))
    end

    def converted_compose_hash
      @converted_compose_hash ||= Shiplane::ComposeHash.new(File.new(compose_filepath), compose_config).production_yml
    end

    def converted_output
      @converted_output ||= converted_compose_hash.dup.tap do |hash|
        hash.traverse! do |key, value|
          if (key == 'env_file' && value == '.env.development')
            [key, '.env.production']
          else
            [key, value]
          end
        end
      end
    end

    def convert_output!
      puts "Converting Compose File..."
      File.write(compose_filepath, converted_output.to_yaml)
      puts "Compose File Converted..."
    end

    def self.convert_output!(project_folder, sha, config: nil)
      new(project_folder, sha, config: config).convert_output!
    end
  end
end
