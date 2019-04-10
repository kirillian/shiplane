attr = node['chef-server-with-letsencrypt']

package 'letsencrypt'

execute 'generate certs with letsencrypt' do
  command <<-EOS
  letsencrypt certonly --standalone -d #{node['chef-server']['api_fqdn']} --standalone-supported-challenges http-01
  EOS
  creates "/etc/letsencrypt/live/#{node['chef-server']['api_fqdn']}/fullchain.pem"
end

# Can't use only_if - Chef run will still fail if `crontab` doesn't exist
cron 'letsencrypt-ssl-chef' do
  time :weekly
  command %W{
  letsencrypt renew && pkill -HUP nginx
  }.join(' ')
end

node.override['chef-server']['configuration'] = <<-EOS
bookshelf['vip'] = '#{node['chef-server']['api_fqdn']}'
nginx['server_name'] = '#{node['chef-server']['api_fqdn']}'
nginx['non_ssl_port'] = false
nginx['ssl_certificate'] = '/etc/letsencrypt/live/#{node['chef-server']['api_fqdn']}/fullchain.pem'
nginx['ssl_certificate_key'] = '/etc/letsencrypt/live/#{node['chef-server']['api_fqdn']}/privkey.pem'
opscode_erchef['max_request_size'] = 3000000
EOS

include_recipe 'chef-server' if attr['install_chef_server']
