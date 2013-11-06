class davical::packages {

  package { [
    "davical"
  ]:
    ensure => "${package_ensure}",
  }

  include davical::db
}

class davical::db {

  file { "davical_initdb.sh":
    name   => "/usr/local/sbin/davical_initdb.sh",
    content => template("davical/davical_initdb.sh.erb"),
    owner   => "root",
    group   => "root",
    mode    => 744
  }
  
  exec { "davical_initdb":
    subscribe   => File["davical_initdb.sh"],
    refreshonly => true,
    command     => "davical_initdb.sh",
    require     => [File["davical_initdb.sh"], Class["davical::packages"]]
  }
}

class davical {
  include davical::packages
}
