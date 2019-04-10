#
# Cookbook:: test
# Recipe:: resources
#
# Copyright:: 2012-2017, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe 'test::base'

if node['platform'] == 'ubuntu'
  # Apt Repository
  apt_repository 'juju' do
    uri '"http://ppa.launchpad.net/juju/stable/ubuntu"'
    components ['main']
    distribution 'trusty'
    key 'C8068B11'
    keyserver 'keyserver.ubuntu.com'
    action :add
  end

  # Apt Repository
  apt_repository 'nodejs' do
    uri 'http://ppa.launchpad.net/chris-lea/node.js/ubuntu'
    components ['main']
    distribution 'trusty'
    key 'C7917B12'
    keyserver 'hkp://keyserver.ubuntu.com:80'
    action :add
  end

  # PPA Repository w/o key specified
  apt_repository 'gimp' do
    uri 'ppa:otto-kesselgulasch/gimp'
  end

  # Apt repository that suppresses output for sensitive resources.
  apt_repository 'haproxy' do
    uri 'http://ppa.launchpad.net/vbernat/haproxy-1.5/ubuntu'
    components ['main']
    keyserver 'keyserver.ubuntu.com'
    key '1C61B9CD'
    sensitive true
    action :add
  end
end

# Apt Repository with arch
apt_repository 'cloudera' do
  uri 'http://archive.cloudera.com/cdh4/ubuntu/precise/amd64/cdh'
  arch 'amd64'
  distribution 'precise-cdh4'
  components ['contrib']
  key 'http://archive.cloudera.com/debian/archive.key'
  action :add
end

# Apt repository and install a package it contains
apt_repository 'nginx' do
  uri "http://nginx.org/packages/#{node['platform']}"
  components ['nginx']
  key 'http://nginx.org/keys/nginx_signing.key'
  deb_src true
end

package 'nginx' do
  action :install
end

# Apt Preferences
apt_preference 'chef' do
  pin 'version 12.7.2-1'
  pin_priority '700'
end

# Preference file renaming
file '/etc/apt/preferences.d/wget' do
  action :touch
end

apt_preference 'wget' do
  pin 'version 1.13.4-3'
  pin_priority '1001'
end

# COOK-2338
apt_preference 'dotdeb' do
  glob '*'
  pin 'origin packages.dotdeb.org '
  pin_priority '700'
end

# rename preferences with wildcards
file '/etc/apt/preferences.d/*.pref' do
  action :touch
end

apt_preference '*' do
  pin 'origin nginx.org'
  pin_priority '1001'
end

# Preference file removal
file '/etc/apt/preferences.d/camel.pref' do
  action :touch
end

apt_preference 'camel' do
  action :remove
end
