class rsyslog::packages {
  package { "rsyslog-gnutls":
    ensure => "${package_ensure}",
  }
}

define rsyslog::config($rsyslog_clients) {
  file { "/etc/rsyslog.conf":
    owner       => root,
    group       => root,
    mode        => 644,
    content     => template("rsyslog/rsyslog.conf.erb"),
    require     => [
      Class["rsyslog::packages"],
      Exec["rsyslog-ssl-cert"],
    ],
    notify      => Service["rsyslog"],
  }
}

class rsyslog::setup {
  file { "/var/log/rsyslog":
    ensure      => directory,
    owner       => syslog,
    group       => syslog,
    mode        => 755,
    require     => Class["rsyslog::packages"],
    notify      => Service["rsyslog"],
  }
  
  file { "/etc/default/rsyslog":
    ensure      => file,
    owner       => root,
    group       => root,
    mode        => 0644,
    notify      => Service["rsyslog"],
    source      => "puppet://puppet/modules/rsyslog/rsyslog.default",
  }
  
  exec { "rsyslog-ssl-cert":
    user          => root,
    command       => "/usr/sbin/usermod -a -G ssl-cert syslog",
    require       => [
      Class["rsyslog::packages"],
      Package["ssl-cert"]
    ],
    onlyif        => "sh -c '! /usr/bin/groups syslog | grep ssl-cert'",
  }

  # Inspired by: http://wiki.rsyslog.com/index.php/DailyLogRotation
  file { "/etc/cron.d/rsyslog-compress-ex":
    content => "#PUPPET\n@daily root find /var/log/rsyslog -type f -mtime +1 -name '*.log' -exec bzip2 '{}' \\; > /dev/null 2>&1\n";
  }
  # Delete files older than $log_retention_days
  file { "/etc/cron.d/rsyslog-prune-ex":
    content => "#PUPPET\n@daily root find /var/log/rsyslog -type f -mtime +${rsyslog[log_retention_days]} -name '*.log.bz2' -exec rm '{}' \\; > /dev/null 2>&1\n";
  }
}

class rsyslog::services {
  service { "rsyslog":
    ensure  => running,
    enable  => true,
    require => Class["rsyslog::packages"],
  }
}

class rsyslog {
  include rsyslog::packages, rsyslog::setup, rsyslog::hosts, rsyslog::services
}

