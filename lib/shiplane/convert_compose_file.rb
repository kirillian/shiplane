require 'facets/hash/traverse'
require_relative 'configuration'
require_relative 'compose_hash'

module Shiplane
  class ConvertComposeFile
    extend Forwardable
    attr_accessor :project_folder, :sha

    delegate %i(build_config) => :shiplane_config

    def initialize(project_folder, sha)
      @project_folder = project_folder
      @sha = sha
    end

    def shiplane_config
      @shiplane_config ||= Shiplane::Configuration.new
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
        build_config.fetch('artifacts', {}).each do |(appname, config)|
          hash.deep_merge!({ 'services' => { appname => { 'image' => "#{config['repo']}:#{sha}" } } })
        end

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

    def self.convert_output!(project_folder, sha)
      new(project_folder, sha).convert_output!
    end
  end
end
