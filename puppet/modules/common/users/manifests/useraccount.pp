define users::useraccount($user, $comment, $uid, $password = "x", $groups = [], $ensure = "present") {
  case $ensure {
    present, disabled: {
      group { "${user}":
        ensure => present,
        gid    => $uid,
      }
      user { "${user}":
        ensure     => $ensure,
        uid        => $uid,
        gid        => $user,
        comment    => $comment,
        password   => $password,
        groups     => $groups,
        require    => [Class["users::groups"], Group[$user]],
        managehome => true,
        shell      => "/bin/bash",
      }
      # http://projects.puppetlabs.com/issues/1099 - managehome is wonky
      file { "/home/${user}":
        ensure  => directory,
        mode    => 0755,
        owner   => $user,
        group   => $user,
        require => User[$user],
      }
      file { "/home/${user}/tmp":
        ensure  => directory,
        mode    => 0755,
        owner   => $user,
        group   => $user,
        require => File["/home/${user}"],
      }
      file { "/home/${user}/.ssh":
        ensure  => directory,
        mode    => 0700,
        owner   => $user,
        group   => $user,
        require => File["/home/${user}"],
      }
      file { "/home/${user}/.ssh/authorized_keys":
        ensure  => file,
        mode    => 0600,
        owner   => $user,
        group   => $user,
        require => File["/home/${user}/.ssh"],
        source  => ["puppet://puppet/modules/users/${user}.authorized_keys.${hostname}",
                    "puppet://puppet/modules/users/${user}.authorized_keys.${env}",
                    "puppet://puppet/modules/users/${user}.authorized_keys",
                    "puppet://puppet/modules/users/fallback.authorized_keys"]
      }

    }
    absent: {
      exec { "disable_user_${user}":
        command => "chmod 000 /home/${user} && usermod -s /sbin/nologin ${user}",
        onlyif  => "id ${user}",
      }
    }
  }
}
