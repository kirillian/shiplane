# -*- coding: utf-8 -*-

require 'chefspec'

describe 'hostnames::vmware' do
  let(:chef_run) { ChefSpec::Runner.new.converge 'hostname::vmware' }
end
