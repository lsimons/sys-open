class slapd::packages {

  package { [
    "slapd",
    "ldap-utils"
  ]:
    ensure => "${package_ensure}",
  }
}


class slapd::config {
  file { "slapd_config.sh":
    name   => "/usr/local/sbin/slapd_config.sh",
    content => template("slapd/slapd_config.sh.erb"),
    owner   => "root",
    group   => "root",
    mode    => 744
  }
  
  exec { "slapd_config":
    subscribe   => File["slapd_config.sh"],
    refreshonly => true,
    command     => "slapd_config.sh",
    require     => [File["slapd_config.sh"], Class["slapd::packages"]]
  }
}

class slapd::services {
  service { "slapd":
    ensure  => running,
    enable  => true,
    require => Class["slapd::packages", "slapd::config"],
    subscribe => File["/etc/snmp/snmpd.conf"],
  }
}

class slapd {
  include firewall::ldaps, slapd::packages, slapd::config, slapd::services
}
