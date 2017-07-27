if os.windows?
  prefix = 'C:/'
  service_name = 'TCBuildAgent'
else
  prefix = '/opt'
  service_name = 'teamcity'
end

describe directory("#{prefix}/teamcity") do
  it { should exist }
end

describe file("#{prefix}/teamcity/bin/agent.sh") do
  it { should exist }
end

describe file("#{prefix}/teamcity/bin/service.install.bat") do
  it { should exist }
end

describe service(service_name) do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe port(9090) do
  it { should be_listening }
end
