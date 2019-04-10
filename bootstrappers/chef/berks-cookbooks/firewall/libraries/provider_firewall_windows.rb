#
# Author:: Sander van Harmelen (<svanharmelen@schubergphilis.com>)
# Cookbook:: firewall
# Provider:: windows
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
  class Provider::FirewallWindows < Chef::Provider::LWRPBase
    include FirewallCookbook::Helpers::Windows

    provides :firewall, os: 'windows'

    def whyrun_supported?
      false
    end

    def action_install
      return if disabled?(new_resource)

      svc = service 'MpsSvc' do
        action :nothing
      end

      [:enable, :start].each do |act|
        svc.run_action(act)
        new_resource.updated_by_last_action(true) if svc.updated_by_last_action?
      end
    end

    def action_restart
      return if disabled?(new_resource)

      # ensure it's initialized
      new_resource.rules({}) unless new_resource.rules
      new_resource.rules['windows'] = {} unless new_resource.rules['windows']

      firewall_rules = Chef.run_context.resource_collection.select { |item| item.is_a?(Chef::Resource::FirewallRule) }
      firewall_rules.each do |firewall_rule|
        next unless firewall_rule.action.include?(:create) && !firewall_rule.should_skip?(:create)

        # build rules to apply with weight
        k = build_rule(firewall_rule)
        v = firewall_rule.position

        # unless we're adding them for the first time.... bail out.
        unless new_resource.rules['windows'].key?(k) && new_resource.rules['windows'][k] == v
          new_resource.rules['windows'][k] = v
        end
      end

      input_policy = node['firewall']['windows']['defaults']['policy']['input']
      output_policy = node['firewall']['windows']['defaults']['policy']['output']
      unless new_resource.rules['windows'].key?("set currentprofile firewallpolicy #{input_policy},#{output_policy}")
        # Make this the possible last rule in the list
        new_resource.rules['windows']["set currentprofile firewallpolicy #{input_policy},#{output_policy}"] = 99999
      end

      # ensure a file resource exists with the current rules
      begin
        windows_file = Chef.run_context.resource_collection.find(file: windows_rules_filename)
      rescue
        windows_file = file windows_rules_filename do
          action :nothing
        end
      end
      windows_file.content build_rule_file(new_resource.rules['windows'])
      windows_file.run_action(:create)

      # if the file was changed, restart iptables
      return unless windows_file.updated_by_last_action?

      disable! if active?
      delete_all_rules! # clear entirely
      reset! # populate default rules

      new_resource.rules['windows'].sort_by { |_k, v| v }.map { |k, _v| k }.each do |cmd|
        add_rule!(cmd)
      end
      # ensure it's enabled _after_ rules are inputted, to catch malformed rules
      enable! unless active?

      new_resource.updated_by_last_action(true)
    end

    def action_disable
      return if disabled?(new_resource)

      if active?
        disable!
        Chef::Log.info("#{new_resource} disabled.")
        new_resource.updated_by_last_action(true)
      else
        Chef::Log.debug("#{new_resource} already disabled.")
      end

      svc = service 'MpsSvc' do
        action :nothing
      end

      [:disable, :stop].each do |act|
        svc.run_action(act)
        new_resource.updated_by_last_action(true) if svc.updated_by_last_action?
      end
    end

    def action_flush
      return if disabled?(new_resource)

      reset!
      Chef::Log.info("#{new_resource} reset.")
      new_resource.updated_by_last_action(true)
    end
  end
end
