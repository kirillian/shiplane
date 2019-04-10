group "#{node.fetch("barebones-docker", {}).fetch("group", {}).fetch("name", "docker")}"
user "#{node.fetch("barebones-docker", {}).fetch("user", {}).fetch("name", "docker")}" do
  group "#{node.fetch("barebones-docker", {}).fetch("group", {}).fetch("name", "docker")}"
end

docker_service 'default' do
  group "#{node.fetch("barebones-docker", {}).fetch("group", {}).fetch("name", "docker")}"
  install_method 'package'
  service_manager 'systemd'
  auto_restart true
  systemd_opts ["TasksMax=infinity","MountFlags=private"]
  version "#{node.fetch("barebones-docker", {}).fetch("docker", {}).fetch("version", "18.06.1")}"
  action :nothing
end

docker_image 'jwilder/nginx-proxy' do
  tag 'alpine'
  action :nothing
end

docker_image 'jrcs/letsencrypt-nginx-proxy-companion' do
  action :nothing
end

docker_container 'nginx_reverse_proxy' do
  action :nothing
  repo 'jwilder/nginx-proxy'
  tag 'alpine'
  port [ '80:80', '443:443' ]
  volumes [
    '/etc/ssl/certs/docker:/etc/nginx/certs',
    '/var/run/docker.sock:/tmp/docker.sock:ro',
    '/etc/docker/nginx-proxy/proxy.conf:/etc/nginx/proxy.conf',
    '/etc/docker/nginx-proxy/conf.d/logging.conf:/etc/nginx/conf.d/logging.conf',
    "/etc/docker/nginx-proxy/vhost.d:/etc/nginx/vhost.d",
    "/etc/docker/nginx-proxy/share/html:/usr/share/nginx/html",
  ]
end

docker_container 'nginx-proxy-letsencrypt' do
  action :nothing
  repo 'jrcs/letsencrypt-nginx-proxy-companion'
  volumes_from 'nginx_reverse_proxy'
  volumes [
    '/var/run/docker.sock:/var/run/docker.sock:ro',
  ]
end

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

directory "/etc/docker/nginx-proxy/share/html" do
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

directory "/var/log/nginx" do
  recursive true
  owner "#{node.fetch("barebones-docker", {}).fetch("user", {}).fetch("name", "docker")}"
  group "#{node.fetch("barebones-docker", {}).fetch("group", {}).fetch("name", "docker")}"
  mode 0755
  action :nothing
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

execute 'ensure_docker_nginx_proxy_prerequisites' do
  command "echo 'Ensuring Docker NGINX proxy prereqs...'"
  notifies :create, "docker_service[default]", :immediately
  notifies :start, "docker_service[default]", :immediately
  notifies :create_if_missing, "directory[/etc/ssl/certs/docker]", :immediately
  notifies :create_if_missing, "directory[/etc/docker/nginx-proxy/conf.d]", :immediately
  notifies :create_if_missing, "directory[/etc/docker/nginx-proxy/vhost.d]", :immediately
  notifies :create_if_missing, "directory[/etc/docker/nginx-proxy/share/html]", :immediately
  notifies :create_if_missing, "directory[/var/log/nginx]", :immediately
  notifies :create_if_missing, "template[/etc/docker/nginx-proxy/proxy.conf]", :immediately
  notifies :create_if_missing, "template[/etc/docker/nginx-proxy/conf.d/logging.conf]", :immediately
  notifies :touch, "file[/var/log/nginx/access.log]", :immediately
  notifies :touch, "file[/var/log/nginx/error.log]", :immediately
  notifies :pull, "docker_image[jwilder/nginx-proxy]", :immediately
  notifies :pull, "docker_image[jrcs/letsencrypt-nginx-proxy-companion]", :immediately
  notifies :redeploy, "docker_container[nginx_reverse_proxy]", :immediately
  notifies :redeploy, "docker_container[nginx-proxy-letsencrypt]", :immediately

  action :run
end
