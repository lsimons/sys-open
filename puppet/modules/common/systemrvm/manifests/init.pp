class systemrvm::dependencies {
  include apache::packages
  
  if ! defined(Package['build-essential'])      { package { 'build-essential':      ensure => "${package_ensure}" } }
  if ! defined(Package['bison'])                { package { 'bison':                ensure => "${package_ensure}" } }
  if ! defined(Package['openssl'])              { package { 'openssl':              ensure => "${package_ensure}" } }
  if ! defined(Package['libreadline6'])         { package { 'libreadline6':         ensure => "${package_ensure}" } }
  if ! defined(Package['libreadline6-dev'])     { package { 'libreadline6-dev':     ensure => "${package_ensure}" } }
  if ! defined(Package['curl'])                 { package { 'curl':                 ensure => "${package_ensure}" } }
  if ! defined(Package['git-core'])             { package { 'git-core':             ensure => "${package_ensure}" } }
  if ! defined(Package['zlib1g'])               { package { 'zlib1g':               ensure => "${package_ensure}" } }
  if ! defined(Package['zlib1g-dev'])           { package { 'zlib1g-dev':           ensure => "${package_ensure}" } }
  if ! defined(Package['libssl-dev'])           { package { 'libssl-dev':           ensure => "${package_ensure}" } }
  if ! defined(Package['libyaml-dev'])          { package { 'libyaml-dev':          ensure => "${package_ensure}" } }
  if ! defined(Package['libsqlite3-0'])         { package { 'libsqlite3-0':         ensure => "${package_ensure}" } }
  if ! defined(Package['libsqlite3-dev'])       { package { 'libsqlite3-dev':       ensure => "${package_ensure}" } }
  if ! defined(Package['sqlite3'])              { package { 'sqlite3':              ensure => "${package_ensure}" } }
  if ! defined(Package['libxml2-dev'])          { package { 'libxml2-dev':          ensure => "${package_ensure}" } }
  if ! defined(Package['libxslt1-dev'])         { package { 'libxslt1-dev':         ensure => "${package_ensure}", alias => 'libxslt-dev' } }
  if ! defined(Package['autoconf'])             { package { 'autoconf':             ensure => "${package_ensure}" } }
  if ! defined(Package['libc6-dev'])            { package { 'libc6-dev':            ensure => "${package_ensure}" } }

  # for passenger
  if ! defined(Package['apache2-prefork-dev'])  { package { 'apache2-prefork-dev':  ensure => "${package_ensure}" } }
  if ! defined(Package['libapr1-dev'])          { package { 'libapr1-dev':          ensure => "${package_ensure}", alias => 'libapr-dev' } }
  if ! defined(Package['libaprutil1-dev'])      { package { 'libaprutil1-dev':      ensure => "${package_ensure}", alias => 'libaprutil-dev' } }
  if ! defined(Package['libcurl4-openssl-dev']) { package { 'libcurl4-openssl-dev': ensure => "${package_ensure}" } }
  
  # for rails
  case $operatingsystemrelease {
    10.04: {
      if ! defined(Package['libv8-2.0.3'])          { package { 'libv8-2.0.3':          ensure => "${package_ensure}" } }
    }
  }
}

class systemrvm::install {
  $ruby_version = "${systemrvm[ruby_version]}"
  $passenger_version = "${systemrvm[passenger_version]}"

  $maxpoolsize = "${systemrvm[passenger_maxpoolsize]}"
  $poolidletime = "${systemrvm[passenger_poolidletime]}"
  $mininstances = "${systemrvm[passenger_mininstances]}"
  $maxinstancesperapp = "${systemrvm[passenger_maxinstancesperapp]}"
  $spawnmethod = "${systemrvm[passenger_spawnmethod]}"

  $rvm_installer_url = "https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer"
  $rvm_version = "${package_ensure}"
  $rvm_path = "/usr/local/rvm"
  $rvm_bin_path = "${rvm_path}/bin"
  $rvm_man_path = "${rvm_path}/man"
  $rvm_cmd = "${rvm_bin_path}/rvm"
  $rvm_exec = "${rvm_cmd} ruby-${ruby_version} exec"
  $ruby_cmd = "$rvm_path/wrappers/ruby-${ruby_version}/ruby"
  $rvm_gem_path = "${rvm_path}/gems/ruby-${ruby_version}/gems"
  $rvm_passenger_gem_path = "${rvm_gem_path}/passenger-${passenger_version}"
  $rvm_passenger_apache_module = "${rvm_passenger_gem_path}/ext/apache2/mod_passenger.so"
  
  exec { 'install-rvm':
    command => "bash -c '/usr/bin/curl -s ${rvm_installer_url} -o /tmp/rvm-installer ; \
                chmod +x /tmp/rvm-installer ; \
                rvm_bin_path=$rvm_bin_path rvm_man_path=$rvm_man_path /tmp/rvm-installer --version ${rvm_version} ; \
                rm /tmp/rvm-installer'",
    creates => '/usr/local/rvm/bin/rvm',
    require => Class['systemrvm::dependencies'],
  }
  
  exec { "install-rvm-ruby":
    command => "${rvm_cmd} install ruby-${ruby_version}",
    unless  => "${rvm_cmd} list strings | grep ruby-${ruby_version}",
    timeout => 1200,
    require => Exec["install-rvm"],
  }

  exec { "install-passenger-gem":
    command => "${rvm_exec} gem install passenger --version ${passenger_version}",
    unless => "${rvm_exec} gem list -l | grep passenger | grep ${passenger_version}",
    timeout => 600,
    require => [Exec["install-rvm-ruby"], Class["apache"]],
  }
  
  exec { "install-passenger-apache2-module":
    command => "${rvm_exec} passenger-install-apache2-module -a",
    creates => "$rvm_passenger_apache_module",
    timeout => 600,
    require => Exec["install-passenger-gem"],
  }

  file {
    '/etc/apache2/mods-available/passenger.load':
      ensure  => file,
      content => "LoadModule passenger_module $rvm_passenger_apache_module",
      require => Exec['install-passenger-apache2-module'],
      notify => Service["apache2"];

    '/etc/apache2/mods-available/passenger.conf':
      ensure  => file,
      content => template('systemrvm/passenger-apache.conf.erb'),
      require => Exec['install-passenger-apache2-module'],
      notify => Service["apache2"];

    '/etc/apache2/mods-enabled/passenger.load':
      ensure  => 'link',
      target  => '../mods-available/passenger.load',
      require => Exec['install-passenger-apache2-module'],
      notify => Service["apache2"];

    '/etc/apache2/mods-enabled/passenger.conf':
      ensure  => 'link',
      target  => '../mods-available/passenger.conf',
      require => Exec['install-passenger-apache2-module'],
      notify => Service["apache2"];
  }
}

class systemrvm {
  include systemrvm::dependencies, systemrvm::install
}
