class unattendedupgrades::packages {
  package { "unattended-upgrades":
    ensure => "${package_ensure}"
  }
}

class unattendedupgrades::config {
  file { "50unattended-upgrades":
    name    => "/etc/apt/apt.conf.d/50unattended-upgrades",
    content => template("unattendedupgrades/50unattended-upgrades.erb"),
    owner   => "root",
    group   => "root",
    mode    => 644,
    require => Class["unattendedupgrades::packages"],
  }
}

class unattendedupgrades {
  include unattendedupgrades::packages, unattendedupgrades::config
}
