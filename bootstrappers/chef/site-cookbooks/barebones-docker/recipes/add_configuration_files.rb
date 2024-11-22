directory "/etc/ssl/certs/docker" do
  recursive true
  owner "#{node.fetch("barebones-docker", {}).fetch("user", {}).fetch("name", "docker")}"
  group "#{node.fetch("barebones-docker", {}).fetch("group", {}).fetch("name", "docker")}"
  mode 0755
  action :nothing
end

directory "/etc/docker/nginx-proxy/conf.d" do
  recursive true
  owner "#{node.fetch("barebones-docker", {}).fetch("user", {}).fetch("name", "docker")}"
  group "#{node.fetch("barebones-docker", {}).fetch("group", {}).fetch("name", "docker")}"
  mode 0755
  action :nothing
end

directory "/etc/docker/nginx-proxy/vhost.d" do
  recursive true
  owner "#{node.fetch("barebones-docker", {}).fetch("user", {}).fetch("name", "docker")}"
  group "#{node.fetch("barebones-docker", {}).fetch("group", {}).fetch("name", "docker")}"
  mode 0755
  action :nothing
end

directory "/etc/docker/nginx-proxy/share" do
  recursive true
  owner "#{node.fetch("barebones-docker", {}).fetch("user", {}).fetch("name", "docker")}"
  group "#{node.fetch("barebones-docker", {}).fetch("group", {}).fetch("name", "docker")}"
  mode 0755
  action :nothing
end

remote_directory '/etc/docker/nginx-proxy/conf.d' do
  source 'nginx-proxy/conf.d'
  recursive true
  owner "#{node.fetch("barebones-docker", {}).fetch("user", {}).fetch("name", "docker")}"
  group "#{node.fetch("barebones-docker", {}).fetch("group", {}).fetch("name", "docker")}"
  mode 0755
  action :nothing
  ignore_failure true
end

remote_directory '/etc/docker/nginx-proxy/vhost.d' do
  source 'nginx-proxy/vhost.d'
  recursive true
  owner "#{node.fetch("barebones-docker", {}).fetch("user", {}).fetch("name", "docker")}"
  group "#{node.fetch("barebones-docker", {}).fetch("group", {}).fetch("name", "docker")}"
  mode 0755
  action :nothing
  ignore_failure true
end

remote_directory '/etc/docker/nginx-proxy/share' do
  source 'nginx-proxy/share'
  recursive true
  owner "#{node.fetch("barebones-docker", {}).fetch("user", {}).fetch("name", "docker")}"
  group "#{node.fetch("barebones-docker", {}).fetch("group", {}).fetch("name", "docker")}"
  mode 0755
  action :nothing
  ignore_failure true
end

cookbook_file '/etc/docker/nginx-proxy/proxy.conf' do
  source 'nginx-proxy/proxy.conf'
  owner "#{node.fetch("barebones-docker", {}).fetch("user", {}).fetch("name", "docker")}"
  group "#{node.fetch("barebones-docker", {}).fetch("group", {}).fetch("name", "docker")}"
  mode 0755
  action :nothing
  ignore_failure true
end

directory "/var/log/nginx" do
  recursive true
  owner "#{node.fetch("barebones-docker", {}).fetch("user", {}).fetch("name", "docker")}"
  group "#{node.fetch("barebones-docker", {}).fetch("group", {}).fetch("name", "docker")}"
  mode 0755
  action :nothing
end

template "/etc/docker/nginx-proxy/proxy.conf" do
  source "proxy.conf.erb"
  owner "#{node.fetch("barebones-docker", {}).fetch("user", {}).fetch("name", "docker")}"
  group "#{node.fetch("barebones-docker", {}).fetch("group", {}).fetch("name", "docker")}"
  mode 0755
  action :nothing
end

template "/etc/docker/nginx-proxy/conf.d/logging.conf" do
  source "logging.conf.erb"
  owner "#{node.fetch("barebones-docker", {}).fetch("user", {}).fetch("name", "docker")}"
  group "#{node.fetch("barebones-docker", {}).fetch("group", {}).fetch("name", "docker")}"
  mode 0755
  action :nothing
end

# nginx_proxy_files = run_context.cookbook_collection['barebones-docker'].manifest.fetch('all_files', []).select{|file| file['path'] =~ /files\/nginx-proxy/ }
# nginx_proxy_file_commands = []

# Chef::Log.fatal("*" * 120)
# run_context.cookbook_collection['barebones-docker'].manifest.fetch('all_files', []).each do |file|
#   Chef::Log.fatal("#{file['path']}' exists")
# end
# Chef::Log.fatal("*" * 120)

# Chef::Log.fatal("*" * 120)
# nginx_proxy_files.each do |file|
#   Chef::Log.fatal("#{file['path']}' found")

#   is_directory = File.directory?(file['path'])

#   pathname = file['path'].split(File::SEPARATOR)
#   directory_path = pathname[pathname.index('nginx-proxy')..-1]

#   if !is_directory
#     filename = directory_path.last
#     directory_path = directory_path[0...-1]
#   end

#   nginx_proxy_file_commands << "directory[/etc/docker/#{File.join(*directory_path)}]"
#   directory "/etc/docker/#{File.join(*directory_path)}" do
#     recursive true
#     owner "#{node.fetch("barebones-docker", {}).fetch("user", {}).fetch("name", "docker")}"
#     group "#{node.fetch("barebones-docker", {}).fetch("group", {}).fetch("name", "docker")}"
#     mode 0755
#     action :nothing
#   end

