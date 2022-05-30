require_relative 'extensions'

module Shiplane
  class ComposeHash
    attr_accessor :compose_file, :production_config

    def initialize(compose_file, production_config)
      @compose_file = compose_file
      @production_config = production_config
    end

    def production_yml
      blacklisted_nodes.inject(whitelisted_hash){ |acc, node| acc.blacklist(node) }
    end

    def compose_hash
      @compose_hash ||= YAML.load(compose_file, aliases: true)
    end

    def whitelisted_hash
      @whitelisted_hash ||= compose_hash.whitelist(*default_whitelisted_nodes, *whitelisted_nodes)
    end

    def blacklisted_nodes
      @blacklisted_nodes ||= production_config.fetch('blacklist', [])
    end

    def whitelisted_nodes
      @whitelisted_nodes ||= production_config.fetch('whitelist', [])
    end

    def default_whitelisted_nodes
      [
        "version",
      ]
    end
  end
end
