class davfs::packages {
  package { "davfs2":
    ensure => "${package_ensure}",
  }
}

class davfs::configs {
  file { "/etc/davfs2/secrets":
    require => Class["davfs::packages"],
    content => template("davfs/secrets.erb"),
    mode => "0600",
    owner => "root",
    group => "root",
  }
}

define davfs::mount (
  $url,
  $user,
  $pass,
){
  file { "/tmp/${user}":
    require => Class["davfs::packages"],
    content => template("davfs/test.erb"),
  }
  
}

class davfs 
( $mountpoints = {}, )
{
  include davfs::packages
  include davfs::configs
}
