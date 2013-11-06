Exec {
  path => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
}

Package {
# This makes sure that every time you call a package resource, it happens
# *after* apt-get update has been run.
# Placing this here makes it so you do not have to place it at every Package.
  require => Class["basepackages::aptupdate"],
}
