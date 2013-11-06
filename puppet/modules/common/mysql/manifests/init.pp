# fully removing mysql if the setup fails:
#    apt-get remove mysql-client mysql-common mysql-server mysql-client-5.1 \
#        mysql-client-core-5.1 mysql-server-5.1 mysql-server-core-5.1 libmysqlclient16
#    find / -name '*mysql*' | grep -v vim | grep -v local | xargs rm -r
#    rm /etc/my.cnf
#    rm /root/.my.cnf
# you can then edit the puppet config and retry...

class mysql::client::packages {
  # There are situations that only a client is needed.
  package { "mysql-client":
    ensure => "${package_ensure}"
  }
}

class mysql::packages {
  package { "mysql-server":
    ensure => "${package_ensure}"
  }
}

class mysql::config {
  file { "my.cnf":
    name    => "/etc/mysql/conf.d/my.cnf",
    content => template("mysql/my.cnf.erb"),
    owner   => "root",
    group   => "root",
    mode    => 644,
    notify  => Service["mysql"],
    require => Class["mysql::packages"],
  }
}

class mysql::preinstall {
  file { "set-mysql-root-password":
    name    => "/usr/local/sbin/set-mysql-root-password",
    ensure  => file,
    source  => "puppet:///modules/mysql/set-mysql-root-password",
    owner   => "root",
    group   => "root",
    mode    => 555,
  }
  
  file { "clean-mysql-default-grants.sql":
    name   => "/usr/local/etc/clean-mysql-default-grants.sql",
    ensure => file,
    source => "puppet:///modules/mysql/clean-mysql-default-grants.sql",
    owner  => "root",
    group  => "root",
    mode   => 555,
  }
  
  # debian dpkg postinstall already runs mysql_install_db
}

class mysql::services {
  service { "mysql":
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => Class["mysql::packages", "mysql::config", "mysql::preinstall"],
  }
}

class mysql::postinstall {
  # debian dpkg postinstall normally wants to set root password, but if we run it
  #   non-interactively, it shouldn't....which means installing mysql-server from
  #   puppet should work with the below script, but installing from the command
  #   line doesn't.
  exec { "run-set-mysql-root-password":
    subscribe   => Package["mysql-server"],
    refreshonly => true,
    command     => "set-mysql-root-password",
    require     => Class["mysql::preinstall", "mysql::services"],
  }

  exec { "clean-mysql-default-grants":
    subscribe   => File["clean-mysql-default-grants.sql"],
    refreshonly => true,
    command     => "mysql < /usr/local/etc/clean-mysql-default-grants.sql",
    environment => [ "HOME=/root" ],
    require     => Class["mysql::preinstall", "mysql::services"],
  }
}

class mysql::backup {
  package { "automysqlbackup":
    ensure => "${package_ensure}",
  }
  file { "/home/backup01/automysqlbackup":
    ensure => directory,
  }
  file { "/etc/default/automysqlbackup":
    require => [
                File["/home/backup01/automysqlbackup"], 
                Package["automysqlbackup"],
               ],
    ensure  => file,
    content => template("mysql/automysqlbackup.erb"),
  }
  file { "/usr/local/sbin/mysql-backup-post":
    ensure  => file,
    content => template("mysql/mysql-backup-post.erb"),
    owner   => "root",
    group   => "root",
    mode    => 777,
  }
}

class mysql {
  include mysql::packages, mysql::config, mysql::preinstall, mysql::services, mysql::postinstall, mysql::client::packages
  include mysql::backup
}
