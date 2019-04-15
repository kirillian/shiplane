namespace :shiplane do
  desc "Install Shiplane"
  task :install => [:app_name] do |t, args|
    Rake::Task['shiplane:generate_shiplane_yaml_file'].invoke(args['app_name'])
  end

  task :generate_shiplane_yaml_file, :app_name do |t, args|
    shiplane_yml_erb_filepath = File.expand_path("../../generators/shiplane/install/templates/shiplane.yml.erb", __dir__)
    shiplane_yml_filepath = 'shiplane.yml'

    if File.exist?(shiplane_yml_filepath)
      warn "[skip] #{shiplane_yml_filepath} already exists"
    else
      File.write('shiplane.yml', ERB.new(File.read(shiplane_yml_filepath)).result_with_hash(app_name: args['app_name']))
      puts "#{shiplane_yml_filepath} created"
    end
  end
end
