class sshd::packages {
  package { ["openssh-server", "openssh-client"]:
    ensure => "${package_ensure}",
  }
}

class sshd::config {
  file { "/etc/ssh/sshd_config":
    owner   => root,
    group   => root,
    mode    => 644,
    # FIXME FIXME FIXME!
    # ${hostname} is a fact. It can be manipulated by the client. $clientcert
    # is safer.
    source  => ["puppet://puppet/modules/sshd/sshd_config.${hostname}", #<--FIXME!
                "puppet://puppet/modules/sshd/sshd_config.${env}",
                "puppet://puppet/modules/sshd/sshd_config"],
    require => Class["sshd::packages", "users"] # require users first, so public key config in place and we can disable passwords
  }

  exec { "reload-sshd":
    user        => root,
    command     => "/sbin/reload ssh",
    subscribe   => File["/etc/ssh/sshd_config"],
    refreshonly => true,
  }
}

class sshd {
  include sshd::packages, sshd::config
}
