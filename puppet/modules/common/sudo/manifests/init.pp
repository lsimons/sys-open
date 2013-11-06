class sudo::packages {
  package { "sudo":
    ensure => "${package_ensure}",
  }
}

class sudo::config {
  file { "/etc/sudoers":
    ensure => file,
    content => template("sudo/sudoers.erb"),
    owner  => "root",
    group  => "root",
    mode   => 440,
    require => Class["sudo::packages"],
  }
}


class sudo {
  include sudo::packages, sudo::config
}
