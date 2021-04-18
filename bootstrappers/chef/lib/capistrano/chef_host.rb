require 'shiplane/host'
require_relative './chef_error_parser'

module Shiplane
  class ChefHost < Host
    include Airbrussh::Colors

    REMOTE_CHEF_FOLDER_PATH = File.join("/var","chef")
    LOCAL_CHEF_FOLDER_PATH = File.expand_path("../../../lib/chef", __FILE__)
    COOKBOOKS_FILE_NAME = "cookbooks.tar.gz"
    LOCAL_COOKBOOKS_FILE_PATH = File.expand_path("../../../#{COOKBOOKS_FILE_NAME}", __FILE__)
    REMOTE_COOKBOOKS_FILE_PATH = File.join(REMOTE_CHEF_FOLDER_PATH, COOKBOOKS_FILE_NAME)
    CHEF_PACKAGE_NAME = config.fetch("bootstrap", {}).fetch("chef-bootstrapper", {}).fetch("package_name")
    CHEF_PACKAGE_DOWNLOAD_URL = config.fetch("bootstrap", {}).fetch("chef-bootstrapper", {}).fetch("package_url")
    APT_PACKAGES = %w(build-essential wget)

    def install
      with_context do
        SSHKit::Coordinator.new(host).each in: :parallel do
          context_variables = fetch(:shiplane_sshkit_values)

          install_started = test("[ -f #{File.join(Shiplane::ChefHost::REMOTE_CHEF_FOLDER_PATH, '.install-started')} ]")
          install_finished = test("[ -f #{File.join(Shiplane::ChefHost::REMOTE_CHEF_FOLDER_PATH, '.install')} ]")

          if install_started && !install_finished
            execute :sudo, :dpkg, '--configure', '-a', interaction_handler: context_variables[:interaction_handler]
            # execute :sudo, :dpkg, "--remove", "--force-remove-reinstreq", *Shiplane::ChefHost::APT_PACKAGES - %w(wget build-essential), interaction_handler: context_variables[:interaction_handler]
          end

          unless install_finished
            execute :sudo, :sysctl, "-w", "net.ipv6.conf.all.disable_ipv6=1", interaction_handler: context_variables[:interaction_handler]
            execute :sudo, :sysctl, "-w", "net.ipv6.conf.default.disable_ipv6=1", interaction_handler: context_variables[:interaction_handler]
            execute :sudo, :mkdir, '-m', '2777', '-p', Shiplane::ChefHost::REMOTE_CHEF_FOLDER_PATH, interaction_handler: context_variables[:interaction_handler]
            execute :sudo, :touch, File.join(Shiplane::ChefHost::REMOTE_CHEF_FOLDER_PATH, '.install-started'), interaction_handler: context_variables[:interaction_handler]
            execute :sudo, 'apt-get', 'update', interaction_handler: context_variables[:interaction_handler]
            execute :sudo, 'apt-get', 'install', '-y', *Shiplane::ChefHost::APT_PACKAGES, interaction_handler: context_variables[:interaction_handler]
            execute :wget, Shiplane::ChefHost::CHEF_PACKAGE_DOWNLOAD_URL
            execute :sudo, :dpkg, '-i', Shiplane::ChefHost::CHEF_PACKAGE_NAME, interaction_handler: context_variables[:interaction_handler]
            execute :sudo, :ls, '-al', Shiplane::ChefHost::REMOTE_CHEF_FOLDER_PATH, interaction_handler: context_variables[:interaction_handler]
            execute :sudo, :touch, File.join(Shiplane::ChefHost::REMOTE_CHEF_FOLDER_PATH, '.install'), interaction_handler: context_variables[:interaction_handler]
            execute :sudo, :sysctl, "-w", "net.ipv6.conf.all.disable_ipv6=0", interaction_handler: context_variables[:interaction_handler]
            execute :sudo, :sysctl, "-w", "net.ipv6.conf.default.disable_ipv6=0", interaction_handler: context_variables[:interaction_handler]
          end
        end
      end
    end

    def reinstall
      with_context do
        SSHKit::Coordinator.new(host).each in: :parallel do
          context_variables = fetch(:shiplane_sshkit_values)

          if(test("[ -f #{File.join(Shiplane::ChefHost::REMOTE_CHEF_FOLDER_PATH, '.install')} ]"))
            execute :sudo, :rm, File.join(Shiplane::ChefHost::REMOTE_CHEF_FOLDER_PATH, '.install'), interaction_handler: context_variables[:interaction_handler]
          end
        end
      end
    end

    def configure
      with_context do
        errors = {}
        SSHKit::Coordinator.new(host).each in: :parallel do |h|
          context_variables = fetch(:shiplane_sshkit_values)

          begin
            execute :sudo, 'chef-solo', '-c', "#{Shiplane::ChefHost::REMOTE_CHEF_FOLDER_PATH}/solo.rb", "--chef-license", "accept", interaction_handler: context_variables[:interaction_handler]
          rescue => e
            errors["#{h}"] = Shiplane::ChefErrorParser.parse(e)
          end
        end

        unless errors.empty?
          write_message(SSHKit::Logger::ERROR, "#{errors.keys.size} Errors encountered:")
          errors.each do |h, trace|
            write_message SSHKit::Logger::INFO, "~" * 80
            write_message SSHKit::Logger::INFO, green("Server: #{h}")
            trace.each do |line|
              write_message SSHKit::Logger::INFO, line
            end
            write_message SSHKit::Logger::INFO, "~" * 80
          end
        end
      end
    end
  end
end
