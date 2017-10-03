#
# Cookbook Name:: teamcity
# Recipe:: agent
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

if node['teamcity']['agent']['server_uri'].to_s == ''
  raise "Attribute node['teamcity']['agent']['server_uri'] is not specified!" \
        'You need to set it to proceed the Teamcity agent installation'
end

TEAMCITY_PATH = File.join(node['teamcity']['install_prefix'], 'teamcity')

include_recipe 'ark'

ark 'teamcity' do
  url ::URI.join(node['teamcity']['agent']['server_uri'], 'update/buildAgent.zip').to_s
  path node['teamcity']['install_prefix']
  strip_components 0
  version node['teamcity']['version']
  creates 'bin/agent.sh'
  action :put
  unless platform_family? 'windows'
    owner node['teamcity']['username']
    group node['teamcity']['group']
  end
end

directory File.join(TEAMCITY_PATH, 'conf/') do
  recursive true
  mode 0o755
  unless platform_family? 'windows'
    owner node['teamcity']['username']
    group node['teamcity']['group']
  end
end

template File.join(TEAMCITY_PATH, 'conf/', 'buildAgent.properties') do
  source 'buildAgent.properties.erb'
  mode 0o644
  variables(
    server_uri:          node['teamcity']['agent']['server_uri'],
    name:                node['teamcity']['agent']['name'],
    own_address:         node['teamcity']['agent']['own_address'],
    own_port:            node['teamcity']['agent']['port'],
    authorization_token: node['teamcity']['agent']['authorization_token'],
    system_properties:   node['teamcity']['agent']['system_properties'],
    env_properties:      node['teamcity']['agent']['env_properties'],
    work_dir:            node['teamcity']['agent']['work_dir'],
    temp_dir:            node['teamcity']['agent']['temp_dir'],
    system_dir:          node['teamcity']['agent']['system_dir']
  )
  unless platform_family? 'windows'
    owner node['teamcity']['username']
    group node['teamcity']['group']
  end
end

# Setup the system service.
# Don't notify Teamcity Agent service - it will restart itself automatically
# on any config file change.
if platform_family? 'windows'
  execute 'install teamcity service' do
    command File.join(TEAMCITY_PATH, 'bin/', 'service.install.bat')
    cwd File.join(TEAMCITY_PATH, 'bin/')
    action :run
    not_if { ::Win32::Service.exists? node['teamcity']['service_name'] }
  end
else
  file File.join(TEAMCITY_PATH, 'bin/', 'agent.sh') do
    owner node['teamcity']['username']
    group node['teamcity']['group']
    mode 0o750
  end

  template "/etc/init.d/#{node['teamcity']['service_name']}" do
    source 'teamcity_agent_init.erb'
    mode 0o755
    owner 'root'
    group 'root'
    variables(
      teamcity_user_name:    node['teamcity']['username'],
      teamcity_service_name: node['teamcity']['service_name'],
      teamcity_executable:   File.join(TEAMCITY_PATH, 'bin/', 'agent.sh'),
      teamcity_pidfile:      File.join(TEAMCITY_PATH, 'logs/', 'buildAgent.pid')
    )

    # Trigger the gereration of teamcity.service unit on systemd-driven systems
    if node['init_package'] == 'systemd'
      notifies :run, 'execute[systemd_reload]', :immediately
    end
  end

  execute 'systemd_reload' do
    command 'systemctl daemon-reload'
    action :nothing
  end
end

service node['teamcity']['service_name'] do
  supports start: true, stop: true, restart: true, status: true
  action :enable
  action :start if node['teamcity']['agent']['start_service']
end
