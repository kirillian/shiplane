namespace :release do
  desc "Refresh Cookbooks"
  task refresh_cookbooks: ["cookbooks.tar.gz"] do
  end

  task :prepare_files do |task|
    rm 'cookbooks.tar.gz', force: true
    rm_r 'cookbooks', force: true
  end

  file "cookbooks.tar.gz" => :cookbooks do |task|
    sh "tar -cvzf #{task.name} cookbooks"
  end

  file cookbooks: :prepare_files do |task|
    cp_r 'berks-cookbooks/.', "cookbooks"
    cp_r 'site-cookbooks/.', "cookbooks"
  end
end
