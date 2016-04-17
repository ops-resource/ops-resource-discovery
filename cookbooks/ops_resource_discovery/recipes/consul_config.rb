#
# Cookbook Name:: ops_resource_discovery
# Recipe:: consul_config
#
# Copyright 2015, P. van der Velde
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'windows'


# STORE PROVISIONING SCRIPT
provisioning_directory = node['paths']['provisioning_base']
directory provisioning_directory do
  action :create
end

consul_script = 'Consul.ps1'
cookbook_file "#{provisioning_directory}\\#{consul_script}" do
  source consul_script
  action :create
end

provisioning_script = 'Initialize-ConsulResource.ps1'
cookbook_file "#{provisioning_directory}\\#{provisioning_script}" do
  source provisioning_script
  action :create
end