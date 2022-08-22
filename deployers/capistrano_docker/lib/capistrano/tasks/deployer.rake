# frozen_string_literal: true

require 'dotenv'
Dotenv.load File.join(Dir.pwd, '.env')

namespace :deploy do
  task :starting do
    invoke "shiplane:instantiate_shiplane_environment"
    invoke "shiplane:create_networks"
  end

  task :updating do
    invoke "shiplane:download_container"
  end

  task :publishing do
    invoke "shiplane:stop_old_containers"
    invoke "shiplane:remove_conflicting_containers"
    invoke "shiplane:deploy"
  end

  task :finishing do
  end
end

namespace :shiplane do
  task :instantiate_shiplane_environment do
    set :shiplane_container_configurations, Hash[fetch(:shiplane_containers).map do |name, config|
      [name, Shiplane::Deploy::ContainerConfiguration.new(name, config, env)]
    end]

    set :shiplane_network_configurations, Hash[fetch(:shiplane_networks).map do |name, config|
      [name, Shiplane::Deploy::NetworkConfiguration.new(name, config, env)]
    end]
  end

  task :create_networks do
    fetch(:shiplane_network_configurations).each do |name, config|
      roles = roles(config.fetch(:capistrano_role, :all)).map{|role| Shiplane::Host.new(role, env) }
      roles.each do |role|
        on role.capistrano_role do
          config.create_commands(role).each(&method(:execute))
        end
      end
    end
  end

  desc "Deploy the current branch to production via its docker container"
  task deploy: [:instantiate_shiplane_environment, :create_networks, :download_container, :stop_old_containers, :remove_conflicting_containers, :cleanup_old_releases] do
    fetch(:shiplane_container_configurations).each do |name, config|
      roles = roles(config.fetch(:capistrano_role, :all)).map{|role| Shiplane::Host.new(role, env) }
      roles.each do |role|
        on role.capistrano_role do
          config.run_commands(role).each(&method(:execute))
        end
      end
    end
  end

  task :stop_old_containers do
    fetch(:shiplane_container_configurations).each do |name, config|
      roles = roles(config.fetch(:capistrano_role, :all)).map{|role| Shiplane::Host.new(role, env) }
      roles.each do |role|
        on role.capistrano_role do
          old_container_ids = capture("#{config.docker_command(role)} ps --filter name=#{config.container_name} --format \"{{.ID}}\"").split("\n")
          old_container_ids.each do |container_id|
            execute "#{config.docker_command(role)} kill #{container_id}"
          end
        end
      end
    end
  end

  task :remove_conflicting_containers do
    fetch(:shiplane_container_configurations).each do |name, config|
      roles = roles(config.fetch(:capistrano_role, :all)).map{|role| Shiplane::Host.new(role, env) }
      roles.each do |role|
        on role.capistrano_role do
          old_container_ids = capture("#{config.docker_command(role)} ps -a --filter name=#{fetch(:sha)} --format \"{{.ID}}\"").split("\n")
          old_container_ids.each do |container_id|
            execute "#{config.docker_command(role)} rm #{container_id}"
          end
        end
      end
    end
  end

  task :cleanup_old_releases do
    all_roles = {}

    fetch(:shiplane_container_configurations).each do |name, config|
      roles = roles(config.fetch(:capistrano_role, :all)).map{|role| Shiplane::Host.new(role, env) }

      roles.each do |role|
        all_roles[role] = config.docker_command(role)
        on role.capistrano_role do
          container_ids_to_keep = capture("#{config.docker_command(role)} container ls -aq --filter name=#{config.container_name} -n #{config.env.fetch(:keep_releases, 5)}").split("\n")
          all_container_ids = capture("#{config.docker_command(role)} container ls -aq --filter name=#{config.container_name}").split("\n")

          (all_container_ids - container_ids_to_keep).each do |container_id|
            execute "#{config.docker_command(role)} rm #{container_id}"
          end
        end
      end
    end

    all_roles.keys.each do |role|
      on role.capistrano_role do
        execute "#{all_roles[role]} image prune -fa"
      end
    end
  end
end
