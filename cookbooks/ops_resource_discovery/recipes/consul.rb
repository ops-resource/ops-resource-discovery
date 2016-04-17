#
# Cookbook Name:: ops_resource_discovery
# Recipe:: consul
#
# Copyright 2015, P. van der Velde
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'windows'
include_recipe 'windows_firewall'

Chef::Recipe.send(:include, Discovery::Helper)

# CREATE CONSUL USER
consul_user_username = node['user']['consul_user_username']
consul_user_password = node['user']['consul_user_password']
user consul_user_username do
  password consul_user_password
  action :create
end

group 'Performance Monitor Users' do
  action :modify
  members consul_user_username
  append true
end

# Grant the user the LogOnAsService permission. Following this anwer on SO: http://stackoverflow.com/a/21235462/539846
# With some additional bug fixes to get the correct line from the export file and to put the correct text in the import file
powershell_script 'user_grant_service_logon_rights' do
  code <<-POWERSHELL
    $ErrorActionPreference = 'Stop'

    $userName = "#{consul_user_username}"

    $tempPath = "#{log_directory}"
    $import = Join-Path -Path $tempPath -ChildPath "import.inf"
    if(Test-Path $import)
    {
        Remove-Item -Path $import -Force
    }

    $export = Join-Path -Path $tempPath -ChildPath "export.inf"
    if(Test-Path $export)
    {
        Remove-Item -Path $export -Force
    }

    $secedt = Join-Path -Path $tempPath -ChildPath "secedt.sdb"
    if(Test-Path $secedt)
    {
        Remove-Item -Path $secedt -Force
    }

    Write-Host ("Granting SeServiceLogonRight to user account: {0} on host: {1}." -f $userName, $computerName)
    $sid = ((New-Object System.Security.Principal.NTAccount($userName)).Translate([System.Security.Principal.SecurityIdentifier])).Value

    secedit /export /cfg $export
    $line = (Select-String $export -Pattern "SeServiceLogonRight").Line
    $sids = $line.Substring($line.IndexOf('=') + 1).Trim()

    $lines = @(
            "[Unicode]",
            "Unicode=yes",
            "[System Access]",
            "[Event Audit]",
            "[Registry Values]",
            "[Version]",
            "signature=`"`$CHICAGO$`"",
            "Revision=1",
            "[Profile Description]",
            "Description=GrantLogOnAsAService security template",
            "[Privilege Rights]",
            "SeServiceLogonRight = $sids,*$sid"
        )
    foreach ($line in $lines)
    {
        Add-Content $import $line
    }

    secedit /import /db $secedt /cfg $import
    secedit /configure /db $secedt
    gpupdate /force
  POWERSHELL
end

# CONFIGURE LOG DIRECTORIES
log_directory = node['paths']['log']
directory log_directory do
  rights :read, 'Everyone', applies_to_children: true
  rights :modify, 'Administrators', applies_to_children: true
  action :create
end

consul_log_directory = node['paths']['consul_logs']
directory consul_log_directory do
  rights :read, 'Everyone', applies_to_children: true
  rights :modify, consul_user_username, applies_to_children: true, applies_to_self: false
  rights :modify, 'Administrators', applies_to_children: true
  action :create
end

# CONFIGURE CONSUL DIRECTORIES
ops_base_directory = node['paths']['ops_base']
directory ops_base_directory do
  rights :read, 'Everyone', applies_to_children: true
  rights :modify, 'Administrators', applies_to_children: true
  action :create
end

consul_base_directory = node['paths']['consul_base']
directory consul_base_directory do
  action :create
end

# CONFIGURE CONSUL CONFIG DIRECTORIES
consul_config_directory = node['paths']['consul_config']
directory consul_config_directory do
  rights :read_execute, 'Everyone', applies_to_children: true, applies_to_self: false
  rights :modify, 'Administrators', applies_to_children: true
  action :create
end

consul_checks_directory = node['paths']['consul_checks']
directory consul_checks_directory do
  action :create
end

# CONFIGURE CONSUL EXECUTABLE
consul_bin_directory = node['paths']['consul_bin']
directory consul_bin_directory do
  rights :read_execute, 'Everyone', applies_to_children: true, applies_to_self: false
  action :create
end

consul_exe = 'consul.exe'
cookbook_file "#{consul_bin_directory}\\#{consul_exe}" do
  source consul_exe
  action :create
end

powershell_script 'firewall_open_TCP_ports_for_consul' do
  code <<-POWERSHELL
    netsh advfirewall firewall add rule name=\"Consul_Tcp\" dir=in action=allow protocol=TCP program=\"#{consul_bin_directory}\\#{consul_exe}\" enable=yes profile=domain
  POWERSHELL
end

powershell_script 'firewall_open_UDP_ports_for_consul' do
  code <<-POWERSHELL
    netsh advfirewall firewall add rule name=\"Consul_UDP\" dir=in action=allow protocol=UDP program=\"#{consul_bin_directory}\\#{consul_exe}\" enable=yes profile=domain
  POWERSHELL
end

# Getting a comma separed set of IP addresses that are the IP addresses of the DNS recusors
# For the consul configuration we want a formatted string that looks like:
# "recursor_IP_1","recursor_IP_2","recursor_IP_3"
recusors_formatted = node['env_external']['dns_server'].gsub(',', '\",\"')
consul_config_recursors = "\"#{recursors_formatted}\""

