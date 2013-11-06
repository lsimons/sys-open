class snmp::packages {

  package { [
    "snmpd",
    "snmp",
    "libsnmp-base",
    "libsnmp15"
  ]:
    ensure => "${package_ensure}",
  }
}

class snmp::config {
  include snmp::config::mibs

  # Load them mibs!
  file { "/etc/snmp/snmp.conf":
    ensure => file,
    path   => "/etc/snmp/snmp.conf",
    content => template("snmp/snmp.conf.erb"),
    owner   => root,
    group   => root,
    require => Class["snmp::config::mibs"],
  }

  file { "/etc/snmp/snmpd.conf":
    ensure  => file,
    path    => "/etc/snmp/snmpd.conf",
    content => template("snmp/snmpd.conf.erb"),
    owner   => root,
    group   => root,
    mode    => 0600,
    require => Class["snmp::config::mibs"],
    notify  => Service["snmpd"],
  }

  # handy dandy. Now root can simply use 'snmpwalk some.host':
  file { "/root/.snmp":
    ensure  => directory,
    path    => "/root/.snmp",
    owner   => root,
    group   => root,
    mode    => 0700,
  }
  file { "/root/.snmp/snmp.conf":
    ensure  => file,
    path    => "/root/.snmp/snmp.conf",
    content => template("snmp/snmp.conf.erb"),
    owner   => root,
    group   => root,
    mode    => 0600,
    require => [File["/root/.snmp"], Class["snmp::config::mibs"],],
    #notify  => "snmpd",
  }
}

class snmp::config::extensions {
  file { "/etc/snmp/extensions":
    ensure       => directory,
    owner        => root,
    group        => root,
    path         => "/etc/snmp/extensions",
    source       => "puppet:///modules/snmp/extensions",
    recurse      => remote,
    recurselimit => 3,
    require      => Class["snmp::packages"],
  }
}

class snmp::config::mibs {
  # Due to licensing issues many mib files are not included in the
  # Debian/Ubuntu package. Hence:
  file { "/var/lib/mibs":
    ensure       => directory,
    owner        => root,
    group        => root,
    path         => "/var/lib/mibs",
    source       => "puppet:///modules/snmp/mibs",
    recurse      => remote,
    recurselimit => 3,
    ignore       => ".index",
  }

  file { "/usr/share/mibs/ietf":
    ensure => link,
    target => "/var/lib/mibs/ietf",
    require => File["/var/lib/mibs"]
  }

  file { "/usr/share/mibs/iana":
    ensure => link,
    target => "/var/lib/mibs/iana",
    require => File["/var/lib/mibs"]
  }

}

class snmp::services {
  service { "snmpd":
    ensure  => running,
    enable  => true,
    require => Class["snmp::packages", "snmp::config"],
    subscribe => File["/etc/snmp/snmpd.conf"],
  }
}

class snmp {
  include snmp::packages, snmp::config, snmp::services, snmp::config::extensions
}
