class Shiplane::Railtie < Rails::Railtie
  rake_tasks do
    load 'shiplane/tasks/install.rake'
  end
end
