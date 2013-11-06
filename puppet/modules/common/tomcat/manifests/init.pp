class tomcat::packages {
  package { "tomcat7":
    ensure      => "${package_ensure}",
    require     => [
      Class["java"],
      Package["ssl-cert"],
      Class["apt::tomcat::backports"]
    ],
  }
}

class tomcat::config {
  exec { "tomcat-ssl-cert":
    user          => root,
    command       => "/usr/sbin/usermod -a -G ssl-cert,syslog tomcat7",
    require       => [
      Class["tomcat::packages"],
      Package["ssl-cert"]
    ],
    onlyif        => "sh -c '! /usr/bin/groups tomcat7 | grep ssl-cert'",
  }

  file { "/etc/tomcat7/server.xml":
    owner       => root,
    group       => tomcat7,
    mode        => 644,
    content     => template("tomcat/server.xml.erb"),
    require     => [
      Class["tomcat::packages"],
      Class["pki::host::publish"],
      Exec["tomcat-ssl-cert"],
    ],
    notify      => Service["tomcat7"],
  }
  
  file { "/etc/tomcat7/tomcat-users.xml":
    ensure      => file,
    owner       => root,
    group       => tomcat7,
    mode        => 640,
    source      => "puppet://puppet/modules/tomcat/tomcat-users.xml",
    require     => Class["tomcat::packages"],
    notify      => Service["tomcat7"],
  }

  # no need to mention we are tomcat
  file { "/var/lib/tomcat7/webapps/ROOT/index.html":
    ensure      => file,
    owner       => root,
    group       => root,
    mode        => 644,
    source      => "puppet://puppet/modules/tomcat/index.html",
    require     => Class["tomcat::packages"],
  }

  # INFRA-160: configure preferences subsystem
  file { "/var/lib/tomcat7/prefs":
    ensure      => directory,
    owner       => tomcat7,
    group       => tomcat7,
    mode        => 775,
    require     => Class["tomcat::packages"],
  }
  file { "/var/lib/tomcat7/prefs/user":
    ensure      => directory,
    owner       => tomcat7,
    group       => tomcat7,
    mode        => 775,
    require     => File["/var/lib/tomcat7/prefs"],
  }
  file { "/var/lib/tomcat7/prefs/user/.java":
    ensure      => directory,
    owner       => tomcat7,
    group       => tomcat7,
    mode        => 775,
    require     => File["/var/lib/tomcat7/prefs/user"],
  }
  file { "/var/lib/tomcat7/prefs/user/.java/.userPrefs":
    ensure      => directory,
    owner       => tomcat7,
    group       => tomcat7,
    mode        => 775,
    require     => File["/var/lib/tomcat7/prefs/user/.java"],
  }
  file { "/var/lib/tomcat7/prefs/user/.userPrefs":
    ensure      => directory,
    owner       => tomcat7,
    group       => tomcat7,
    mode        => 775,
    require     => File["/var/lib/tomcat7/prefs/user"],
  }
  file { "/var/lib/tomcat7/prefs/system":
    ensure      => directory,
    owner       => tomcat7,
    group       => tomcat7,
    mode        => 775,
    require     => File["/var/lib/tomcat7/prefs"],
  }
  file { "/var/lib/tomcat7/prefs/system/.java":
    ensure      => directory,
    owner       => tomcat7,
    group       => tomcat7,
    mode        => 775,
    require     => File["/var/lib/tomcat7/prefs/system"],
  }
  file { "/var/lib/tomcat7/prefs/system/.java/.systemPrefs":
    ensure      => directory,
    owner       => tomcat7,
    group       => tomcat7,
    mode        => 775,
    require     => File["/var/lib/tomcat7/prefs/system/.java"],
  }
  file { "/var/lib/tomcat7/prefs/system/.systemPrefs":
    ensure      => directory,
    owner       => tomcat7,
    group       => tomcat7,
    mode        => 775,
    require     => File["/var/lib/tomcat7/prefs/system"],
  }
  
  # INFRA-214: ssl cert for client connections
  file { "/etc/default/tomcat7":
    owner       => root,
    group       => root,
    mode        => 644,
    content     => template("tomcat/tomcat-default.erb"),
    require     => [
      Class["tomcat::packages"],
      Class["pki::host::publish"],
      Exec["tomcat-ssl-cert"],
    ],
    notify      => Service["tomcat7"],
  }
}

class tomcat::config::logging {
  # logging customizations. Simple, right? Ugh.
  # http://tomcat.apache.org/tomcat-7.0-doc/logging.html
  
  # install custom jar files into tomcat that control its logging behavior
  package { "liblog4j1.2-java":
    ensure      => "${package_ensure}",
    require     => Class["java"],
  }
  
  file { "/usr/share/tomcat7/lib/log4j-1.2.jar":
    ensure      => link,
    owner       => root,
    group       => root,
    mode        => 644,
    target      => "/usr/share/java/log4j-1.2.jar",
    require     => [Class["tomcat::packages"], Package["liblog4j1.2-java"]],
  }

  file { "/usr/share/java/tomcat-juli-adapters-7.0.33.jar":
    ensure      => file,
    owner       => root,
    group       => root,
    mode        => 644,
    source      => "puppet://puppet/modules/tomcat/tomcat-juli-adapters-7.0.33.jar",
    require     => Class["tomcat::packages"],
  }

