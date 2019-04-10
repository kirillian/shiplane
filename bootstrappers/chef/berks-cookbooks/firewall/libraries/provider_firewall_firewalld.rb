#
# Author:: Ronald Doorn (<rdoorn@schubergphilis.com>)
# Cookbook:: firewall
# Resource:: default
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
class Chef
  class Provider::FirewallFirewalld < Chef::Provider::LWRPBase
    include FirewallCookbook::Helpers::Firewalld

    provides :firewall, os: 'linux', platform_family: %w(rhel fedora) do |node|
      node['platform_version'].to_f >= 7.0 && !node['firewall']['redhat7_iptables']
    end

    def whyrun_supported?
      false
    end

    def action_install
      return if disabled?(new_resource)

      firewalld_package = package 'firewalld' do
        action :nothing
        options new_resource.package_options
      end
      firewalld_package.run_action(:install)
      new_resource.updated_by_last_action(firewalld_package.updated_by_last_action?)

      unless ::File.exist?(firewalld_rules_filename)
        rules_file = lookup_or_create_rulesfile
        rules_file.content '# created by chef to allow service to start'
        rules_file.run_action(:create)
        new_resource.updated_by_last_action(rules_file.updated_by_last_action?)
      end

      firewalld_service = lookup_or_create_service
      [:enable, :start].each do |a|
        firewalld_service.run_action(a)
        new_resource.updated_by_last_action(firewalld_service.updated_by_last_action?)
      end
    end

    def action_restart
      return if disabled?(new_resource)

      # ensure it's initialized
      new_resource.rules({}) unless new_resource.rules
      new_resource.rules['firewalld'] = {} unless new_resource.rules['firewalld']

      # this populates the hash of rules from firewall_rule resources
      firewall_rules = Chef.run_context.resource_collection.select { |item| item.is_a?(Chef::Resource::FirewallRule) }
      firewall_rules.each do |firewall_rule|
        next unless firewall_rule.action.include?(:create) && !firewall_rule.should_skip?(:create)

        ip_versions(firewall_rule).each do |ip_version|
          # build rules to apply with weight
          k = "firewall-cmd --direct --add-rule #{build_firewall_rule(firewall_rule, ip_version)}"
          v = firewall_rule.position

          # unless we're adding them for the first time.... bail out.
          next if new_resource.rules['firewalld'].key?(k) && new_resource.rules['firewalld'][k] == v
          new_resource.rules['firewalld'][k] = v

          # If persistent rules is enabled (default) make sure we add a permanent rule at the same time
          perm_rules = node && node['firewall'] && node['firewall']['firewalld'] && node['firewall']['firewalld']['permanent']
          if firewall_rule.permanent || perm_rules
            k = "firewall-cmd --permanent --direct --add-rule #{build_firewall_rule(firewall_rule, ip_version)}"
            new_resource.rules['firewalld'][k] = v
          end
        end
      end

      # ensure a file resource exists with the current firewalld rules
      rules_file = lookup_or_create_rulesfile
      rules_file.content build_rule_file(new_resource.rules['firewalld'])
      rules_file.run_action(:create)

      # ensure the service is running without waiting.
      firewalld_service = lookup_or_create_service
      [:enable, :start].each do |a|
        firewalld_service.run_action(a)
        new_resource.updated_by_last_action(firewalld_service.updated_by_last_action?)
      end

      # mark updated if we changed the zone
      unless firewalld_default_zone?(new_resource.enabled_zone)
        firewalld_default_zone!(new_resource.enabled_zone)
        new_resource.updated_by_last_action(true)
      end

      # if the file was changed, load new ruleset
      return unless rules_file.updated_by_last_action?
      firewalld_flush!
      # TODO: support logging

      new_resource.rules['firewalld'].sort_by { |_k, v| v }.map { |k, _v| k }.each do |cmd|
        firewalld_rule!(cmd)
      end

      new_resource.updated_by_last_action(true)
    end

    def action_disable
      return if disabled?(new_resource)

      if firewalld_active?
        firewalld_flush!
        firewalld_default_zone!(new_resource.disabled_zone)
        new_resource.updated_by_last_action(true)
      end

      # ensure the service is stopped without waiting.
      firewalld_service = lookup_or_create_service
      [:disable, :stop].each do |a|
        firewalld_service.run_action(a)
        new_resource.updated_by_last_action(firewalld_service.updated_by_last_action?)
      end

      rules_file = lookup_or_create_rulesfile
      rules_file.content '# created by chef to allow service to start'
      rules_file.run_action(:create)
      new_resource.updated_by_last_action(rules_file.updated_by_last_action?)
    end

    def action_flush
      return if disabled?(new_resource)
      return unless firewalld_active?

      firewalld_flush!
      new_resource.updated_by_last_action(true)

      rules_file = lookup_or_create_rulesfile
      rules_file.content '# created by chef to allow service to start'
      rules_file.run_action(:create)
      new_resource.updated_by_last_action(rules_file.updated_by_last_action?)
    end

    def action_save
      return if disabled?(new_resource)
      return if firewalld_all_rules_permanent!

      firewalld_save!
      new_resource.updated_by_last_action(true)
    end

    def lookup_or_create_service
      begin
        firewalld_service = Chef.run_context.resource_collection.find(service: 'firewalld')
      rescue
        firewalld_service = service 'firewalld' do
          action :nothing
        end
      end
      firewalld_service
    end

    def lookup_or_create_rulesfile
      begin
        firewalld_file = Chef.run_context.resource_collection.find(file: firewalld_rules_filename)
      rescue
        firewalld_file = file firewalld_rules_filename do
          action :nothing
        end
      end
      firewalld_file
    end
  end
end
