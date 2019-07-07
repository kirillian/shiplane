namespace :shiplane do
  desc "Bootstrap host - provisions docker and nginx-proxy"
  task :bootstrap, [:role] => ['bootstrap:default']

  namespace :bootstrap do
    task :default, [:role] do |task, args|
      filter = args.fetch('role', 'all')
      hosts = roles(filter).map do |host|
        Shiplane::ChefHost.new(host, env)
      end

      set :shiplane_hosts, hosts

      %w{ prepare install configure cleanup }.each do |task|
        invoke "shiplane:bootstrap:#{task}"
      end
    end

    task :prepare do
    end

    task :install do
    end

    task :configure do
    end

    task :cleanup do
    end
  end
end