  file { "/usr/share/java/tomcat-juli-adapters.jar":
    ensure      => link,
    owner       => root,
    group       => root,
    mode        => 644,
    target      => "/usr/share/java/log4j-1.2.jar",
    require     => File["/usr/share/java/tomcat-juli-adapters-7.0.33.jar"],
  }

  file { "/usr/share/tomcat7/lib/tomcat-juli-adapters.jar":
    ensure      => link,
    owner       => root,
    group       => root,
    mode        => 644,
    target      => "/usr/share/java/tomcat-juli-adapters-7.0.33.jar",
    require     => File["/usr/share/java/tomcat-juli-adapters-7.0.33.jar"],
  }

  file { "/usr/share/java/tomcat-juli-full-7.0.33.jar":
    ensure      => file,
    owner       => root,
    group       => root,
    mode        => 644,
    source      => "puppet://puppet/modules/tomcat/tomcat-juli-full-7.0.33.jar",
    require     => Class["tomcat::packages"],
  }

  file { "/usr/share/java/tomcat-juli-full.jar":
    ensure      => link,
    owner       => root,
    group       => root,
    mode        => 644,
    target      => "/usr/share/java/tomcat-juli-full-7.0.33.jar",
    require     => File["/usr/share/java/tomcat-juli-full-7.0.33.jar"],
  }

  # this is what flips tomcat over to the new logging setup, so above must
  # be in place before we do it
  file { "/usr/share/tomcat7/bin/tomcat-juli.jar":
    ensure      => link,
    owner       => root,
    group       => root,
    mode        => 644,
    target      => "/usr/share/java/tomcat-juli-full-7.0.33.jar",
    require     => [
      File["/usr/share/java/tomcat-juli-full-7.0.33.jar"],
      File["/usr/share/tomcat7/lib/log4j-1.2.jar"],
      File["/usr/share/tomcat7/lib/tomcat-juli-adapters.jar"],
    ],
  }

  # redirect tomcat logging (and unconfigured log4j logging) to syslog
  file { "/usr/share/tomcat7/lib/log4j.properties":
    owner       => root,
    group       => tomcat7,
    mode        => 644,
    content     => template("tomcat/log4j.properties.erb"),
    require     => [
      Class["tomcat::packages"],
      File["/usr/share/tomcat7/bin/tomcat-juli.jar"],
    ],
    notify      => Service["tomcat7"],
  }
  
  # we're keeping this, so that any apps that use j.u.l. do get
  #   some amount of default configuration
  # file { "/etc/tomcat7/logging.properties":
  #  ensure      => absent,
  # }
  file { "/etc/tomcat7/logging.properties":
    owner       => root,
    group       => tomcat7,
    mode        => 644,
    content     => template("tomcat/logging.properties.erb"),
    require     => Class["tomcat::packages"],
    notify      => Service["tomcat7"],
  }
  
  # redirecting stdout to syslog via this custom shell script
  file { "/usr/share/tomcat7/bin/catalina.sh":
    ensure      => file,
    owner       => root,
    group       => root,
    mode        => 755,
    source      => "puppet://puppet/modules/tomcat/catalina.syslog.sh",
    require     => Class["tomcat::packages"],
    notify      => Service["tomcat7"],
  }

  # to restore to 'standard logging':
  #    (and change the rest of the files back to 'absent')
  #
  # file { "/usr/share/tomcat7/bin/tomcat-juli.jar":
  #   ensure      => link,
  #   owner       => root,
  #   group       => root,
  #   mode        => 644,
  #   target      => "/usr/share/java/tomcat-juli.jar",
  # }
  #
  # file { "/etc/tomcat7/logging.properties":
  #   owner       => root,
  #   group       => tomcat7,
  #   mode        => 644,
  #   source      => "puppet://puppet/modules/tomcat/logging.dist.properties",
  #   require     => Class["tomcat::packages"],
  #   notify      => Service["tomcat7"],
  # }
  #
  # file { "/usr/share/tomcat7/bin/catalina.sh":
  #   ensure      => file,
  #   owner       => root,
  #   group       => root,
  #   mode        => 755,
  #   source      => "puppet://puppet/modules/tomcat/catalina.dist.sh",
  #   require     => Class["tomcat::packages"],
  #   notify      => Service["tomcat7"],
  # }
}

class tomcat::services {
  service { "tomcat7":
    ensure  => running,
    enable  => true,
    require => Class["tomcat::packages", "tomcat::config"],
  }

  # INFRA-170: restart apache to make sure it picks up the new crl
  if $tomcat[https_active] == 1 {
    cron { "tomcat-restart-for-crl":
      command => "/etc/init.d/tomcat7 restart >/dev/null",
      user    => root,
      hour    => 02,
      minute  => 12,
    }
  } else {
    cron { "tomcat-restart-for-crl":
      command => "/etc/init.d/tomcat7 restart >/dev/null",
      ensure  => "absent",
      user    => root,
      hour    => 02,
      minute  => 12,
    }
  }
}

class tomcat {
  include tomcat::packages, tomcat::config, tomcat::config::logging, tomcat::services
}
