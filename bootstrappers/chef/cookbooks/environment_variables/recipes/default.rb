#
# Cookbook Name:: environment_variables
# Recipe:: default
#
# Copyright 2014, Room 118 Solutions
#
# All rights reserved - Do Not Redistribute
#

# chef can't deal with an empty file
bash "ensure /etc/environment has content" do
  code %(echo "# touched at `date`" > /etc/environment)
  only_if { File.stat("/etc/environment").size.zero? }
end

ruby_block "setup system ENVIRONMENT variables" do
  block do
    require "chef/util/file_edit"
    file = Chef::Util::FileEdit.new "/etc/environment"

    node["environment_variables"].each do |key, value|
      # Quote a value that includes a backslash
      value = "'#{value}'" if value =~ /\\/

      key_value = "#{key}=#{value}"

      match = /#{key}/
      file.search_file_replace_line(match, key_value) # update existing
      file.insert_line_if_no_match(match, key_value) # add new
      file.write_file
    end
  end
end
