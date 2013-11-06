##################################################
### Packages
##################################################

class pki::packages {
  # the main packages we care about
  package { ["gnutls-bin", "openssl"]:
    ensure => "${package_ensure}",
  }
  # set ensure => (present|latest) on the many libraries that we use for various crypto things
  # this is defined in the apt module to avoid a dependency cycle
  #   if ! defined(Package['gnupg']) { package { 'gnupg': ensure => "${package_ensure}" } }
  if ! defined(Package['gpgv']) { package { 'gpgv': ensure => "${package_ensure}" } }
  if ! defined(Package['libgnutls26']) { package { 'libgnutls26': ensure => "${package_ensure}" } }
  if ! defined(Package['libgpg-error0']) { package { 'libgpg-error0': ensure => "${package_ensure}" } }
  if ! defined(Package['libgpgme11']) { package { 'libgpgme11': ensure => "${package_ensure}" } }
  if ! defined(Package['libgsasl7']) { package { 'libgsasl7': ensure => "${package_ensure}" } }
  if ! defined(Package['libgssapi-krb5-2']) { package { 'libgssapi-krb5-2': ensure => "${package_ensure}" } }
  if ! defined(Package['libgssapi3-heimdal']) { package { 'libgssapi3-heimdal': ensure => "${package_ensure}" } }
  if ! defined(Package['libasn1-8-heimdal']) { package { 'libasn1-8-heimdal': ensure => "${package_ensure}" } }
  if ! defined(Package['libhcrypto4-heimdal']) { package { 'libhcrypto4-heimdal': ensure => "${package_ensure}" } }
  if ! defined(Package['libheimbase1-heimdal']) { package { 'libheimbase1-heimdal': ensure => "${package_ensure}" } }
  if ! defined(Package['libheimntlm0-heimdal']) { package { 'libheimntlm0-heimdal': ensure => "${package_ensure}" } }
  if ! defined(Package['libhx509-5-heimdal']) { package { 'libhx509-5-heimdal': ensure => "${package_ensure}" } }
  if ! defined(Package['libk5crypto3']) { package { 'libk5crypto3': ensure => "${package_ensure}" } }
  if ! defined(Package['libkrb5-26-heimdal']) { package { 'libkrb5-26-heimdal': ensure => "${package_ensure}" } }
  if ! defined(Package['libkrb5-3']) { package { 'libkrb5-3': ensure => "${package_ensure}" } }
  if ! defined(Package['libkrb5support0']) { package { 'libkrb5support0': ensure => "${package_ensure}" } }
  if ! defined(Package['libnspr4']) { package { 'libnspr4': ensure => "${package_ensure}" } }
  if ! defined(Package['libnss3']) { package { 'libnss3': ensure => "${package_ensure}" } }
  if ! defined(Package['libnss3-1d']) { package { 'libnss3-1d': ensure => "${package_ensure}" } }
  if ! defined(Package['libroken18-heimdal']) { package { 'libroken18-heimdal': ensure => "${package_ensure}" } }
  if ! defined(Package['libss2']) { package { 'libss2': ensure => "${package_ensure}" } }
  if ! defined(Package['libssl1.0.0']) { package { 'libssl1.0.0': ensure => "${package_ensure}" } }
  if ! defined(Package['libstdc++6']) { package { 'libstdc++6': ensure => "${package_ensure}" } }
}

class pki::host::packages {
  package { ["ca-certificates", "ca-certificates-java", "ssl-cert"]:
    ensure => "${package_ensure}",
  }
}

##################################################
### Utility / setup
##################################################

class pki::fixperms {
  # bulk-fixes the permissions on all generated CA files
  $ca_folder     = $pki[ca_folder]

  exec { "pki::fixperms::chown":
    command     => "chown -R puppet:puppet ${ca_folder}",
    refreshonly => true,
    notify      => Exec["pki::fixperms::chmod"],
  }
  exec { "pki::fixperms::chmod":
    command     => "find ${ca_folder} -type f | xargs chmod 0600",
    refreshonly => true,
    notify      => Exec["pki::fixperms::chmod::dirs"],
  }
  exec { "pki::fixperms::chmod::dirs":
    command     => "find ${ca_folder} -type d | xargs chmod 0700",
    refreshonly => true,
  }
}

