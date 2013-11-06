##################################################
### Munin Client
##################################################
class munin::service {
  service { "munin-node":
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
  }
}

class munin::client {
  include munin::service

  package { "munin-node":
    ensure => "${package_ensure}",
  }

  exec { "munin-ssl-cert":
    user          => root,
    command       => "/usr/sbin/usermod -a -G ssl-cert,syslog munin",
    require       => [
      Package["munin-node"],
      Package["ssl-cert"]
    ],
    onlyif        => "sh -c '! /usr/bin/groups munin | grep ssl-cert'",
  }

  file { "/etc/munin/munin-node.conf":
    ensure  => file,
    content => template("munin/munin-node.conf.erb"),
    notify => Service["munin-node"],
    require => [
      Package["munin-node"],
      Class["pki::host::publish"],
      Exec["munin-ssl-cert"],
    ],
  }
  file { "/etc/munin/ca.pem":
    ensure  => absent,
  }

  file { "/etc/munin/${clientcert}_key.pem":
    ensure  => absent,
  }
  file { "/etc/munin/${clientcert}_cert.pem":
    ensure  => absent,
  }
}

##################################################
### Munin Server
##################################################
class munin::setup {
  file { "/etc/munin":
    ensure  => directory,
    owner   => "munin",
    group   => "munin",
  }
  file { "/etc/munin/apache.conf":
    ensure  => file,
    content => template("munin/apache.conf.erb"),
    require => [
      Package["munin"],
      File["/etc/munin"],
      File["/etc/sys/htpasswd"],
    ],
  }
  file { "/etc/apache2/conf.d/munin":
    ensure => link,
    target => "/etc/munin/apache.conf",
    notify => Service["apache2"],
    require => [
      Package["apache2", "munin"],
      File["/etc/munin/apache.conf"],
    ],
  } 
}

define munin::server::config($monitor_hosts) {
  file { "/etc/munin/munin.conf":
    ensure  => file,
    content => template("munin/munin.conf.erb"),
    require => [
      Package["munin"],
      File["/etc/munin"],
      Class["pki::host::publish"],
      Exec["munin-ssl-cert"],
    ],
    subscribe => Exec["munin-ssl-cert"],
  }
}

class munin::server {
  package { "munin":
    ensure => "${package_ensure}",
  }

  include apache
  include munin::setup
  include munin::hosts
  include munin::client
}
