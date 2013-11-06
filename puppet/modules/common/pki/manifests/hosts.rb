# helper that defines pki::cert or pki::revoke for each system in systems.yml

hostclass :"pki::hosts" do
  management = scope.lookupvar("management")
  # exclude = management['exclude_environments']

  nodes = YAML::load( File.open( '/etc/sys/puppet/systems.yml' ))

  certificates = {}
  revoked = {}
  serials = []
  
  nodes.each do |fqdn, params|
    env = params['env']
    # make local certs for testing
    # if exclude.include? env
    #   next
    # end
    
    if not params.has_key?('serial')
      # we have some old hosts that did not get certs at all
      next
    end

    serial = params['serial']
    if serials.include? serial
      raise "Duplicate serial #{serial} in systems.yml"
    else
      serials.push(serial)
    end
    if env == "deleted"
      revoked["pki::hosts::revoked::#{fqdn}"] = {
        "fqdn"   => fqdn,
        "serial" => serial,
      }
    else
      certificates["pki::hosts::cert::#{fqdn}"] = {
        "fqdn"   => fqdn,
        "serial" => serial,
      }
    end
  end

  create_resources(['pki::cert',   certificates])
  create_resources(['pki::revoke', revoked])
end
