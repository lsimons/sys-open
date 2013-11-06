class ldapdb::appdbs {
  # this makes a database for each app defined in profiles.yml that has a LDAP database configured
  
  file { "update_ldapdbs.sh":
    name    => "/usr/local/sbin/update_ldapdbs.sh",
    content => template("ldapdb/update_ldapdbs.sh.erb"),
    owner   => "root",
    group   => "root",
    mode    => 744,
  }
  
  exec { "update_ldapdbs":
    subscribe   => File["update_ldapdbs.sh"],
    refreshonly => true,
    command     => "update_ldapdbs.sh",
    require     => [File["update_ldapdbs.sh"], Class["slapd"]],
  }
}

class ldapdb {
  include ldapdb::appdbs
}
