class mail::packages {
  package { "postfix":
    ensure => "${package_ensure}",
  }
  package { "exim4":
    ensure => absent,
  }
  package { "msmtp-mta":
    ensure => absent,
  }
  package { "msmtp":
    ensure => absent,
  }
  package { "mailutils":
    ensure => "${package_ensure}",
  }
  package { "mutt":
    ensure => "${package_ensure}",
  }
}

class mail::service {
  service { "postfix":
    require => Package["postfix"],
    ensure  => running,
  }
}

class mail::mta {
  case $profile {
    "smarthost": {
      include mail::postfix::smarthost
    }
    default: {
      include mail::postfix::client
    }
  }
}

class mail::postfix::client {
  # I'm a postfix that only forward mails to my smarthost!
  $smarthost = $mail[smarthost]

  file { "/etc/postfix/main.cf":
    content     => template("mail/client-main.cf.erb"),
    notify      => Service["postfix"],
    require     => [
      Package["postfix"], 
      Class["pki::host::publish"],
    ]
  }
  # This creates an alias for all root mail. 
  # Applying this on the ${smarthost} will probably be a Bad Thing.
  mailalias { "root":
    ensure      => "present",
    recipient   => "root@${smarthost}",
    target      => "/etc/aliases",
    name        => root,
    require     => File["/etc/postfix/main.cf"],
  }
  exec { 'newaliases':
    subscribe   => Mailalias["root"],
    path        => "/usr/bin",
    cwd         => "/etc",
    refreshonly => true
  }
}


class mail::postfix::smarthost {
  # I am the smarthost for other nodes.
  file { "/etc/postfix/main.cf":
    content => template("mail/main.cf.erb"),
    notify  => Service["postfix"],
    require => [
      Package["postfix"], 
      Class["pki::host::publish"],
    ]
  }
  file { "/etc/postfix/relay_clientcerts":
    source  => "puppet:///modules/mail/relay_clientcerts",
    notify  => Exec["postmap relay_clientcerts"],
    require => [
      Package["postfix"], 
      Class["pki::host::publish"],
    ]
  }
  exec { "postmap relay_clientcerts":
    path => "/usr/sbin", 
    cwd  => "/etc/postfix",
  }

  # This creates aliases for all root mail to go to ops@example.com so we'll actually read it
  mailalias { "root":
    ensure      => "${package_ensure}",
    recipient   => "ops@example.com",
    target      => "/etc/aliases",
    name        => root,
    require     => File["/etc/postfix/main.cf"],
  }
  mailalias { "postmaster":
    ensure      => "${package_ensure}",
    recipient   => "root",
    target      => "/etc/aliases",
    name        => postmaster,
    require     => File["/etc/postfix/main.cf"],
  }
  mailalias { "admin":
    ensure      => "${package_ensure}",
    recipient   => "ops@example.com",
    target      => "/etc/aliases",
    name        => admin,
    require     => File["/etc/postfix/main.cf"],
  }
  exec { 'newaliases':
    subscribe   => [
      Mailalias["root"],
      Mailalias["postmaster"],
      Mailalias["admin"],
    ],
    path        => "/usr/bin",
    cwd         => "/etc",
    refreshonly => true
  }
}

class mail {
  include mail::packages, mail::service, mail::mta
}
