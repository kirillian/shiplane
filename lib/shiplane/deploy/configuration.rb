module Shiplane
  module Deploy
    class Configuration
      attr_accessor :env, :name, :options

      def initialize(name, options, env)
        @name = name
        @options = options
        @env = env
      end

      def docker_command(role)
        role.requires_sudo? ? "sudo docker" : "docker"
      end
    end
  end
end
