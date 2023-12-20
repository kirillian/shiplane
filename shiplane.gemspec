# frozen_string_literal: true

require_relative "lib/shiplane/version"

Gem::Specification.new do |spec|
  spec.platform      = Gem::Platform::RUBY
  spec.name          = "shiplane"
  spec.version       = Shiplane::VERSION
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

  spec.files << "README.md"

  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.6.0"
  spec.license = "MIT"

  spec.add_dependency "shiplane_bootstrappers_chef", Shiplane::VERSION
  spec.add_dependency "shiplane_deployers_capistrano_docker", Shiplane::VERSION

  spec.add_runtime_dependency 'dotenv', '~> 2.1', '>= 2.1.1'
  spec.add_runtime_dependency 'facets', '~> 3.1', '>= 3.1.0'
  spec.add_runtime_dependency 'rake', '~> 13.0', '>= 12.0.0'

  spec.add_development_dependency 'gem-release', '~> 2.2.1', '>= 2.0.4'
end
