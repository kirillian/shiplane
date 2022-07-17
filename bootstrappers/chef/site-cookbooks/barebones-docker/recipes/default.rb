include_recipe '::install_docker'
include_recipe '::add_docker_service'
include_recipe '::download_images'
include_recipe '::add_configuration_files'
include_recipe '::deploy_containers'

execute 'ensure_nginx_proxy_prerequisites' do
  command "echo 'Ensuring Docker NGINX proxy prereqs...'"
  notifies :run, "execute[barebones_docker_install_docker]", :immediately
  notifies :run, "execute[barebones_docker_add_docker_service]", :immediately
  notifies :run, "execute[barebones_docker_download_images]", :immediately
  notifies :run, "execute[barebones_docker_add_configuration_files]", :immediately
  notifies :run, "execute[barebones_docker_deploy_containers]", :immediately

  action :run
end
