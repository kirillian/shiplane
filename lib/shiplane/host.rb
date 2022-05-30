require 'sshkit'
require 'sshkit/dsl'

module Shiplane
  class Host
    extend Forwardable
    include SSHKit::DSL

    attr_accessor :env, :host, :role
    def_delegators :env, :servers
    def_delegators :role, :hostname

    SSHKIT_PROPERTIES = %i(user password keys hostname port ssh_options)

    def initialize(role, env)
      @role = role
      @env = env
    end

    def host
      @host ||= SSHKit::Host.new(sshkit_options)
    end

    def capistrano_role
      @capistrano_role ||= role.dup.tap do |r|
        r.properties.set(:ssh_options, ssh_options)
      end
    end

    def sshkit_values
      {
        interaction_handler: { "[sudo] password for #{user}: " => "#{password}\n" }
      }
    end

    def requires_sudo?
      @requires_sudo ||= config.fetch('requires_sudo', false)
    end

    private

    def user
      ssh_options.fetch("user", "")
    end

    def password
      ssh_options.fetch("password", "")
    end

    def sshkit_options
      @sshkit_options ||= options.merge(hostname: hostname).slice(*SSHKIT_PROPERTIES)
    end

    def options
      @options ||= role.properties.to_h.symbolize_keys.merge(ssh_options: ssh_options)
    end

    def ssh_options
      @ssh_options ||= config.fetch('ssh_options', {}).symbolize_keys
    end

    def config
      self.class.config.fetch('deploy', {}).fetch('servers', {}).fetch(hostname, {})
    end

    def with_context(&block)
      set(:shiplane_sshkit_values, sshkit_values)
      yield
      set(:shiplane_sshkit_values, nil)
    end

    def sshkit_output
      @sshkit_output ||= SSHKit.config.output
    end

    def write_message(verbosity, message)
      sshkit_output.write(SSHKit::LogMessage.new(verbosity, message))
    end

    def self.env_file
      config.fetch("bootstrap", {}).fetch('env_file', '.env')
    end

    def self.config
      @config ||= YAML.load(File.read(config_filepath), aliases: true)
    end

    def self.config_filepath
      File.join("shiplane.yml")
    end

    def self.bootstrap!(host, env)
      new(host, env).bootstrap!
    end
  end
end
