namespace :shiplane do
  task :login_to_dockerhub do
    fetch(:shiplane_container_configurations).each do |name, config|
      roles = roles(config.fetch(:capistrano_role, :all)).map{|role| Shiplane::Host.new(role, env) }
      roles.each do |role|
        on role.capistrano_role do
          username = fetch(:shiplane_docker_registry_username)
          password = fetch(:shiplane_docker_registry_password)
          execute "echo '#{password}' | #{config.docker_command(role)} login --username #{username} --password-stdin"
        end
      end
    end
  end

  task download_container: [:login_to_dockerhub] do
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
