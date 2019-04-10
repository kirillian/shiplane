### Settings

`deploy.rb`:

```
# Docker Registry Authentication
set :docker_registry, :dockerhub
set :docker_registry_username, ENV["DOCKERHUB_USERNAME"]
set :docker_registry_password, ENV["DOCKERHUB_PASSWORD"]

set :containers, [
  {
    name: "podcaster_app_#{fetch(:sha)}",
    server_role: 'app',
    command: 'bin/start_web_server',
    virtual_host_name: 'battlecryforfreedom.com',
    docker_registry_repo: 'kirillian2/podcaster',
    port: 3000,
    mounted_volumes: [
      [fetch(:sso_cert_file),'/var/www/podcaster/config/app.crt'],
      [fetch(:sso_cert_private_key_file),'/var/www/podcaster/config/app.key'],
    ],
    terminate_ssl: false,
    ssl_cert_file: nil,
  },
  {
    name: "podcaster_sidekiq_#{fetch(:sha)}",
    server_role: 'app',
    command: 'bundle exec sidekiq',
    docker_registry_repo: 'kirillian2/podcaster',
    mounted_volumes: [
      [fetch(:sso_cert_file),'/var/www/podcaster/config/app.crt'],
      [fetch(:sso_cert_private_key_file),'/var/www/podcaster/config/app.key'],
    ],
    terminate_ssl: false,
    ssl_cert_file: nil,
  },
]
```