class pki::config {
  # ensures $ca_folder exists
  $ca_folder     = $pki[ca_folder]

  exec { "mkdir -p ${ca_folder}": 
    # Crazy puppet still cannot and will not create subfolders if parentfolder
    # does not exist. 
    creates => $ca_folder,
  }
  file { $ca_folder:
    ensure  => directory,
    recurse => true,
    owner   => "puppet", 
    group   => "puppet",
    mode    => 0600,
    require => [
      Exec["mkdir -p ${ca_folder}"],
      Class["pki::packages"],
    ],
  }
}

##################################################
### The Certificate Authority
##################################################

class pki::ca::setup {
  # Initialize a certificate authority on the puppet master
  $ca_folder = $pki::config::ca_folder
  $ca_key    = "${ca_folder}/ca-key.pem"
  $ca_cert   = "${ca_folder}/ca.pem"
  $ca_keystore = "${ca_folder}/ca.jks"
  $tmpl      = "${ca_folder}/certtool.cfg"
  
  # Creates a template configuration for certtool for setting up the CA
  file { "${tmpl}":
    ensure  => file,
    owner   => "puppet", 
    group   => "puppet", 
    mode    => 0600,
    content => template("pki/ca_template.cfg.erb"),
    require => Class["pki::config"],
  }

  # Creates a private key for use by the CA
  exec { "ca-key.pem":
    command => "certtool --generate-privkey --outfile ${ca_key} --bits 2048",
    cwd     => "$ca_folder",
    creates => "${ca_key}",
    require => File["${tmpl}"],
  }
  file { "${ca_key}":
    ensure  => file,
    owner   => "puppet", 
    group   => "puppet", 
    mode    => 0600,
    require => Exec["ca-key.pem"],
  }

  # Creates a self signed certificate using self generated private key.
  exec { "ca.pem":
    command => "certtool --generate-self-signed --load-privkey ${ca_key} --outfile ${ca_cert} --template ${tmpl}",
    cwd     => "$ca_folder",
    creates => "${ca_cert}",
    require => File["${ca_key}"],
  }
  file { "${ca_cert}":
    ensure  => file,
    owner   => "puppet", 
    group   => "puppet", 
    mode    => 0600,
    require => Exec["ca.pem"],
    before  => [
      Class["pki::hosts", "pki::services"],
      File["/usr/share/ca-certificates/local/ca.pem"],
    ],
  }
  
  # Check that the generate certificate is valid
  exec { "verify-ca.pem":
    command     => "bash -c \"openssl verify -CAfile ${ca_cert} ${ca_cert} | grep error\"",
    cwd         => "$ca_folder",
    returns     => 1,
    require     => Package["openssl"],
    subscribe   => Exec["ca.pem"],
    refreshonly => true,
  }
  
  # Create a java truststore from the ca cert
  exec { "ca_keystore":
    command => "keytool -importcert -noprompt -alias ${fqdn} -file ${ca_cert} -keystore ${ca_keystore} -storepass changeit",
    cwd     => "${ca_folder}",
    creates => "${ca_keystore}",
    require => [
      Exec["ca.pem"],
      Class["java"]
    ],
  }
  file { "${ca_keystore}":
    ensure  => file,
    owner   => "puppet", 
    group   => "puppet", 
    mode    => 0600,
    require => Exec["ca_keystore"],
    before  => [
      Class["pki::hosts", "pki::services"],
      File["/usr/share/ca-certificates/local/ca.jks"],
    ],
  }
}

class pki::ca::revocations {
  # Revocation support for the pki::ca
  $ca_folder        = $pki::config::ca_folder
  $ca_key           = "${ca_folder}/ca-key.pem"
  $ca_cert          = "${ca_folder}/ca.pem"
  $crl              = "${ca_folder}/crl.pem"
  $revoked_combined = "${ca_folder}/revoked_certs.pem"
  $tmpl             = "${ca_folder}/crl_template.cfg"

