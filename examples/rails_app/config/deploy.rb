Airbrussh.configure do |config|
  config.command_output = false
end

# config valid only for current version of Capistrano
lock '3.11.0'

set :application, 'example'
set :repo_url, 'git@github.com:kirillian/example.git'

set :deploy_to, '/var/www/example'

set :branch, proc { `git rev-list --max-count=1 --abbrev-commit #{ENV["REVISION"] || ENV["BRANCH"] || "master"}`.chomp }.call

set :sha, `git rev-parse HEAD`.chomp

set :shiplane_docker_registry_username, ENV['DOCKERHUB_USERNAME']
set :shiplane_docker_registry_password, ENV['DOCKERHUB_PASSWORD']

set :shiplane_networks, {
  example: {
    connections: [
      "nginx_reverse_proxy",
      "nginx-proxy-letsencrypt",
    ],
  }
}

set :shiplane_containers, {
  app: {
    alias: 'example-app',
    volumes: [],
    environment: [],
    expose: 3000,
    capistrano_role: "docker",
    repo: "some_user/example",
    command: 'bin/start_web_server',
    virtual_host: "example.com",
    letsencrypt_email: "some.user@example.com",
    networks: [
      "example"
    ],
  },
  sidekiq: {
    alias: 'example-sidekiq',
    volumes: [],
    environment: [],
    capistrano_role: "docker",
    repo: "some_user/example",
    command: 'bin/start_sidekiq',
    networks: [
      "example"
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
    tag: "5.0.5-alpine",
    networks: [
      "example"
    ],
    deploy: {
      restart: false,
    },
  },
  postgres: {
    alias: 'db',
    volumes: [
      "/var/lib/postgres/data:/var/lib/postgresql/data",
    ],
    environment: {
      POSTGRES_PASSWORD: ENV['DATABASE_PASSWORD'],
      POSTGRES_USER: ENV['DATABASE_USERNAME'],
    },
    flags: {
      'shm-size' => '256MB',
    },
    expose: 5432,
    publish: 5432,
    capistrano_role: "docker",
    repo: "postgres",
    tag: "11.3",
    networks: [
      "example"
    ],
    deploy: {
      restart: false,
    },
  },
}
