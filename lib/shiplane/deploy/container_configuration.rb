require_relative 'configuration'

module Shiplane
  module Deploy
    class ContainerConfiguration < Configuration
      def network_alias
        @network_alias ||= options.fetch(:alias, container_name)
      end

      def volumes
        @volumes ||= options.fetch(:volumes, [])
      end

      def published_ports
        @published_ports ||= [options.fetch(:publish, [])].flatten
      end

      def exposed_ports
        @exposed_ports ||= [options.fetch(:expose, [])].flatten - published_ports
      rescue => e
        binding.pry
      end

      def container_name
        @container_name ||= "#{env.fetch(:application)}_#{name}_#{env.fetch(:sha)}"
      end

      def image_name
        @image_name ||= "#{options.fetch(:repo)}:#{image_tag}"
      end

      def image_tag
        @image_tag ||= options.fetch(:tag, "#{env.fetch(:stage)}-#{env.fetch(:sha)}")
      end

      def virtual_host
        @virtual_host ||= options[:virtual_host]
      end

      def letsencrypt_host
        @letsencrypt_host ||= options.fetch(:letsencrypt_host, virtual_host)
      end

      def letsencrypt_email
        @letsencrypt_email ||= options[:letsencrypt_email]
      end

      def networks
        @networks ||= options.fetch(:networks, [])
      end

      def startup_command
        @startup_command ||= options[:command]
      end

      def network_connect_commands(role)
        @network_commands ||= networks.map do |network|
          [
            docker_command(role),
            "network connect",
            "--alias #{network_alias}",
            network,
            container_name,
            "|| true",
          ].flatten.compact.join(" ")
        end
      end

      def run_command(role)
        @command ||= [
          docker_command(role),
          "run -d",
          volumes.map{|volume_set| "-v #{volume_set}" },
          published_ports.map{|port| "--expose #{port} -p #{port}" },
          exposed_ports.map{|port| "--expose #{port}" },
          "--name #{container_name}",
          virtual_host ? "-e VIRTUAL_HOST=#{virtual_host}" : nil,
          letsencrypt_host ? "-e LETSENCRYPT_HOST=#{letsencrypt_host}" : nil,
          letsencrypt_email ? "-e LETSENCRYPT_EMAIL=#{letsencrypt_email}" : nil,
          image_name,
          startup_command ? startup_command : nil,
        ].flatten.compact.join(" ")
      end

      def run_commands(role)
        @run_commands ||= [
          run_command(role),
          network_connect_commands(role),
        ].flatten
      end
    end
  end
end