  # Creates a template configuration for certtool for generating CRLs
  file { "${tmpl}":
    ensure      => file,
    owner       => "puppet", 
    group       => "puppet", 
    mode        => 0600,
    content     => template("pki/crl_template.cfg.erb"),
    require     => Class["pki::config"],
  }
  
  # Concatenate all revoked certs into a single file.
  exec { "pki::ca::revocations::combined":
    command     => "cat ${ca_folder}/*/*_cert.pem.revoked > ${revoked_combined}",
    cwd         => "$ca_folder",
    refreshonly => true,
    notify      => Exec["pki::ca::revocations::crl"],
    require     => [
      Class["pki::config"],
      File["${tmpl}"],
    ]
  }
  file { "${revoked_combined}":
    ensure  => file,
    owner   => "puppet", 
    group   => "puppet", 
    mode    => 0600,
    require => Exec["pki::ca::revocations::combined"],
  }
  
  # Updates CRL from all combined revoked files, iff there are any revoked certs
  exec { "pki::ca::revocations::crl":
    command => "certtool --template ${tmpl} --generate-crl --load-ca-privkey ${ca_key} --load-ca-certificate ${ca_cert} --load-certificate ${revoked_combined} > ${crl}",
    cwd     => "$ca_folder",
    # since the CRL contains a timestamp, it has to be regenerated periodically
    # onlyif  => "test -s ${revoked_combined}",
    require => [
      Exec["pki::ca::revocations::combined"],
      File["${revoked_combined}"],
      Class["pki::ca::setup"],
    ],
    before  => [
      File["/usr/share/ca-certificates/local/crl.pem"],
    ],
    # refreshonly => true,
  }

  # Creates empty CRL from all combined revoked files, iff there are no revoked certs
  exec { "pki::ca::revocations::crl::empty":
    command => "certtool --template ${tmpl} --generate-crl --load-ca-privkey ${ca_key} --load-ca-certificate ${ca_cert} > ${crl}",
    cwd     => "$ca_folder",
    onlyif  => "test ! -s ${revoked_combined}",
    require => [
      Exec["pki::ca::revocations::combined"],
      File["${revoked_combined}"],
      Class["pki::ca::setup"],
    ],
    before  => [
      File["/usr/share/ca-certificates/local/crl.pem"],
    ],
  }
}

##################################################
### Issuing certs
##################################################

