#
# Cookbook Name:: ops_resource_discovery
# Recipe:: default
#
# Copyright 2015, P. van der Velde
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'ops_resource_discovery::consul'
include_recipe 'ops_resource_discovery::consul_config'
include_recipe 'ops_resource_discovery::consul_as_dns'