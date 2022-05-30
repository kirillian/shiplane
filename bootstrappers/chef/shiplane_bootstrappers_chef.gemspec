# frozen_string_literal: true

require_relative "lib/shiplane/bootstrappers/chef/version"

Gem::Specification.new do |spec|
  spec.platform      = Gem::Platform::RUBY
  spec.name          = "shiplane_bootstrappers_chef"
  spec.version       = Shiplane::Bootstrappers::Chef::VERSION
  spec.authors       = ["John Epperson"]
  spec.email         = ["john.epperson@rockagile.io"]

  spec.summary       = "A toolbox for converting developer docker-compose files into production-ready images."
  spec.description   = "Converts docker-compose.yml files into images that can be uploaded to any docker image repository."
  spec.homepage      = "https://github.com/kirillian/shiplane"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").select { |f| f.match(%r{^(lib)/}) }
  end

  spec.files << "cookbooks.tar.gz"

  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.3.1"
  spec.license = "MIT"

  spec.add_runtime_dependency 'capistrano', '~> 3.7', '>= 3.7.1'
  spec.add_runtime_dependency 'airbrussh', '~> 1.1', '>= 1.1.1'

  spec.add_development_dependency 'berkshelf', '~> 7.0.0', '>= 7.0.8'
  spec.add_development_dependency 'gem-release', '~> 2.2.1', '>= 2.0.4'
end
