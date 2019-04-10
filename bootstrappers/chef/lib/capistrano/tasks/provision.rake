require 'rake'
require 'dotenv'

desc "Provision host"
task :provision, [:role, :username, :keypath] => ['provision:default']

namespace :provision do
  task :default, [:role, :username, :keypath] => [
    :prepare_files,
    'cookbooks.tar.gz',
    :set_host_options,
    :prepare_host,
    :evaluate_erb_files,
    :rsync_chef,
    'upload-cookbooks',
    :fix_file_permissions,
  ] do |task, args|
    errors = {}
    on roles(fetch(:host_options).role) do |host|
      begin
        sudo 'chef-solo', '-c', '/var/chef/solo.rb'
      rescue => e
        error_line_regexp = /================================================================================/
        message_lines = e.message.split("\n").reverse
        error_message_start = message_lines.index(message_lines.find{|line| line =~ error_line_regexp }) || message_lines.size - 1
        error_message_end = message_lines.index(message_lines.find{|line| line =~ /ERROR: Exception handlers complete/ || line =~ /FATAL: Chef::Exceptions::ChildConvergeError/ }) || 0
        error_lines = message_lines[error_message_end..error_message_start].reverse
        errors["#{host}"] = error_lines
      end
    end

    unless errors.empty?
      puts "#{errors.keys.size} Errors encountered:"
      errors.each do |host, trace|
        puts "~" * 80
        puts "Server: #{host}"
        puts *trace
        puts "~" * 80
      end
    end
  end

  task :set_host_options, :role, :username, :keypath do |task, args|
    set :host_options, HostOptions.new(**args.to_h)

    roles(args['role']).each do |role|
      role.ssh_options = fetch(:host_options).ssh_options #unless role.user == fetch(:host_options).ssh_options[:user]
      role.user = fetch(:host_options).username
      role.keys = fetch(:host_options).keys
    end
  end

  task :prepare_host, :role, :username, :keypath do |task, args|
    on roles(fetch(:host_options).role) do |host|
      #preparation_started = test("[ -f #{File.join(chef_path, '.preparation-started')} ]")
      preparation_finished = test("[ -f #{File.join(chef_path, '.prepared')} ]")
      #if preparation_started && !preparation_finished
        #sudo :dpkg, '--configure', '-a'
        #sudo :dpkg, "--remove", "--force-remove-reinstreq", *packages
      #end

      unless preparation_finished
        sudo :mkdir, '-m', '2777', '-p', chef_path
        sudo :touch, File.join(chef_path, '.preparation-started')
        sudo 'apt-get', 'update'
        sudo 'apt-get', 'install', '-y', *packages
        execute :wget, chef_package_url
        sudo :dpkg, '-i', chef_package_name
        sudo :ls, '-al', chef_path
        sudo :touch, File.join(chef_path, '.prepared')
      end
    end
  end

  task :rsync_chef, :role, :username, :keypath do |task, args|
    on roles(fetch(:host_options).role) do |host|
      rsync_arguments = [
        '-r',
        '-e', "ssh -p #{host.port || 22} -i #{host.netssh_options.fetch(:keys)}",
        "#{chef_folder_path}/",
        "#{host.netssh_options.fetch(:user)}@#{host}:/var/chef"
      ]
      Kernel.system 'rsync', *rsync_arguments
    end
  end

  desc "Uploads the tarballed cookbooks"
  task :'upload-cookbooks', :role, :username, :keypath do |task, args|
    on roles(args['role']) do |host|
      sudo :rm, '-Rf', File.join(chef_path, 'cookbooks.tar.gz')
      upload!('cookbooks.tar.gz', chef_path)
      sudo :rm, '-Rf', File.join(chef_path, 'cookbooks')
      execute :tar, '-xzf', File.join(chef_path, 'cookbooks.tar.gz'), '-C', chef_path
    end
  end

  task :fix_file_permissions, :role, :username, :keypath do |task, args|
    on roles(args['role']) do |host|
      sudo :chmod, '-R', '777', chef_path
    end
  end

  task :evaluate_erb_files, :role, :username, :keypath do |task, args|
    Dotenv.load ".env.#{ENV['RAILS_ENV']}"
    on roles(args['role']) do |host|
      Dir["#{chef_folder_path}/**/*.erb"].map do |filename|
        compiled_template = ERB.new(File.read(filename)).result(binding)
        compiled_file_name = filename.match(/.*\/chef\/(.*)\.erb/)[1]
        sudo :mkdir, '-m', '777', '-p', File.join(chef_path, File.dirname(compiled_file_name))
        upload! StringIO.new(compiled_template), File.join(chef_path, compiled_file_name)
      end
    end
  end

  task :prepare_files do |task|
    rm 'cookbooks.tar.gz', force: true
    rm_r 'cookbooks', force: true
  end

  file "cookbooks.tar.gz" => :cookbooks do |task|
    sh "tar -cvzf #{task.name} cookbooks"
  end

  file cookbooks: :prepare_files do |task|
    cp_r 'berks-cookbooks/.', "cookbooks"
    cp_r 'site-cookbooks/.', "cookbooks"
  end
end

def packages
  %w(ruby ruby2.3-dev build-essential wget)
end

def chef_package_url
  "https://packages.chef.io/files/stable/chefdk/3.3.23/ubuntu/16.04/#{chef_package_name}"
end

def chef_package_name
  'chefdk_3.3.23-1_amd64.deb'
end

def chef_folder_path
  File.expand_path("../../../chef", __FILE__)
end

def sudo(*args)
  execute :sudo, *args, interaction_handler: {
    "[sudo] password for #{fetch(:host_options).username}: " => "#{fetch(:host_options).password}\n"
  }
end

def chef_path
  File.join("/var","chef")
end

class HostOptions
  attr_accessor :role, :keypath, :username, :password

  def initialize(username: nil, password: nil, keypath: nil, role: nil)
    @username = username
    @password = password
    @keypath = keypath
    @role = role
  end

  def username
    @username ||= config['username'] || 'deploy'
  end

  def password
    @password ||= config['password']
  end

  def keypath
    @keypath ||= config['keypath'] || "#{Dir.home}/.ssh/id_rsa"
  end

  def keys
    @keys ||= keypath.split('/')
  end

  def config
    @config ||= YAML.load(File.read(config_file_path))['capistrano']
  end

  def ssh_options
    @ssh_options ||= {
      user: username,
      keys: File.join(keys),
      forward_agent: true,
      auth_methods: %w(publickey),
    }
  end

  def config_file_path
    File.expand_path("../../../../config/config.yml", __FILE__)
  end
end
