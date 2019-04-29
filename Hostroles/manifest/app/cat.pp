## This is GV hostrole file
class hostroles::app::capsule::inv::cat {
  # only install sumo on live
  case $::[] {
    'qa':  {
      class { 'platforms::se::base':
        sumo_accessid  => '',
        sumo_accesskey => '',
      }
##    include platforms::monit::globalvehicle
##    include platforms::monit::init

    }
    'live':  {
      class { 'platforms::se::base':
        sumo_accessid  => '',
        sumo_accesskey => '',
      }
    }
    default: {
      include platforms::se::base
    }
  }
  case $::[] {
    'live','qa','dev': {
      class {'platforms::newrelic::java_agent':
        app_name => 'global-vehicle-services',
      }
    }
    default: { }
  }
  class {'platforms::newrelic::server_monitor':
    newrelic_license_key => '',
  }
  case $::[] {
    'live','qa','dev': {
      include platforms::monit::catvehicle
      include platforms::monit::init
    }
    default: { }
  }

  platforms::jdk { 'jdk-1.7.0-55': }
  -> file { '/usr/java/global-vehicle-jdk':
    ensure => 'link',
    target => '/usr/java/default',
  }
  include platforms::capsule
  include platforms::remote_config
  include platforms::sysctl::coherence
  include platforms::mounts::images
  include platforms::mounts::videos
  include platforms::mounts::www
  include platforms::mounts::jdpa
  include platforms::newrelic::java_agent

  include platforms::spacewalk::activation  # only required on centos 6

  class { 'platforms::custom_hostsfile': type => 'cat' }
  if ($::[] == 'qa') {
    host { 'helix-db1.earthcars.net': ip => '' }
}
