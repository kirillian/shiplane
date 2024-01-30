require 'yaml'

module Shiplane
  class SafeYamlLoading
    def self.load_file(filepath)
      load(File.read(filepath))
    end

    def self.load_with_aliases(yaml)
      YAML.load(yaml, aliases: true)
    end

    def self.load_without_aliases(yaml)
      YAML.load(yaml)
    end

    if Psych && Gem::Version.new(Psych::VERSION) > Gem::Version.new("4.0.0")
      define_singleton_method :load, method(:load_with_aliases)
    else
      define_singleton_method :load, method(:load_without_aliases)
    end
  end
end
