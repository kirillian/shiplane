docker_image 'jwilder/nginx-proxy' do
  tag 'alpine'
  action :nothing
end

docker_image 'nginxproxy/acme-companion' do
  action :nothing
end

execute 'barebones_docker_download_images' do
  command "echo 'Ensuring Docker NGINX proxy images are downloaded...'"
  notifies :pull, "docker_image[jwilder/nginx-proxy]", :immediately
  notifies :pull, "docker_image[nginxproxy/acme-companion]", :immediately

  action :nothing
end
