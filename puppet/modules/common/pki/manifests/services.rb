# simple helper to convert app config into pki cert config

hostclass :"pki::services" do
  domain = scope.lookupvar("domain")
  management = scope.lookupvar("management")
  # exclude = management['exclude_environments']

  service_certificates = {}
  revoked_services = {}
  
  serials = []
  
  # this would just get you the apps to be hosted on the management host...
  # java_apps = scope.lookupvar("java_apps")
  # passenger_apps = scope.lookupvar("passenger_apps")
  # wsgi_apps = scope.lookupvar("wsgi_apps")
  # php_apps = scope.lookupvar("php_apps")
  # apps = java_apps + passenger_apps + wsgi_apps + php_apps
  
  deleted_apps = scope.lookupvar("deleted_apps")
  deleted_apps = deleted_apps["java_apps"] + deleted_apps["passenger_apps"] + deleted_apps["wsgi_apps"] + deleted_apps["php_apps"]

  app_config = YAML::load( File.open( '/etc/sys/puppet/apps.yml' ))
  app_config.each do |profile, profile_config|
    if profile == "deleted"
      next
    end
    profile_apps = []
    if profile_config.has_key?('java_apps')
      profile_apps += profile_config['java_apps']
    end
    if profile_config.has_key?('passenger_apps')
      profile_apps += profile_config['passenger_apps']
    end
    if profile_config.has_key?('wsgi_apps')
      profile_apps += profile_config['wsgi_apps']
    end
    if profile_config.has_key?('php_apps')
      profile_apps += profile_config['php_apps']
    end
    profile_apps.each do |app|
      if not app.has_key?('AppName')
        raise "application without AppName"
      end
      app_name = app['AppName']

      if not app.has_key?('serials')
        next
      end

      deleted_apps.each do |deleted_app|
        if not deleted_app.has_key?('AppName')
          raise "application without AppName"
        end
        deleted_app_name = deleted_app['AppName']
        if app_name == deleted_app_name
          raise "application #{app_name} is also in deleted section"
        end
      end
  
      app_serials = app['serials']
      app_serials.each do |app_environment, serial|
        # make local certs for testing
        # if exclude.include? app_environment
        #   next
        # end
        if serials.include? serial
          raise "Duplicate serial #{serial} in pki::services"
        else
          serials.push(serial)
        end
        fqdn = "#{app_name}.#{app_environment}.#{domain}"
        service_certificates["pki::services::cert::#{fqdn}"] = {
            "fqdn"   => fqdn,
            "serial" => serial
        }
      end
    end
  end

  deleted_apps.each do |app|
    if not app.has_key?('AppName')
      raise "application without AppName"
    end
    app_name = app['AppName']
    if not app.has_key?('serials')
      next
    end
    app_serials = app['serials']
    app_serials.each do |app_environment, serial|
      # make local certs for testing
      # if exclude.include? app_environment
      #   next
      # end
      if serials.include? serial
        raise "Duplicate serial #{serial} in pki::services"
      else
        serials.push(serial)
      end
      fqdn = "#{app_name}.#{app_environment}.#{domain}"
      revoked_services["pki::services::revoked::#{fqdn}"] = {
          "fqdn"   => fqdn,
          "serial" => serial
      }
    end
  end
  
  create_resources(['pki::cert',   service_certificates])
  create_resources(['pki::revoke', revoked_services])
end
