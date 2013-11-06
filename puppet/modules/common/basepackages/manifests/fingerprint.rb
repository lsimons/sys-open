# Trying to verify the fqdn by comparing SSL cert fingerprints.


hostclass :"basepackages::fingerprint" do

      fingerprint = scope.lookupvar('fingerprint')
      fqdn = scope.lookupvar('fqdn')
      verify_fingerprint = %x[ puppet cert fingerprint #{fqdn} ]
      verify_fingerprint = verify_fingerprint.split(' ')[1]

      # scope.unsetvar("verify_fingerprint")
      scope.setvar("verify_fingerprint", verify_fingerprint)
      content = "#{fingerprint} and #{verify_fingerprint}"

      fingerprint_verified = true
      if fingerprint == verify_fingerprint
        fingerprint_verified = '1'
      end
      scope.setvar("fingerprint_verified", fingerprint_verified)
end