#   if !is_directory
#     base_filename = File.basename(filename, '.erb')

#     nginx_proxy_file_commands << "template[/etc/docker/#{File.join(*directory_path, base_filename)}]"
#     template "/etc/docker/#{File.join(*directory_path, base_filename)}" do
#       source "#{File.join(*directory_path, filename)}"
#       owner "#{node.fetch("barebones-docker", {}).fetch("user", {}).fetch("name", "docker")}"
#       group "#{node.fetch("barebones-docker", {}).fetch("group", {}).fetch("name", "docker")}"
#       mode 0755
#       action :nothing
#     end
#   end
# end
# Chef::Log.debug("*" * 120)

if run_context.cookbook_collection['barebones-docker'].manifest.fetch('all_files', []).any?{|file| file['path'] == 'files/nginx-proxy/proxy.conf' || file['path'] == 'files/default/nginx-proxy/proxy.conf' }
  execute 'barebones_docker_write_proxy_conf' do
    command "echo 'proxy.conf' overridden. Skipping writing 'proxy.conf' ..."

    notifies :create, "cookbook_file[/etc/docker/nginx-proxy/proxy.conf]", :immediately

    action :nothing
  end
else
  execute 'barebones_docker_write_proxy_conf' do
    command "echo 'proxy.conf' not found. Writing 'proxy.conf' ..."
    notifies :create, "template[/etc/docker/nginx-proxy/proxy.conf]", :immediately

    action :nothing
  end
end

if run_context.cookbook_collection['barebones-docker'].manifest.fetch('all_files', []).any?{|file| file['path'] == 'files/nginx-proxy/conf.d/logging.conf' }
  execute 'barebones_docker_write_conf_d_logging' do
    command "echo 'conf.d/logging.conf' overridden. Skipping writing 'conf.d/logging.conf' ..."

    action :nothing
  end
else
  execute 'barebones_docker_write_conf_d_logging' do
    command "echo 'conf.d/logging.conf' not found. Writing 'conf.d/logging.conf' ..."
    notifies :create_if_missing, "template[/etc/docker/nginx-proxy/conf.d/logging.conf]", :immediately

    action :nothing
  end
end

vhost_config_filepaths = run_context.cookbook_collection['barebones-docker'].manifest
                      .fetch('all_files', [])
                      .select{|file| file['path'] =~ /files\/(default\/)?nginx-proxy\/vhost\.d\/.*/ }
                      .map{|file| file['path'][/nginx-proxy\/vhost\.d\/.*/] }

unless vhost_config_filepaths.empty?
  vhost_config_filepaths.each do |filepath|
    cookbook_file "/etc/docker/#{filepath}" do
      source "/files/default/#{filepath}"
      owner "#{node.fetch("barebones-docker", {}).fetch("user", {}).fetch("name", "docker")}"
      group "#{node.fetch("barebones-docker", {}).fetch("group", {}).fetch("name", "docker")}"
      mode 0755
      action :nothing
      ignore_failure true
    end
  end

  execute 'barebones_docker_write_vhost_config_files' do
    command "echo 'proxy.conf' overridden. Skipping writing 'proxy.conf' ..."
    vhost_config_filepaths.each do |filepath|
      notifies :create, "cookbook_file[/etc/docker/#{filepath}]", :immediately
    end

    action :nothing
  end
else
  execute 'barebones_docker_write_proxy_conf' do
    command "echo 'proxy.conf' not found. Writing 'proxy.conf' ..."
    notifies :create, "template[/etc/docker/nginx-proxy/proxy.conf]", :immediately

    action :nothing
  end
end

file '/var/log/nginx/access.log' do
  mode '0755'
  owner "#{node.fetch("barebones-docker", {}).fetch("user", {}).fetch("name", "docker")}"
  group "#{node.fetch("barebones-docker", {}).fetch("group", {}).fetch("name", "docker")}"
  mode 0755
  action :nothing
end

file '/var/log/nginx/error.log' do
  mode '0755'
  owner "#{node.fetch("barebones-docker", {}).fetch("user", {}).fetch("name", "docker")}"
  group "#{node.fetch("barebones-docker", {}).fetch("group", {}).fetch("name", "docker")}"
  mode 0755
  action :nothing
end

execute 'barebones_docker_add_configuration_files' do
  command "echo 'Ensuring Docker NGINX proxy configuration files...'"
  notifies :create, "directory[/etc/ssl/certs/docker]", :immediately
  notifies :create, "directory[/etc/docker/nginx-proxy/conf.d]", :immediately
  notifies :create, "directory[/etc/docker/nginx-proxy/vhost.d]", :immediately
  notifies :create, "directory[/etc/docker/nginx-proxy/share]", :immediately
  notifies :create, "directory[/var/log/nginx]", :immediately
  notifies :create, "remote_directory[/etc/docker/nginx-proxy/conf.d]", :immediately
  notifies :create, "remote_directory[/etc/docker/nginx-proxy/vhost.d]", :immediately
  notifies :create, "remote_directory[/etc/docker/nginx-proxy/share]", :immediately
  # nginx_proxy_file_commands.each do |command_text|
  #   notifies :create, command_text, :immediately
  # end
  notifies :run, "execute[barebones_docker_write_proxy_conf]", :immediately
  notifies :run, "execute[barebones_docker_write_conf_d_logging]", :immediately
  notifies :touch, "file[/var/log/nginx/access.log]", :immediately
  notifies :touch, "file[/var/log/nginx/error.log]", :immediately

  action :nothing
end
