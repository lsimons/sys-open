# http://mig5.net/content/one-touch-provisioning-and-auto-monitoring-new-servers

class nagios::packages {
  package { 'nagios3':
    ensure => "${package_ensure}",
    alias  => 'nagios',
  }
  package { 'nagios-plugins-basic':
    ensure => "${package_ensure}",
  }
  package { 'nagios3-doc':
    ensure => "${package_ensure}",
  }
  package { 'nagiosgrapher':
    ensure => "${package_ensure}",
  }
}

class nagios::services {
  service { 'nagios3':
    ensure     => running,
    alias      => 'nagios',
    require    => Class["nagios::packages"],
    hasstatus  => true,
    hasrestart => true,
  }
  
}

class nagios::configs {

  file { '/etc/nagios3/apache2.conf':
    ensure     => file,
    content    => template("nagios/apache2.conf.erb"),
    owner      => nagios,
    group      => nagios,
    mode       => 0644,
    require    => [
      Class["nagios::packages"],
    ],
  }
  file { '/etc/apache2/conf.d/nagios3.conf':
    ensure => link,
    target => "/etc/nagios3/apache2.conf",
    notify => Service["apache2"],
    require => [
      Package["apache2", "nagios3"],
      File["/etc/nagios3/apache2.conf"]
    ],
  } 


  # Used by cgi to write to:
  file { '/var/lib/nagios3':
    ensure     => directory,
    require    => Class["nagios::packages"],
    owner      => nagios,
    group      => nagios,
    mode       => 0751,
    notify     => Service["nagios"],
  }

  # Used by cgi to write to:
  file { '/var/lib/nagios3/rw':
    ensure     => directory,
    require    => Class["nagios::packages"],
    owner      => nagios,
    group      => www-data,
    mode       => 2710,
    notify     => Service["nagios"],
  }

  # CGI (webinterface) settings:
  file { '/etc/nagios3/cgi.cfg':
    ensure     => file,
    require    => Class["nagios::packages"],
    owner      => root,
    group      => root,
    mode       => 0644,
    #source     => "puppet:///modules/nagios/nagios3/cgi.cfg",
    content    => template("nagios/cgi.cfg.erb"),
    notify     => Service["nagios"],
  }

  # Main nagios config file:
  file { '/etc/nagios3/nagios.cfg':
    ensure     => file,
    require    => Class["nagios::packages"],
    owner      => root,
    group      => root,
    mode       => 0644,
    content    => template("nagios/nagios.cfg.erb"),
    notify     => Service["nagios"],
  }

  # hostgroups:
  file { '/etc/nagios3/conf.d/hostgroups.cfg':
    ensure     => file,
    require    => Class["nagios::packages"],
    owner      => root,
    group      => root,
    mode       => 0644,
    content    => template("nagios/hostgroups.cfg.erb"),
    notify     => Service["nagios"],
  }
  file { '/etc/nagios3/conf.d/extinfo_nagios2.cfg':
    ensure  => absent,
  }
  file { '/etc/nagios3/conf.d/hostgroups_nagios2.cfg':
    ensure  => absent,
  }
  
  #Was replaced by a template:
  file { '/etc/nagios3/conf.d/contacts_nagios2.cfg':
    ensure  => absent,
  }

  # Resources. Can contain passwords/usernames/variables that should not be
  # readable by the CGI.
  # For all intended purposes, this file is mostly unused currently.
  file { '/etc/nagios3/resource.cfg':
    ensure     => file,
    require    => Class["nagios::packages"],
    owner      => root,
    group      => root,
    mode       => 0644,
    content    => template("nagios/resource.cfg.erb"),
    notify     => Service["nagios"],
  }
  
  file { '/etc/nagios3/conf.d/contacts.cfg':
    ensure     => file,
    require    => [
                    Class["nagios::packages"],
                    File["/etc/nagios3/conf.d/contacts_nagios2.cfg"],
                  ],
    content    => template("nagios/contacts.cfg.erb"),
    notify     => Service["nagios"],
  }

  # Command definitions. 
  file { '/etc/nagios3/commands.cfg':
    ensure     => file,
    require    => Class["nagios::packages"],
    owner      => root,
    group      => root,
    mode       => 0644,
    content    => template("nagios/commands.cfg.erb"),
    notify     => Service["nagios"],
  }

  # There are some statements in there that conflict with ours:
  file { '/etc/nagios-plugins/config/snmp.cfg':
    # Make sure the old file is gone.
    ensure     => absent,
    notify     => Service["nagios"],
  }

  # All our configfiles will be added to those already in that folder. 
  file { '/etc/nagios3/conf.d':
    ensure       => directory,
    require      => Class["nagios::packages"],
    owner        => root,
    group        => root,
    mode         => 0755,
    source       => "puppet:///modules/nagios/nagios3/conf.d/",
    recurse      => remote,
    recurselimit => 2,
    notify       => Service["nagios"],
  }

  # All our plugins will be added to the standard available plugins.
  # One of the plugins uses bc to calculate memory. The bc package should be in
  # 'basepackages', as there's probably more reasons for having that installed.
  file { '/usr/lib/nagios/plugins':
    ensure       => directory,
    require      => [Package["bc"], Class["nagios::packages"]],
    owner        => root,
    group        => root,
    mode         => 0755,
    source       => "puppet:///modules/nagios/plugins/",
    recurse      => remote,
    recurselimit => 2,
  }
}

# this isn't needed anymore now, since we are using file {} now instead of nagios_host {}
class nagios::bug3299 {
  # There is a featurerequest in puppet to enable the setting of permissions
  # for the Nagios resources. Until that time, the default is 0600, which is
  # too strict for nagios.
  # Hence this workaround.
  exec { "find /etc/nagios3/conf.d/ -type f -exec chmod -R 0644 {} \\;":
    path => ["/usr/bin", "/bin",],
    require => [
      Class["nagios::configs"], 
    ],
    notify     => Service["nagios"],
  }
}

class nagios {
  include apache
  include nagios::packages
  include nagios::services
  include nagios::configs
  # include nagios::bug3299
}

define nagios::puppetconfig ($host, $host_classes, $host_params) {
  file { "/etc/sys/puppet/modules/common/nagios/files/nagios3/conf.d/${host}.cfg":
    owner   => "root",
    group   => "root",
    content => template("nagios/host.cfg.erb"),
  }
}

class nagios::puppetconfigs {
  include nagios::hosts
}
