class appconf {
  # writes /etc/appconf.{conf,properties} with some basic information about the environment
  
  file { "/etc/appconf.conf":
    content => template("appconf/appconf.conf.erb"),
    owner   => "root",
    group   => "root",
    mode    => 644,
  }

  file { "/etc/appconf.properties":
    content => template("appconf/appconf.properties.erb"),
    owner   => "root",
    group   => "root",
    mode    => 644,
  }
}