define pki::cert ($fqdn, $serial) {
  # Use the CA to generate and sign new certificates
  $basedir  = "${pki::config::ca_folder}"
  $certdir  = "${pki::config::ca_folder}/${fqdn}"
  $tmpl     = "${certdir}/${fqdn}_host_template.cfg"
  $key      = "${certdir}/${fqdn}_key.pem"
  $csr      = "${certdir}/${fqdn}_request.pem"
  $cert     = "${certdir}/${fqdn}_cert.pem"
  $combined = "${certdir}/${fqdn}.pem"
  $p12      = "${certdir}/${fqdn}.p12"
  $keystore = "${certdir}/${fqdn}.jks"
  $md5      = "${certdir}/${fqdn}_cert.md5"
  $ca       = "${basedir}/ca.pem"
  $ca_key   = "${basedir}/ca-key.pem"
  
  # 0) Create a folder for holding the cert
  file { "$certdir":
    ensure  => directory,
    owner   => "puppet", 
    group   => "puppet",
    mode    => 0700,
    require => [
      File["${basedir}"],
    ],
  }

  # 1) Create a template configuration for certtool for creating host certs
  file { "$tmpl":
    ensure  => file,
    require => [
      Class["pki::config"],
      File["${certdir}"],
    ],
    content => template("pki/host_template.cfg.erb"),
  }

  # 2) Create a private key for a host cert
  exec { "pki::cert::privkey::${fqdn}":
    command => "certtool --generate-privkey --outfile ${key} --bits 2048",
    cwd     => "${basedir}",
    creates => "${key}",
    require => [
      Class["pki::config"], 
      File["${certdir}"],
    ],
  }

  # 3) Create a certificate signing request for a host cert
  exec { "pki::cert::request::${fqdn}":
    command => "certtool --generate-request --load-privkey ${key} --outfile ${csr} --template ${tmpl}",
    cwd     => "${basedir}",
    creates => "${csr}",
    require => [
      File["${tmpl}"],
      Exec["pki::cert::privkey::${fqdn}"],
    ],
  }

  # 4) Process a certificate signing request to generate a host cert
  exec { "pki::cert::cert::${fqdn}":
    command => "certtool --generate-certificate --load-request ${csr} --outfile ${cert} --load-ca-certificate ${ca} --load-ca-privkey ${ca_key} --template ${tmpl}",
    cwd     => "${basedir}",
    creates => "${cert}",
    require => [
      Exec["pki::cert::request::${fqdn}"],
      Class["pki::ca::setup"],
    ],
  }
  
  # Check that the generate certificate is valid
  exec { "pki::cert::verify::${fqdn}":
    command     => "bash -c \"openssl verify -CAfile ${ca} ${cert} | grep error\"",
    cwd         => "${basedir}",
    returns     => 1,
    require     => Package["openssl"],
    subscribe   => Exec["pki::cert::cert::${fqdn}"],
    refreshonly => true,
  }

  # 5) Combine cert and key into one file
  exec { "pki::cert::combined::${fqdn}":
    command => "cat ${cert} ${key} > ${combined}",
    cwd     => "${basedir}",
    creates => "${combined}",
    require => [
      Exec["pki::cert::cert::${fqdn}"],
    ],
  }

  # 6) Create a .p12 from the cert and key (for importing into keytool)
  exec { "pki::cert::p12::${fqdn}":
    command => "openssl pkcs12 -export -in ${cert} -inkey ${key} -out ${p12} -name ${fqdn} -CAfile ${ca} -caname local -passout pass:changeit",
    cwd     => "${basedir}",
    creates => "${p12}",
    require => [
      Exec["pki::cert::cert::${fqdn}"],
    ],
  }

  # 7) Create a java keystore from the cert
  exec { "pki::cert::jks::${fqdn}":
    command => "keytool -importkeystore -noprompt -deststorepass changeit -destkeypass changeit -destkeystore ${keystore} -srckeystore ${p12} -srcstoretype PKCS12 -srcstorepass changeit -alias ${fqdn}",
    cwd     => "${basedir}",
    creates => "${keystore}",
    notify  => Exec["pki::fixperms::chown"],
    require => [
      Exec["pki::cert::p12::${fqdn}"],
      Class["java"]
    ],
  }

  # 8) Create an md5 fingerprint file from the cert; notify
  exec { "pki::cert::md5::${fqdn}":
    command => "echo `openssl x509 -md5 -fingerprint -in ${cert} -noout  | cut -d '=' -f 2` ${fqdn} > ${md5}",
    cwd     => "${basedir}",
    creates => "${md5}",
    notify  => [
      Exec["pki::fixperms::chown"],
      Exec["pki::md5::concat::postfix"],
    ],
    before  => [
      Exec["pki::fixperms::chown"],
      Exec["pki::md5::concat::postfix"],
    ],
    require => [
      Exec["pki::cert::cert::${fqdn}"],
    ]
  }
}

class pki::postfix::clientcerts {
  # Combine all md5 fingerprints into one file for postfix to use

  $ca_folder           = "${pki::config::ca_folder}"
  $postfix_clientcerts = $pki[postfix_clientcerts]

  exec { "pki::md5::concat::postfix":
    command     => "cat ${ca_folder}/*/*_cert.md5 > ${postfix_clientcerts}",
    cwd         => "$ca_folder",
    refreshonly => true,
  }
}

##################################################
### host certs on the target machines
##################################################
# A host certificate is associated with a specific machine. No
# two machines should share a host certificate.

class pki::host::publish {
  # Publish machine certificate files to the server
  include pki::host::packages
  
