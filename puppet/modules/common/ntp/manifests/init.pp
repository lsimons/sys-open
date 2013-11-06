class ntp {
  package { "ntp":
    ensure => "${package_ensure}",
  }

  service { "ntp":
    ensure => running,
    enable => true,
    pattern => "/usr/sbin/ntpd",
    require => Package["ntp"],
  }
}
