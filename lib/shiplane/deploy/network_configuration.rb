require_relative 'configuration'

module Shiplane
  module Deploy
    class NetworkConfiguration < Configuration
      def connections
        @connections ||= options.fetch(:connections, [])
      end

      def connect_commands(role)
        @connect_commands ||=
        connections.map do |connection|
          [
            docker_command(role),
            "network connect",
            name,
            connection,
            "|| true",
          ].flatten.compact.join(" ")
        end
      end

      def create_command(role)
        @create_command ||= [
          docker_command(role),
          "network create",
          name,
          "|| true",
        ].flatten.compact.join(" ")
      end

      def create_commands(role)
        [
          create_command(role),
          connect_commands(role),
        ].flatten
      end
    end
  end
end
