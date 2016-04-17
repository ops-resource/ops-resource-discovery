default['env_external']['dns_server'] = '${ConsulExternalDnsServers}'

# Servers
default['env_consul']['consul_server_count'] = ${ConsulServerCount}

# Consul agent data center
default['env_consul']['consul_datacenter'] = '${ConsulDataCenterName}'

# Consul agent ports
default['env_consul']['consul_dns_port'] = 53
default['env_consul']['consul_http_port'] = 8530
default['env_consul']['consul_rpc_port'] = 8430
default['env_consul']['consul_serf_lan_port'] = 8331
default['env_consul']['consul_serf_wan_port'] = 8332
default['env_consul']['consul_server_port'] = 8330

# Consul domain
default['env_consul']['consul_domain'] = '${ConsulDomain}'
