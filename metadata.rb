name 'teamcity'
maintainer 'Mikhail Zholobov'
maintainer_email 'legal90@gmail.com'
license 'Apache-2.0'
description 'Installs/Configures TeamCity agent/server.'
version '0.1.0'

recipe 'teamcity::default', 'Installs Java and TeamCity Build Agent'
recipe 'teamcity::agent', 'Installs a TeamCity Build Agent'

supports 'redhat', '>= 6.0'
supports 'centos', '>= 6.0'
supports 'debian', '>= 7.0'
supports 'ubuntu', '>= 12.04'
supports 'windows'

depends 'ark'
depends 'java'
depends 'chocolatey'

chef_version '>= 12.6' if respond_to?(:chef_version)
