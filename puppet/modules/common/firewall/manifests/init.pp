class firewall::ufw {
  package { "ufw":
    ensure => "${package_ensure}",
  }

  Package["ufw"] -> Exec["ufw-default-deny"] -> Exec["ufw-enable"]

  exec { "ufw-default-deny":
    command => "ufw default deny",
    unless  => "ufw status verbose | grep \"[D]efault: deny (incoming), allow (outgoing)\"",
  }

  exec { "ufw-enable":
    command => "yes | ufw enable",
    unless  => "ufw status | grep \"[S]tatus: active\"",
  }

  service { "ufw":
    ensure    => running,
    enable    => true,
    hasstatus => true,
    subscribe => Package["ufw"],
  }

  firewall::allow { "allow-ssh-from-all":
    port  => 22,
    ip    => "any",
    proto => "tcp",
  }
}

class firewall::snmp (
  $monitorhost,
  )  {
  firewall::allow { "allow-snmp-from-${monitorhost}":
    port  => 161,
    ip    => "any",
    proto => "udp",
    from  => "${monitorhost}",
  }
}

class firewall::http {
  firewall::allow { "allow-http-from-all":
    port  => 80,
    ip    => "any",
    proto => "tcp",
  }
}

class firewall::ldaps {
  firewall::allow { "allow-ldaps-from-all":
    port  => 636,
    ip    => "any",
    proto => "tcp",
  }
  firewall::allow { "allow-ldap-from-all":
    port  => 389,
    ip    => "any",
    proto => "tcp",
  }
}

class firewall::smtp {
  firewall::allow { "allow-smtp-from-all":
    port  => 25,
    ip    => "any",
    proto => "tcp",
  }
}

class firewall::syslog {
  firewall::allow { "allow-syslog-from-all":
    port  => 514,
    ip    => "any",
    proto => "udp",
  }
}

class firewall::syslog_alt {
  firewall::allow { "allow-syslog_alt-from-all":
    port  => 10514,
    ip    => "any",
    proto => "tcp",
  }
}

class firewall::dns {
  firewall::allow { "allow-dns-from-all":
    port  => 53,
    ip    => "any",
    proto => "any",
  }
}


class firewall::https {
  firewall::allow { "allow-https-from-all":
    port  => 443,
    ip    => "any",
    proto => "tcp",
  }
}

class firewall::http_alt {
  firewall::allow { "allow-http_alt-from-all":
    port  => 8080,
    ip    => "any",
    proto => "tcp",
  }
}

class firewall::http_tomcat {
  if $env == "local" or $env == "dev" or $env == "test" {
    # CORE-177: allow websocket connections directly to java
    #   todo: clean this up to be neat
    firewall::allow { "allow-profileserver_tomcat-from-all":
      port  => 8096,
      ip    => "any",
      proto => "tcp",
    }
  }
}

class firewall::munin (
  $monitorhost,
  ) {
  firewall::allow { "allow-munin-from-${monitorhost}":
    port  => 4949,
    ip    => "any",
    proto => "tcp",
    from  => "${monitorhost}",
  }
}

class firewall::opennms {
  firewall::allow { "allow-opennms-from-all":
    port  => 8980,
    ip    => "any",
    proto => "tcp",
  }
}

class firewall {
  include firewall::ufw
  include firewall::http
  include firewall::https
  class{'firewall::munin': monitorhost => $monitorhost}
  class{'firewall::snmp': monitorhost => $monitorhost}
}