consul_config_file = 'consul_default.json'
machine_ip = local_ip

environment = 'env_consul'
datacenter = node[environment]['consul_datacenter']
dns_port = node[environment]['consul_dns_port']
http_port = node[environment]['consul_http_port']
rpc_port = node[environment]['consul_rpc_port']
serf_lan_port = node[environment]['consul_serf_lan_port']
serf_wan_port = node[environment]['consul_serf_wan_port']
server_port = node[environment]['consul_server_port']

consuldomain = node[environment]['consul_domain']

numberofservers = node[environment]['consul_server_count']

# We need to multiple-escape the escape character because of ruby string and regex etc. etc. See here: http://stackoverflow.com/a/6209532/539846
consul_data_directory_json_escaped = consul_data_directory.gsub('\\', '\\\\\\\\')
file "#{consul_bin_directory}\\#{consul_config_file}" do
  content <<-JSON
{
  "data_dir": "#{consul_data_directory_json_escaped}",

  "bootstrap_expect" : #{numberofservers},
  "datacenter": "#{datacenter}",
  "server": true,

  "domain": "#{consuldomain}",

  "addresses": {
    "dns": "#{machine_ip}"
  },
  "ports": {
    "dns": #{dns_port},
    "http": #{http_port},
    "rpc": #{rpc_port},
    "serf_lan": #{serf_lan_port},
    "serf_wan": #{serf_wan_port},
    "server": #{server_port}
  },

  "dns_config" : {
    "allow_stale" : true,
    "max_stale" : "5s",
    "node_ttl" : "15m",
    "service_ttl": {
      "*": "15m"
    }
  },

  "recursors": [#{consul_config_recursors}],

  "disable_remote_exec": true,
  "disable_update_check": true,

  "log_level" : "debug"
}
  JSON
end


# CONFIGURE WINDOWS SERVICE
service_exe_name = 'consul_service'

cookbook_file "#{consul_bin_directory}\\#{service_exe_name}.exe" do
  source 'winsw.exe'
  action :create
end

file "#{consul_bin_directory}\\#{service_exe_name}.exe.config" do
  content <<-XML
<configuration>
    <runtime>
        <generatePublisherEvidence enabled="false"/>
    </runtime>
    <startup>
        <supportedRuntime version="v4.0" />
        <supportedRuntime version="v2.0.50727" />
    </startup>
</configuration>
  XML
  action :create
end

service_name = node['service']['consul']
consul_bin_directory = node['paths']['consul_bin']
file "#{consul_bin_directory}\\#{service_exe_name}.xml" do
  content <<-XML
<?xml version="1.0"?>
<!--
    The MIT License Copyright (c) 2004-2009, Sun Microsystems, Inc., Kohsuke Kawaguchi Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
    subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
    PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
    OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-->

<service>
    <id>#{service_name}</id>
    <name>#{service_name}</name>
    <description>This service runs the consul server.</description>

    <executable>#{consul_bin_directory}\\consul.exe</executable>
    <arguments>agent -config-file=#{consul_bin_directory}\\#{consul_config_file} -config-dir=#{consul_config_directory}</arguments>

    <logpath>#{consul_log_directory}</logpath>
    <log mode="roll-by-size">
        <sizeThreshold>10240</sizeThreshold>
        <keepFiles>8</keepFiles>
    </log>
    <onfailure action="restart"/>
</service>
    XML
  action :create
end

powershell_script 'consul_as_service' do
  code <<-POWERSHELL
    $ErrorActionPreference = 'Stop'

    $securePassword = ConvertTo-SecureString "#{consul_user_password}" -AsPlainText -Force

    # Note the .\\ is to get the local machine account as per here:
    # http://stackoverflow.com/questions/313622/powershell-script-to-change-service-account#comment14535084_315616
    $credential = New-Object pscredential((".\\" + "#{consul_user_username}"), $securePassword)

    # Create the new service
    New-Service `
        -Name '#{service_name}' `
        -BinaryPathName '#{consul_akmeta_bin_directory}\\#{service_exe_name}.exe' `
        -Credential $credential `
        -DisplayName '#{service_name}' `
        -StartupType Automatic

    # Set the service to restart if it fails
    sc.exe failure #{service_name} reset=86400 actions=restart/5000
  POWERSHELL
end

# Create the event log source for the jenkins service. We'll create it now because the service runs as a normal user
# and is as such not allowed to create eventlog sources
registry_key "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\services\\eventlog\\Application\\#{service_name}" do
  values [{
    name: 'EventMessageFile',
    type: :string,
    data: 'c:\\Windows\\Microsoft.NET\\Framework64\\v4.0.30319\\EventLogMessages.dll'
  }]
  action :create
end

# STORE CONFIGURATION INFORMATION
meta_directory = node['paths']['meta']
consul_bin_directory_escaped = consul_bin_directory.gsub('\\', '\\\\\\\\')
consul_config_directory_escaped = consul_config_directory.gsub('\\', '\\\\\\\\')
file "#{meta_directory}\\service_consul.json" do
  content <<-JSON
{
    "install_path": "#{consul_bin_directory_escaped}",
    "config_path": "#{consul_config_directory_escaped}",
}
  JSON
  action :create
end

# push up consul information to provisioning server
