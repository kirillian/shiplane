Airbrussh.configure do |config|
  config.command_output = false
end

# config valid only for current version of Capistrano
lock '3.11.0'

set :application, 'podcaster'
set :repo_url, 'git@github.com:kirillian/podcaster.git'

set :deploy_to, '/var/www/battlecryforfreedom'

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, %w( config/database.yml config/secrets.yml .env.production CHANGELOG.md config/sidekiq_scheduler.yml )

# Default value for linked_dirs is []
set :linked_dirs, %w( log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system )

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

set :rbenv_type, :system
set :rbenv_ruby, File.read('.ruby-version').strip

set :rbenv_prefix, "RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"
set :rbenv_map_bins, %w{rake gem bundle ruby rails sidekiq sidekiqctl}
set :rbenv_roles, :app

SSHKit.config.umask = "022"

set :ssh_options, {
  forward_agent: true
}

set :passenger_restart_with_touch, true

set :branch, proc { `git rev-list --max-count=1 --abbrev-commit #{ENV["REVISION"] || ENV["BRANCH"] || "master"}`.chomp }.call

set :rollbar_token, '07b2c99baf9b43b087ce0dc96957b52f'
set :rollbar_env, Proc.new { fetch :stage }
set :rollbar_role, Proc.new { :app }

set :sha, `git rev-parse HEAD`.chomp

set :shiplane_docker_registry_username, ENV['DOCKERHUB_USERNAME']
set :shiplane_docker_registry_password, ENV['DOCKERHUB_PASSWORD']

set :shiplane_networks, {
  battlecryforfreedom: {
    connections: [
      "nginx_reverse_proxy",
      "nginx-proxy-letsencrypt",
    ],
  }
}

set :shiplane_containers, {
  app: {
    alias: 'battlecryforfreedom-app',
    volumes: [],
    environment: [],
    expose: 3000,
    capistrano_role: "docker",
    repo: "kirillian2/podcaster",
    command: 'bin/start',
    virtual_host: "battlecryforfreedom.com",
    letsencrypt_email: "john.epperson@battlecryforfreedom.com",
    networks: [
      "battlecryforfreedom"
    ],
  },
  sidekiq: {
    alias: 'battlecryforfreedom-sidekiq',
    volumes: [],
    environment: [],
    capistrano_role: "docker",
    repo: "kirillian2/podcaster",
    command: 'bin/start_sidekiq_workers',
    networks: [
      "battlecryforfreedom"
    ],
  },
  redis: {
    alias: 'redis',
    volumes: [
      "/var/lib/redis:/var/lib/redis/data",
    ],
    environment: [],
    expose: 6379,
    publish: 6379,
    capistrano_role: "docker",
    repo: "redis",
    tag: "4.0.9-alpine",
    networks: [
      "battlecryforfreedom"
    ],
  },
  postgres: {
    alias: 'postgres',
    volumes: [
      "/var/lib/postgres/data:/var/lib/postgresql/data",
    ],
    expose: 5432,
    publish: 5432,
    capistrano_role: "docker",
    repo: "postgres",
    tag: "9.6",
    networks: [
      "battlecryforfreedom"
    ],
  },
}

# namespace :deploy do
#   before :started, :capture_revision
#   before :started, :upload_changelog

#   # config/deploy.rb
#   # after 'deploy:symlink:release', 'letsencrypt:register_client'
#   # after 'letsencrypt:register_client', 'letsencrypt:authorize_domain'
#   # after 'letsencrypt:authorize_domain', 'letsencrypt:obtain_certificate'
#   # after 'letsencrypt:obtain_certificate', 'nginx:reload'
# end
