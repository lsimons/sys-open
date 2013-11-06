class users::groups {
  group { "rvm":
    ensure   => "present",
    gid      => 1005,
  }
}

class users::accounts {
  # please keep ordered by user id
  
  users::useraccount { "manage":
    user     => "manage",
    comment  => "general shared admin user",
    password => "$6$doa6Jyqz$81.wkuBbYiznfg1DiXjWLZU39wgDJwz7M1iezhsPD5yZBcriT4yu32RJRFn.FxnADDYILpj9MMbFLCONne9XE1",
    uid      => 1000,
    groups   => "sudo",
  }
  
  if $clientcert == "svc02.lonrs.test.local" {
    users::useraccount { "project1":
      user     => "project1",
      comment  => "Automated account used for the project1 project to sync some files",
      password => "*",
      uid      => 1003,
    }
  } else {
    if $profile == "project1_measurement_service" {
      # different password
      users::useraccount { "project1":
        user     => "project1",
        comment  => "Automated account used for the project1 project",
        password => "*",
        uid      => 1003,
      }
    }
  }
  
  # uid 1005 is rvm in group (see above)
  if $profile == "www" {
    users::useraccount { "hpdemo":
      user     => "hpdemo",
      comment  => "Demo",
      password => "*",
      uid      => 1006,
      groups   => "rvm"
    }

  }
  
  if $profile == "www" {
    users::useraccount { "project4":
      user     => "project4",
      comment  => "project4 Applications",
      password => "*",
      uid      => 1009,
      groups   => "rvm"
    }
  }
  
  if $profile == "wp" {
    users::useraccount { "wp":
      user     => "wp",
      comment  => "Wordpress",
      password => "*",
      uid      => 1009,
    }
  }

  # Used for backups. Should be present on ALL servers.
  users::useraccount { "backup01":
    user     => "backup01",
    comment  => "Backup User for server backup01",
    password => "*",
    uid      => 1014
  }
  
  # Used for apt repositories.
  if $profile == "manage" {
    users::useraccount { "reprepro":
      user     => "reprepro",
      comment  => "Apt repository user",
      password => "*",
      uid      => 1016
    }
  }

  # INFRA-192
  if $profile == "www" {
    users::useraccount { "tools":
      user     => "tools",
      comment  => "Toold",
      password => "*",
      uid      => 1017
    }
  }
  
  if $profile == "www" {
    # INFRA-240
    users::useraccount { "davical":
      user     => "davical",
      comment  => "davical",
      password => "*",
      uid      => 1021
    }
  }

  # INFRA-301
  if $clientcert == "svc11.lonrs.live.example.org" {
    users::useraccount { "cloudbees":
      user     => "cloudbees",
      comment  => "Cloudbees CI",
      password => "*",
      uid      => 1022
    }
  }
  
  if $profile == "www" {
    users::useraccount { "pootle":
      user     => "pootle",
      comment  => "pootle",
      password => "*",
      uid      => 1025
    }
  }
}

class users::profile::path {
  file { "/etc/profile.d/path.sh":
    source => "puppet://puppet/modules/users/path.sh",
    owner  => root,
    group  => root,
  }
}

class users::root::ssh {
  file { "/root/.ssh":
    ensure  => directory,
    mode    => 0700,
    owner   => root,
    group   => root
  }
  file { "/root/.ssh/authorized_keys":
    ensure  => file,
    mode    => 0600,
    owner   => root,
    group   => root,
    require => File["/root/.ssh"],
    # FIXME FIXME FIXME!
    # ${hostname} is a fact. It can be manipulated by the client. $clientcert
    # is safer.
    source  => ["puppet://puppet/modules/users/root.authorized_keys.${hostname}", #<--FIXME!
                "puppet://puppet/modules/users/root.authorized_keys.${env}",
                "puppet://puppet/modules/users/root.authorized_keys",
                "puppet://puppet/modules/users/fallback.authorized_keys"]
  }
}

class users {
  include users::groups, users::accounts, users::profile::path, users::root::ssh
}
