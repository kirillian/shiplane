module FirewallCookbook
  module Helpers
    module Iptables
      include FirewallCookbook::Helpers
      include Chef::Mixin::ShellOut

      CHAIN = { in: 'INPUT', out: 'OUTPUT', pre: 'PREROUTING', post: 'POSTROUTING' }.freeze unless defined? CHAIN # , nil => "FORWARD"}
      TARGET = { allow: 'ACCEPT', reject: 'REJECT', deny: 'DROP', masquerade: 'MASQUERADE', redirect: 'REDIRECT', log: 'LOG --log-prefix "iptables: " --log-level 7' }.freeze unless defined? TARGET

      def build_firewall_rule(current_node, rule_resource, ipv6 = false)
        el5 = current_node['platform_family'] == 'rhel' && Gem::Dependency.new('', '~> 5.0').match?('', current_node['platform_version'])

        return rule_resource.raw.strip if rule_resource.raw
        firewall_rule = if rule_resource.direction
                          "-A #{CHAIN[rule_resource.direction.to_sym]} "
                        else
                          '-A FORWARD '
                        end

        if [:pre, :post].include?(rule_resource.direction)
          firewall_rule << '-t nat '
        end

        # Iptables order of prameters is important here see example output below:
        # -A INPUT -s 1.2.3.4/32 -d 5.6.7.8/32 -i lo -p tcp -m tcp -m state --state NEW -m comment --comment "hello" -j DROP
        firewall_rule << "-s #{ip_with_mask(rule_resource, rule_resource.source)} " if rule_resource.source && rule_resource.source != '0.0.0.0/0'
        firewall_rule << "-d #{rule_resource.destination} " if rule_resource.destination

        firewall_rule << "-i #{rule_resource.interface} " if rule_resource.interface
        firewall_rule << "-o #{rule_resource.dest_interface} " if rule_resource.dest_interface

        firewall_rule << "-p #{rule_resource.protocol} " if rule_resource.protocol && rule_resource.protocol.to_s.to_sym != :none
        firewall_rule << '-m tcp ' if rule_resource.protocol && rule_resource.protocol.to_s.to_sym == :tcp

        # using multiport here allows us to simplify our greps and rule building
        firewall_rule << "-m multiport --sports #{port_to_s(rule_resource.source_port)} " if rule_resource.source_port
        firewall_rule << "-m multiport --dports #{port_to_s(dport_calc(rule_resource))} " if dport_calc(rule_resource)

        firewall_rule << "-m state --state #{rule_resource.stateful.is_a?(Array) ? rule_resource.stateful.join(',').upcase : rule_resource.stateful.upcase} " if rule_resource.stateful
        # the comments extension is not available for ip6tables on rhel/centos 5
        unless el5 && ipv6
          firewall_rule << "-m comment --comment \"#{rule_resource.description}\" " if rule_resource.include_comment
        end

        firewall_rule << "-j #{TARGET[rule_resource.command.to_sym]} "
        firewall_rule << "--to-ports #{rule_resource.redirect_port} " if rule_resource.command == :redirect
        firewall_rule.strip!
        firewall_rule
      end

      def iptables_packages(new_resource)
        packages = if ipv6_enabled?(new_resource)
                     %w(iptables iptables-ipv6)
                   else
                     %w(iptables)
                   end

        # centos 7 requires extra service
        if !debian?(node) && node['platform_version'].to_i >= 7
          packages << %w(iptables-services)
        end

        packages.flatten
      end

      def iptables_commands(new_resource)
        if ipv6_enabled?(new_resource)
          %w(iptables ip6tables)
        else
          %w(iptables)
        end
      end

      def log_iptables(new_resource)
        iptables_commands(new_resource).each do |cmd|
          shell_out!("#{cmd} -L -n")
        end
      rescue
        Chef::Log.info('log_iptables failed!')
      end

      def iptables_flush!(new_resource)
        iptables_commands(new_resource).each do |cmd|
          shell_out!("#{cmd} -F")
        end
      end

      def iptables_default_allow!(new_resource)
        iptables_commands(new_resource).each do |cmd|
          shell_out!("#{cmd} -P INPUT ACCEPT")
          shell_out!("#{cmd} -P OUTPUT ACCEPT")
          shell_out!("#{cmd} -P FORWARD ACCEPT")
        end
      end

      def default_ruleset(current_node)
        current_node['firewall']['iptables']['defaults'][:ruleset].to_h
      end

      def ensure_default_rules_exist(current_node, new_resource)
        input = new_resource.rules

        # don't use iptables_commands here since we do populate the
        # hash regardless of ipv6 status
        %w(iptables ip6tables).each do |name|
          input[name] = {} unless input[name]
          input[name].merge!(default_ruleset(current_node).to_h)
        end
      end
    end
  end
end
