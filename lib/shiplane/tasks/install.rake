namespace :shiplane do
  desc "Install Shiplane"
  task :install, :app_name do |t, args|
    puts "Running Task: 'shiplane:install'"
    Rake::Task['shiplane:capify'].invoke
    Rake::Task['shiplane:generate_shiplane_folder'].invoke
    Rake::Task['shiplane:generate_insert_on_build_folder'].invoke
    Rake::Task['shiplane:generate_shiplane_yaml_file'].invoke(args[:app_name])
    Rake::Task['shiplane:generate_production_dockerfile_stages_file'].invoke
  end

  task :capify do
    puts "Running Task: 'shiplane:capify'"
    shiplane_gems = %w(shiplane shiplane_bootstrappers_chef shiplane_deployers_capistrano_docker)

    if File.exist?('Capfile')
      warn "[warn] Capistrano installation detected. Check the Shiplane documentation for details on how to add shiplane to your existing Capistrano configuration"
    end

    Rake::Task['shiplane:generate_config_folder'].invoke
    Rake::Task['shiplane:generate_capistrano_config_deploy_folder'].invoke
    Rake::Task['shiplane:generate_capfile'].invoke(shiplane_gems)
    Rake::Task['shiplane:generate_capistrano_deploy_file'].invoke
    Rake::Task['shiplane:generate_production_environment_deploy_file'].invoke
  end

  task :generate_folder, :folder_path do |t, args|
    puts "Running Task: 'shiplane:generate_folder'"
    if Dir.exist?(args[:folder_path])
      warn "[skip] #{args[:folder_path]} already exists"
    else
      FileUtils.mkdir_p args[:folder_path]
      puts "#{args[:folder_path]} created"
    end
    Rake::Task['shiplane:generate_folder'].reenable
  end

  task :generate_file, :file_path, :file_contents do |t, args|
    puts "Running Task: 'shiplane:generate_file'"
    if File.exist?(args[:file_path])
      warn "[skip] #{args[:file_path]} already exists"
    else
      File.write(args[:file_path], args[:file_contents])
      puts "#{args[:file_path]} created"
    end
    Rake::Task['shiplane:generate_file'].reenable
  end

  task :generate_shiplane_folder do
    puts "Running Task: 'shiplane:generate_shiplane_folder'"
    Rake::Task['shiplane:generate_folder'].invoke('.shiplane')
  end

  task :generate_insert_on_build_folder do
    puts "Running Task: 'shiplane:generate_insert_on_build_folder'"
    Rake::Task['shiplane:generate_folder'].invoke('.shiplane/insert_on_build')
  end

  task :generate_config_folder do
    puts "Running Task: 'shiplane:generate_config_folder'"
    Rake::Task['shiplane:generate_folder'].invoke('config')
  end

  task :generate_capistrano_config_deploy_folder do
    puts "Running Task: 'shiplane:generate_capistrano_config_deploy_folder'"
    Rake::Task['shiplane:generate_folder'].invoke('config/deploy')
  end

  task :generate_shiplane_yaml_file, :app_name do |t, args|
    puts "Running Task: 'shiplane:generate_shiplane_yaml_file'"
    app_name = args[:app_name]
    shiplane_yml_erb_filepath = File.expand_path("../../generators/shiplane/install/templates/shiplane.yml.erb", __dir__)

    Rake::Task['shiplane:generate_file'].invoke(
      'shiplane.yml',
      ERB.new(File.read(shiplane_yml_erb_filepath), nil, '-').result(binding),
    )
  end

  task :generate_production_dockerfile_stages_file do
    puts "Running Task: 'shiplane:generate_production_dockerfile_stages_file'"
    production_dockerfile_stages_template_filepath = File.expand_path("../../generators/shiplane/install/templates/production_dockerfile_stages.erb", __dir__)

    Rake::Task['shiplane:generate_file'].invoke(
      '.shiplane/production_dockerfile_stages',
      ERB.new(File.read(production_dockerfile_stages_template_filepath), nil, '-').result,
    )
  end

  task :generate_capfile, :gems do |t, args|
    puts "Running Task: 'shiplane:generate_capfile'"
    gems = args[:gems]
    capfile_template_filepath = File.expand_path("../../generators/shiplane/install/templates/Capfile.erb", __dir__)

    Rake::Task['shiplane:generate_file'].invoke(
      'Capfile',
      ERB.new(File.read(capfile_template_filepath), nil, '-').result(binding),
    )
  end

  task :generate_capistrano_deploy_file do
    puts "Running Task: 'shiplane:generate_capistrano_deploy_file'"
    capistrano_deploy_template_filepath = File.expand_path("../../generators/shiplane/install/templates/deploy.rb.erb", __dir__)

    Rake::Task['shiplane:generate_file'].invoke(
      'config/deploy.rb',
      ERB.new(File.read(capistrano_deploy_template_filepath), nil, '-').result,
    )
  end

  task :generate_production_environment_deploy_file do
    puts "Running Task: 'shiplane:generate_production_environment_deploy_file'"
    production_environment_deploy_filepath = File.expand_path("../../generators/shiplane/install/templates/production.rb.erb", __dir__)

    Rake::Task['shiplane:generate_file'].invoke(
      'config/deploy/production.rb',
      ERB.new(File.read(production_environment_deploy_filepath), nil, '-').result,
    )
  end
end
