require 'yaml'
require 'shiplane/railtie' if defined? Rails

require_relative 'shiplane/build'

module Shiplane
  DEFAULT_DOCKERFILE_FILEPATH = 'Dockerfile'
  DEFAULT_COMPOSEFILE_FILEPATH = 'docker-compose.yml'
  DEFAULT_PRODUCTION_DOCKERFILE_STAGES_FILEPATH = 'production_dockerfile_stages'
  SHIPLANE_CONFIG_FILENAME ='shiplane.yml'
end
