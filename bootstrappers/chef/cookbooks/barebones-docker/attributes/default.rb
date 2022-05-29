#
# Cookbook:: barebones-docker
# Attributes:: default
#
# Copyright:: 2013-2018, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
DEFAULT_DOCKER_PACKAGE_NAME = 'docker-ce'
DEFAULT_DOCKER_VERSION = '18.06.1'

case node['platform']
when 'ubuntu'
  if node['platform_version'].to_i >= 22
    default['barebones-docker']['docker']['version'] ||= '20.10.16'
    default['barebones-docker']['docker']['package_name'] = 'docker-ce-cli'
  else
    default['barebones-docker']['docker']['version'] ||= DEFAULT_DOCKER_VERSION
    default['barebones-docker']['docker']['package_name'] = DEFAULT_DOCKER_PACKAGE_NAME
  end
else
  default['barebones-docker']['docker']['version'] ||= DEFAULT_DOCKER_VERSION
  default['barebones-docker']['docker']['package_name'] = DEFAULT_DOCKER_PACKAGE_NAME
end
