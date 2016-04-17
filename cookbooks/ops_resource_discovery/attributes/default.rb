logs_path = 'c:\\logs'
default['paths']['log'] = logs_path

meta_base_path = 'c:\\meta'
default['paths']['meta'] = meta_base_path

ops_base_path = 'c:\\ops'
default['paths']['ops_base'] = ops_base_path

consul_base_path = "#{ops_base_path}\\consul"
default['paths']['consul_base'] = consul_base_path
default['paths']['consul_bin'] = "#{consul_base_path}\\bin"
default['paths']['consul_data'] = "#{consul_base_path}\\data"
default['paths']['consul_ui'] = "#{consul_base_path}\\ui"

consul_logs_path = "#{logs_path}\\consul"
default['paths']['consul_logs'] = consul_logs_path

consul_config_path = "#{meta_base_path}\\consul"
default['paths']['consul_config'] = consul_config_path
default['paths']['consul_checks'] = "#{consul_config_path}\\checks"

default['service']['consul'] = 'consul'

# The user who is used to run the consul webservice
default['user']['consul_user_username'] = 'consul_user'
default['user']['consul_user_password'] = SecureRandom.uuid
