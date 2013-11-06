class appdb::appdbs {
  # this makes a database for each app defined in profiles.yml that has a database configured
  
  file { "update_appdbs.sh":
    name    => "/usr/local/sbin/update_appdbs.sh",
    content => template("appdb/update_appdbs.sh.erb"),
    owner   => "root",
    group   => "root",
    mode    => 744,
  }
  
  file { "update_wwwdbs.sh":
    name    => "/usr/local/sbin/update_wwwdbs.sh",
    ensure  => absent,
  }

  exec { "update_appdbs":
    subscribe   => File["update_appdbs.sh"],
    refreshonly => true,
    command     => "update_appdbs.sh",
    require     => [File["update_appdbs.sh"], Class["postgres"]],
  }
}

class appdb {
  include appdb::appdbs
}
