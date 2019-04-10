require 'dotenv'
require_relative '../chef_host'

namespace :shiplane do
  namespace :bootstrap do
    # task :prepare do
    # end

    task :install do
      fetch(:shiplane_hosts).each do |host|
        host.install
      end
    end

    task configure: %i(evaluate_erb_files rsync_chef_configuration upload_cookbooks fix_file_permissions) do
      fetch(:shiplane_hosts).each do |host|
        host.configure
      end
    end

    # task :cleanup do
    # end

    task :evaluate_erb_files, :username, :keypath do |task, args|
      Dotenv.load Shiplane::ChefHost.env_file
      on fetch(:shiplane_hosts).map(&:capistrano_role) do |host|
        Dir["#{File.expand_path("../../../chef", __FILE__)}/**/*.erb"].map do |filename|
          compiled_template = ERB.new(File.read(filename)).result(binding)
          compiled_file_name = filename.match(/.*\/chef\/(.*)\.erb/)[1]

          sudo :mkdir, '-m', '777', '-p', File.join(Shiplane::ChefHost::REMOTE_CHEF_FOLDER_PATH, File.dirname(compiled_file_name))
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

          execute 'rsync', *rsync_arguments
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
