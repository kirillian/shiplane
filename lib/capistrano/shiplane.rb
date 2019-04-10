require 'shiplane/host'
require 'shiplane/deploy/container_configuration'
require 'shiplane/deploy/network_configuration'

load File.expand_path('../tasks/capistrano_stubs.rake', __FILE__)
load File.expand_path('../tasks/shiplane.rake', __FILE__)