  file { "/usr/share/ca-certificates/local":
    ensure      => directory,
    owner       => "root", 
    group       => "root",
    mode        => 0755,
  }
  file { "/usr/share/ca-certificates/local/ca.pem":
    ensure      => file,
    source      => "puppet://puppet/modules/pki/ca.pem",
    owner       => "root", 
    group       => "root",
    mode        => 0644,
    require     => File["/usr/share/ca-certificates/local"],
  }
  file { "/usr/share/ca-certificates/local/ca.jks":
    ensure      => file,
    source      => "puppet://puppet/modules/pki/ca.jks",
    owner       => "root", 
    group       => "root",
    mode        => 0644,
    require     => File["/usr/share/ca-certificates/local"],
  }
  file { "/usr/local/share/ca-certificates/local_ca.crt":
    ensure      => link,
    target      => "/usr/share/ca-certificates/local/ca.pem",
    owner       => "root", 
    group       => "root",
    mode        => 0644,
    require     => [
      File["/usr/share/ca-certificates/local/ca.pem"],
      Package["ca-certificates", "ca-certificates-java"]
    ],
  }
  exec { "update-ca-certificates":
    command     => "/usr/sbin/update-ca-certificates",
    refreshonly => true,
    subscribe   => File["/usr/local/share/ca-certificates/local_ca.crt"],
    require     => File["/usr/local/share/ca-certificates/local_ca.crt"],
  }
  file { "/usr/share/ca-certificates/local/crl.pem":
    ensure      => file,
    source      => "puppet://puppet/modules/pki/crl.pem",
    owner       => "root", 
    group       => "root",
    mode        => 0644,
    require     => [
      File["/usr/share/ca-certificates/local"],
    ],
  }
  
  file { "/etc/ssl/cert":
    ensure      => directory,
    owner       => "root", 
    group       => "root",
    mode        => 0755,
  }
  
  # use of ${clientcert} in the below is critical because it is not a fact:
  #   this ensures a messed-up client is not requesting certs that do not
  #   belong to it
  
  file { "/etc/ssl/${clientcert}_cert.pem":
    ensure     => file,
    source     => "puppet://puppet/modules/pki/${clientcert}/${clientcert}_cert.pem",
    owner      => "root", 
    group      => "syslog", # _no_ idea why syslog insists on this
    mode       => 0644,
    require    => Package["ssl-cert"],
  }
  file { "/etc/ssl/${clientcert}_key.pem":
    ensure     => file,
    owner      => "root", 
    group      => "syslog", # _no_ idea why syslog insists on this
    mode       => 0640,
    source     => "puppet://puppet/modules/pki/${clientcert}/${clientcert}_key.pem",
    require    => Package["ssl-cert"],
  }
  file { "/etc/ssl/${clientcert}.pem":
    ensure     => file,
    owner      => "root", 
    group      => "ssl-cert",
    mode       => 0640,
    source     => "puppet://puppet/modules/pki/${clientcert}/${clientcert}.pem",
    require    => Package["ssl-cert"],
  }
  file { "/etc/ssl/${clientcert}.jks":
    ensure     => file,
    owner      => "root", 
    group      => "ssl-cert",
    mode       => 0640,
    source     => "puppet://puppet/modules/pki/${clientcert}/${clientcert}.jks",
    require    => Package["ssl-cert"],
  }
}

##################################################
### Service certs
##################################################
# A service certificate is associated with a CNAME that identifies a
# particular web service / applications. Unlike host
# certificates, these may be shared across multiple hosts, if the same
# service is running on multiple hosts.

define pki::service::publishcert ($fqdn) {
  # publish a service certificate to a host hosting that service
  file { "/etc/ssl/${fqdn}_cert.pem":
    ensure     => file,
    owner      => "root", 
    group      => "ssl-cert",
    mode       => 0640,
    source     => "puppet://puppet/modules/pki/${fqdn}/${fqdn}_cert.pem",
  }
  file { "/etc/ssl/${fqdn}_key.pem":
    ensure     => file,
    owner      => "root", 
    group      => "ssl-cert",
    mode       => 0640,
    source     => "puppet://puppet/modules/pki/${fqdn}/${fqdn}_key.pem",
  }
  file { "/etc/ssl/${fqdn}.pem":
    ensure     => file,
    owner      => "root", 
    group      => "ssl-cert",
    mode       => 0640,
    source     => "puppet://puppet/modules/pki/${fqdn}/${fqdn}.pem",
  }
  file { "/etc/ssl/${fqdn}.jks":
    ensure     => file,
    owner      => "root", 
    group      => "ssl-cert",
    mode       => 0640,
    source     => "puppet://puppet/modules/pki/${fqdn}/${fqdn}.jks",
  }
}

