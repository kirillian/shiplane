require 'rake'
require 'shiplane'

desc "Convert Docker Container Artifacts From Development to Production and Upload to Docker Hub"
task :shiplane, [:appname, :sha] => ['shiplane:default']

namespace :shiplane do
  task :default do |t, args|
    sha = `git rev-parse HEAD`.chomp
    invoke "shiplane:build", sha
  end

  task :build, :sha do |t, args|
    Shiplane::Build.build_latest!(args['sha'], fetch(:stage))
  end
end
