class puppet::packages {
  $use_puppetlabs_version = $puppet[use_puppetlabs_version]
  $puppet_version = $puppet[version]
  $facter_version = $puppet[facter_version]
  
  if $use_puppetlabs_version == 1 {
    $script = "/usr/local/sbin/puppetlabs.sh"
    file { "$script":
      ensure => file,
      source => "puppet://puppet/modules/puppet/puppetlabs.sh",
      owner  => "root",
      group  => "root",
      mode   => 755,
    }
    exec { "run-puppetlabs.sh":
      command => "$script on",
      require => File["$script"],
      before  => Package["facter", "puppet", "puppet-common"],
    }
  } else {
    package { "puppetlabs-release":
      ensure => "absent",
    }
    # clean up the temp file from puppetlabs.sh if its there
    file { "/etc/apt/sources.list.d/puppet.list":
      ensure  => absent,
    }
  }
  
  package { [
      "augeas-tools", 
      "ruby1.8", 
      "libaugeas-ruby1.8", 
      "libshadow-ruby1.8", 
      "ruby",
    ]:
    ensure => "${package_ensure}",
  }

  package { "facter":
    ensure => "${facter_version}"
  }
  
  package { ["puppet-common", "puppet"]:
    ensure => "${puppet_version}",
    require => Package["facter"],
  }
}

class puppet::puppetrun {
  file { "/usr/local/bin/puppetrun":
    ensure => file,
    source => "puppet://puppet/modules/puppet/puppetrun",
    owner  => "root",
    group  => "root",
    mode   => 755,
    require => Class["sudo"],
  }
}

class puppet::config {
  file { "/etc/puppet/puppet.conf":
    ensure => file,
    content => template("puppet/puppet.conf.erb"),
    owner  => "root",
    group  => "root",
    mode   => 644,
    require => Class["puppet::packages"],
  }
  file { "/etc/default/puppet":
    ensure => file,
    content => template("puppet/default_puppet.erb"),
    owner  => "root",
    group  => "root",
    mode   => 644,
    require => Class["puppet::packages"],
  }
}

class puppet::services {
  service { "puppet":
    enable  => false,
    ensure  => stopped,
    require => Class["puppet::packages", "puppet::config"]
  }
}

class puppet::cron {
  if $profile == "manage" {
    # run 'first' in any given cycle
    $minute = 1
  } elsif $profile == "smarthost" {
    # updating mail serving soon, so we have a good chance to receive all errors
    $minute = 5
  } elsif $profile == "loghost" {
    # updating log serving soon, so we have a good chance to receive al lerrors
    $minute = 6
  } elsif $profile == "monitorhost" {
    # update monitoring last, so we have a good chance all the things we monitor are up
    $minute = 59
  }
  else {
    # spread out clients to even out load on the server
    # but run 'after' the early runs and before the 'late' runs
    $minute = fqdn_rand(40, 10)
  }
  cron { "puppet-from-cron":
    command => "puppet agent --onetime --no-daemonize",
    user    => root,
    hour    => [9, 11, 13, 15], # run once every 2 hours during office hours
    weekday => [1, 2, 3, 4, 5], # run only during weekdays
    minute  => $minute,
  }
}

class puppet {
  include puppet::packages, puppet::config, puppet::services, puppet::cron, puppet::puppetrun
}
