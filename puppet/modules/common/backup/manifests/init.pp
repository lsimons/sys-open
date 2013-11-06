class backup::rackspace {
  if $env != "local" {
    $key = $backup[rackspace_api_key]
    $user = $backup[rackspace_api_user]
  
    package { "driveclient":
      ensure      => "${package_ensure}",
      require     => [
        Class["apt::rackspace::backup"],
        Exec["apt-get update"],
      ],
    }
    exec { "init-rackspace-driveclient":
      user        => root,
      command     => "/usr/local/bin/driveclient -c -k '${key}' -u '${user}'",
      # notify      => Service["driveclient"],
      require     => Package["driveclient"],
      onlyif      => "sh -c 'cat /etc/driveclient/bootstrap.json | grep IsRegistered | grep false'"
    }

    service { "driveclient":
      enable  => true,
      ensure  => running,
      require => [
        Package["driveclient"],
        Exec["init-rackspace-driveclient"]
      ]
    }
  }
}

class backup {
  include backup::rackspace
}
