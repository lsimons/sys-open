# I'm sure there is a better way to do this.
# We use the fqdn that the client gives us to push certificates to the client. 
# However, the fqdn is provided _by_the_client_ using facter. Facter can easily
# be manipulated into returning 'puppet.domain.ext' as the value for 'fqdn'. 
# 
# I cannot think of something more clever at the moment, other than verifying
# the fqdn against the hostname.domain in the certificate. This needs to be
# done on the puppetmaster, as we do not trust the clients. 
#
# In order to do this, we will test the fingerprint provided by the client
# against the fingerprint of the fqdn.certificate.
#
# Should the client provide a fake fqdn, the puppetmaster will try to resolve
# the fingerprint of fake.domainname.pem. This will either fail, as that file
# may not exist. Or it will succeed, but will return a different fingerprint
# than the one the client has provided. 
#
# Should the client have managed to provide a false fingerprint that also
# matches the certificate of the false fqdn, than we have a problem. This is an
# acceptable risk, IMHO.

Facter.add(:fingerprint) do
 setcode do
   # I feel dirty now. 
   fingerprint = Facter::Util::Resolution.exec('puppet agent --fingerprint')
 end
end
