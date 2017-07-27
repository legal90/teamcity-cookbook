#
# Cookbook Name:: teamcity
# Recipe:: default
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
if platform_family?('windows')
  include_recipe 'java::notify'

  include_recipe 'chocolatey'

  chocolatey_package "jdk#{node['java']['jdk_version']}" do
    action :install
    notifies :write, 'log[jdk-version-changed]', :immediately
  end
else
  include_recipe 'java'

  group node['teamcity']['group']

  user node['teamcity']['username'] do
    gid node['teamcity']['group']
    shell '/bin/bash'
    password node['teamcity']['password'] unless node['teamcity']['password'].nil?
  end
end

include_recipe 'teamcity::agent'
