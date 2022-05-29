apt_repository 'docker' do
  arch               "amd64"
  components         %w(stable)
  distribution       node['lsb'].nil? || node['lsb']['codename'].nil? ? '' : node['lsb']['codename']
  key                'https://download.docker.com/linux/ubuntu/gpg'
  keyserver          'keyserver.ubuntu.com'
  uri                "https://download.docker.com/linux/#{node['platform']}"
  action             :add
end

group "#{node.fetch("barebones-docker", {}).fetch("group", {}).fetch("name", "docker")}"

node.fetch("barebones-docker", {}).fetch("users", []).each do |user_name|
  user user_name do
    group "#{node.fetch("barebones-docker", {}).fetch("group", {}).fetch("name", "docker")}"
  end

  directory "/home/#{user_name}/.docker" do
    owner user_name
    group node.fetch("barebones-docker", {}).fetch("group", {}).fetch("name", "docker")
    mode 0770
    only_if { ::File.directory? "/home/#{user_name}/" }
  end

  file "/home/#{user_name}/.docker/config.json" do
    owner user_name
    group node.fetch("barebones-docker", {}).fetch("group", {}).fetch("name", "docker")
    mode 0660
    only_if { ::File.directory? "/home/#{user_name}/" }
  end
end

group "#{node.fetch("barebones-docker", {}).fetch("group", {}).fetch("name", "docker")}" do
  append true
  members node.fetch("barebones-docker", {}).fetch("users", [])
end

if node['platform'] == 'ubuntu' && node['platform_version'].to_i >= 22
  deb_arch =
    case node['kernel']['machine']
    when 'x86_64'
      'amd64'
    when 'aarch64'
      'arm64'
    when 'armv7l'
      'armhf'
    when 'ppc64le'
      'ppc64el'
    else
      node['kernel']['machine']
    end

  apt_repository 'Docker' do
    components %w(stable)
    uri "https://download.docker.com/linux/#{node['platform']}"
    arch deb_arch
    key "https://download.docker.com/linux/#{node['platform']}/gpg"
    action :nothing
  end

  packages_to_install = %w(docker-ce docker-ce-cli containerd.io docker-compose-plugin)

  packages_to_install.each do |package_to_install|
    package package_to_install do
      options %q|--force-yes -o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-all'|
      action :nothing
    end
  end

  execute 'install_docker_package' do
    command "echo 'Installing Docker Package via apt...'"
    notifies :add, "apt_repository[Docker]", :immediately

    packages_to_install.each do |package_to_install|
      notifies :install, "package[#{package_to_install}]", :immediately
    end

    action :nothing
  end
else
  docker_installation_package 'default' do
    version "#{node.fetch("barebones-docker", {}).fetch("docker", {}).fetch("version")}"
    package_name "#{node.fetch("barebones-docker", {}).fetch("docker", {}).fetch("package_name")}"
    action :nothing
    package_options %q|--force-yes -o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-all'| # if Ubuntu for example
  end

  execute 'install_docker_package' do
    command "echo 'Installing Docker Package via docker_installation_package...'"
    notifies :create, "docker_installation_package[default]", :immediately

    action :nothing
  end
end

docker_service_manager_systemd 'default' do
  systemd_opts "#{node.fetch("barebones-docker", {}).fetch("docker", {}).fetch("systemd_opts")}"
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
  restart_policy 'always'
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
  restart_policy 'always'
  entrypoint nil
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
  notifies :run, "execute[install_docker_package]", :immediately
  notifies :start, "docker_service_manager_systemd[default]", :immediately
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
  notifies :run, "docker_container[nginx_reverse_proxy]", :immediately
  notifies :run, "docker_container[nginx-proxy-letsencrypt]", :immediately

  action :run
end
