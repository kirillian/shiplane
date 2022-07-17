docker_service_manager_systemd 'default' do
  systemd_opts "#{node.fetch("barebones-docker", {}).fetch("docker", {}).fetch("systemd_opts")}"
  action :nothing
end

execute 'barebones_docker_add_docker_service' do
  command "echo 'Ensuring Docker NGINX service manager is installed into systemd...'"
  notifies :start, "docker_service_manager_systemd[default]", :immediately

  action :nothing
end
