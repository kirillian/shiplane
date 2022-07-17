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
    '/etc/docker/nginx-proxy/conf.d:/etc/nginx/conf.d',
    "/etc/docker/nginx-proxy/vhost.d:/etc/nginx/vhost.d",
    "/etc/docker/nginx-proxy/share/html:/usr/share/nginx/html",
  ]
  env [
    "DEBUG=true"
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

execute 'barebones_docker_deploy_containers' do
  command "echo 'Ensuring Docker NGINX proxy prereqs...'"
  notifies :redeploy, "docker_container[nginx_reverse_proxy]", :immediately
  notifies :redeploy, "docker_container[nginx-proxy-letsencrypt]", :immediately
  notifies :run, "docker_container[nginx_reverse_proxy]", :immediately
  notifies :run, "docker_container[nginx-proxy-letsencrypt]", :immediately

  action :nothing
end
