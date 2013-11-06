class wsgi::packages {
  package { ["libapache2-mod-wsgi"]:
    ensure => "${package_ensure}",
    require => Class["apache::packages"],
  }
}

class wsgi {
	include wsgi::packages
}
