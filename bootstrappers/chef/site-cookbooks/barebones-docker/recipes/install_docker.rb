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

execute 'barebones_docker_install_docker' do
  command "echo 'Ensuring Docker NGINX proxy prereqs...'"
  notifies :run, "execute[install_docker_package]", :immediately

  action :nothing
end