define pki::service::unpublishcert ($fqdn) {
  # unpublish a service certificate from a host no longer hosting that service
  file { "/etc/ssl/${fqdn}_cert.pem":
    ensure     => absent,
  }
  file { "/etc/ssl/${fqdn}_key.pem":
    ensure     => absent,
  }
  file { "/etc/ssl/${fqdn}.pem":
    ensure     => absent,
  }
  file { "/etc/ssl/${fqdn}.jks":
    ensure     => absent,
  }
}

class pki::service::publish {
  # publish all service certificates in use on a host
  include pki::service
}

##################################################
### Revoking certs
##################################################

define pki::revoke ($fqdn, $serial) {
  # revoke a certificate (assumes it exists)
  $basedir  = "${pki::config::ca_folder}"
  $tmpl     = "${basedir}/${fqdn}/${fqdn}_host_template.cfg"
  $key      = "${basedir}/${fqdn}/${fqdn}_key.pem"
  $csr      = "${basedir}/${fqdn}/${fqdn}_request.pem"
  $cert     = "${basedir}/${fqdn}/${fqdn}_cert.pem"
  $combined = "${basedir}/${fqdn}/${fqdn}.pem"
  $keystore = "${basedir}/${fqdn}/${fqdn}.jks"
  $md5      = "${basedir}/${fqdn}/${fqdn}_cert.md5"
  $ca       = "${basedir}/ca.pem"

  exec { "pki::revoke::md5::$fqdn":
    command =>"mv ${md5} ${md5}.revoked",
    cwd     => "$basedir",
    creates => "${md5}.revoked",
    onlyif  => "test -e ${md5}",
    notify  => [
      Exec["pki::md5::concat::postfix"],
    ],
  }
  exec { "pki::revoke::jks::$fqdn":
    command =>"mv ${keystore} ${keystore}.revoked",
    cwd     => "$basedir",
    creates => "${keystore}.revoked",
    onlyif  => "test -e ${keystore}",
  }
  exec { "pki::revoke::combined::$fqdn":
    command =>"mv ${combined} ${combined}.revoked",
    cwd     => "$basedir",
    creates => "${combined}.revoked",
    onlyif  => "test -e ${combined}",
  }
  exec { "pki::revoke::cert::$fqdn":
    command =>"mv ${cert} ${cert}.revoked",
    cwd     => "$basedir",
    creates => "${cert}.revoked",
    onlyif  => "test -e ${cert}",
    notify  => [
      Exec["pki::ca::revocations::combined"],
    ],
  }
  exec { "pki::revoke::key::$fqdn":
    command =>"mv ${key} ${key}.revoked",
    cwd     => "$basedir",
    creates => "${key}.revoked",
    onlyif  => "test -e ${key}",
  }
  exec { "pki::revoke::csr::$fqdn":
    command =>"mv ${csr} ${csr}.revoked",
    cwd     => "$basedir",
    creates => "${csr}.revoked",
    onlyif  => "test -e ${csr}",
  }
  exec { "pki::revoke::tmpl::$fqdn":
    command =>"mv ${tmpl} ${tmpl}.revoked",
    cwd     => "$basedir",
    creates => "${tmpl}.revoked",
    onlyif  => "test -e ${tmpl}",
  }
}

##################################################
### Putting it all together (on the master server)
##################################################

class pki::ca {
  include pki::packages
  include pki::fixperms
  include pki::config
  include pki::ca::setup
  include pki::ca::revocations
  include pki::postfix::clientcerts

  include pki::hosts
  include pki::services
}

class pki::host {
  include pki::host::publish
  include pki::service::publish
}
