namespace :shiplane do
  task :login_to_container_service do
    fetch(:shiplane_container_configurations).each do |name, config|
      roles = roles(config.fetch(:capistrano_role, :all)).map{|role| Shiplane::Host.new(role, env) }
      roles.each do |role|
        on role.capistrano_role do
          command = [
            'echo',
            "\"#{fetch(:shiplane_docker_registry_token)}\"",
            '|',
            config.docker_command(role),
            'login',
            fetch(:shiplane_docker_registry_url, nil),
            '--username',
            fetch(:shiplane_docker_registry_username),
            '--password-stdin',
          ].compact.join(' ')

          execute command
        end
      end
    end
  end

  task download_container: [:login_to_container_service] do
    fetch(:shiplane_container_configurations).each do |name, config|
      roles = roles(config.fetch(:capistrano_role, :all)).map{|role| Shiplane::Host.new(role, env) }
      roles.each do |role|
        on role.capistrano_role do
          execute "#{config.docker_command(role)} pull #{config.image_name}"
        end
      end
    end
  end
end
