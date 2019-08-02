set :rails_env, 'production'

server "example.com", user: "ubuntu", roles: %w{ docker }, node: :docker
