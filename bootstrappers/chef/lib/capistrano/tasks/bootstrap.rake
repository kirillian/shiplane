require 'dotenv'
require_relative '../chef_host'
require 'open3'
require 'pry'

namespace :shiplane do
  namespace :bootstrap do
    # task :prepare do
    # end

    task :install do
      fetch(:shiplane_hosts).each do |host|
        host.install
      end
    end

    task configure: %i(evaluate_erb_files rsync_chef_configuration upload_cookbooks rsync_custom_configuration fix_file_permissions) do
      fetch(:shiplane_hosts).each do |host|
        host.configure
      end
    end

    # task :prepare_files do |task, args|
    #   rm_r Shiplane::ChefHost::LOCAL_COOKBOOKS_FOLDER_PATH, force: true
    #   cp_r File.join(Shiplane::ChefHost::LOCAL_SITE_BERKS_COOKBOOKS_FOLDER_PATH, '.'), Shiplane::ChefHost::LOCAL_COOKBOOKS_FOLDER_PATH
    #   cp_r File.join(Shiplane::ChefHost::LOCAL_SITE_COOKBOOKS_FOLDER_PATH, '.'), Shiplane::ChefHost::LOCAL_COOKBOOKS_FOLDER_PATH
    # end

    # task :cleanup do
    # end

    task :evaluate_erb_files, :username, :keypath do |task, args|
      dotenv_filename = Shiplane::ChefHost.env_file
      dotenv_filename = "#{dotenv_filename}.#{fetch(:stage)}" if File.exist?("#{dotenv_filename}.#{fetch(:stage)}")

      Dotenv.load dotenv_filename

      on fetch(:shiplane_hosts).map(&:capistrano_role) do |host|
        @shiplane_users = [
          "docker",
          host.user,
        ].compact.uniq.join("\",\"")

        Dir["#{File.expand_path("../../../chef", __FILE__)}/**/*.erb"].map do |filename|
          compiled_template = ERB.new(File.read(filename)).result(binding)
          compiled_file_name = filename.match(/.*\/chef\/(.*)\.erb/)[1]

          sudo :mkdir, '-m', '777', '-p', File.join(Shiplane::ChefHost::REMOTE_CHEF_FOLDER_PATH, File.dirname(compiled_file_name))
          execute :sudo, :rm, '-f', File.join(Shiplane::ChefHost::REMOTE_CHEF_FOLDER_PATH, compiled_file_name), interaction_handler: { "[sudo] password for #{host.netssh_options.fetch(:user)}: " => "#{host.netssh_options.fetch(:password, "")}\n" }
          upload! StringIO.new(compiled_template), File.join(Shiplane::ChefHost::REMOTE_CHEF_FOLDER_PATH, compiled_file_name)
        end
      end
    end

    task :rsync_chef_configuration do |task, args|
      run_locally do
        fetch(:shiplane_hosts).map(&:capistrano_role).each do |host|
          rsync_arguments = [
            '-r',
            '-e', "\"ssh -p #{host.port || 22} -i #{host.netssh_options.fetch(:keys)}\"",
            "#{Shiplane::ChefHost::LOCAL_CHEF_FOLDER_PATH}/",
            "#{host.netssh_options.fetch(:user)}@#{host}:#{Shiplane::ChefHost::REMOTE_CHEF_FOLDER_PATH}"
          ]

          $stderr.puts rsync_arguments.join(" ")
          execute :rsync, *rsync_arguments
          # *outputs, status = Open3.capture3('rsync', *rsync_arguments)
        end
      end
    end

    # task :rsync_chef_cookbooks_configuration do |task, args|
    #   on fetch(:shiplane_hosts).map(&:capistrano_role) do |host|
    #     execute :sudo, :rm, '-Rf', Shiplane::ChefHost::REMOTE_COOKBOOKS_FOLDER_PATH, interaction_handler: { "[sudo] password for #{host.netssh_options.fetch(:user)}: " => "#{host.netssh_options.fetch(:password, "")}\n" }
    #     execute :sudo, :mkdir, '-m', '2777', '-p', Shiplane::ChefHost::REMOTE_COOKBOOKS_FOLDER_PATH, interaction_handler: { "[sudo] password for #{host.netssh_options.fetch(:user)}: " => "#{host.netssh_options.fetch(:password, "")}\n" }
    #   end

    #   run_locally do
    #     fetch(:shiplane_hosts).map(&:capistrano_role).each do |host|
    #       rsync_arguments = [
    #         '-r',
    #         '-e', "\"ssh -p #{host.port || 22} -i #{host.netssh_options.fetch(:keys)}\"",
    #         "#{Shiplane::ChefHost::LOCAL_COOKBOOKS_FOLDER_PATH}/",
    #         "#{host.netssh_options.fetch(:user)}@#{host}:#{Shiplane::ChefHost::REMOTE_COOKBOOKS_FOLDER_PATH}"
    #       ]

    #       $stderr.puts rsync_arguments.join(" ")
    #       # execute :rsync, *rsync_arguments
    #       *outputs, status = Open3.capture3('rsync', *rsync_arguments)
    #     end
    #   end
    # end

    task :rsync_custom_configuration, :role, :username, :keypath do |task, args|
      on fetch(:shiplane_hosts).map(&:capistrano_role) do |host|
        execute :sudo, :rm, '-Rf', Shiplane::ChefHost::REMOTE_CUSTOM_CONFIGURATION_FOLDER_PATH, interaction_handler: { "[sudo] password for #{host.netssh_options.fetch(:user)}: " => "#{host.netssh_options.fetch(:password, "")}\n" }
        execute :sudo, :mkdir, '-m', '2777', '-p', Shiplane::ChefHost::REMOTE_CUSTOM_CONFIGURATION_FOLDER_PATH, interaction_handler: { "[sudo] password for #{host.netssh_options.fetch(:user)}: " => "#{host.netssh_options.fetch(:password, "")}\n" }
      end

      run_locally do
        if Dir.exist?(Shiplane::ChefHost::LOCAL_CUSTOM_CONFIGURATION_FOLDER_PATH)
          fetch(:shiplane_hosts).map(&:capistrano_role).each do |host|
            rsync_arguments = [
              '-r',
              '-e', "ssh -p #{host.port || 22} -i #{host.netssh_options.fetch(:keys)}",
              "#{Shiplane::ChefHost::LOCAL_CUSTOM_CONFIGURATION_FOLDER_PATH}/",
              "#{host.netssh_options.fetch(:user)}@#{host}:#{Shiplane::ChefHost::REMOTE_CUSTOM_CONFIGURATION_FOLDER_PATH}"
            ]

            $stderr.puts rsync_arguments.join(" ")
            # execute :rsync, *rsync_arguments
            *outputs, status = Open3.capture3('rsync', *rsync_arguments)
          end
        end
      end
    end

    task :upload_cookbooks do |task, args|
      on fetch(:shiplane_hosts).map(&:capistrano_role) do |host|
        sudo :rm, '-Rf', Shiplane::ChefHost::REMOTE_COOKBOOKS_FILE_PATH
        upload!(Shiplane::ChefHost::LOCAL_COOKBOOKS_FILE_PATH, Shiplane::ChefHost::REMOTE_CHEF_FOLDER_PATH)
        sudo :rm, '-Rf', File.join(Shiplane::ChefHost::REMOTE_CHEF_FOLDER_PATH, 'cookbooks')
        execute :tar, '-xzf', Shiplane::ChefHost::REMOTE_COOKBOOKS_FILE_PATH, '-C', Shiplane::ChefHost::REMOTE_CHEF_FOLDER_PATH
      end
    end

    task :fix_file_permissions do |task, args|
      on fetch(:shiplane_hosts).map(&:capistrano_role) do |host|
        sudo :chmod, '-R', '777', Shiplane::ChefHost::REMOTE_CHEF_FOLDER_PATH
      end
    end
  end
end
