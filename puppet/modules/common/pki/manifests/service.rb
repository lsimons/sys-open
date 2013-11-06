hostclass :"pki::service" do
  env = scope.lookupvar("env")
  domain = scope.lookupvar("domain")

  service_certificates = {}
  revoked_services = {}
  
  serials = []
  
  deleted_apps = scope.lookupvar("deleted_apps")
  deleted_apps = deleted_apps["java_apps"] + deleted_apps["passenger_apps"] + deleted_apps["wsgi_apps"] + deleted_apps["php_apps"]
  

  all_apps = YAML::load( File.open( '/etc/sys/puppet/apps.yml' ))
  profile = scope.lookupvar("profile")
  if all_apps.has_key?(profile)
    profile_apps = all_apps[profile]

    if profile_apps.has_key?("java_apps")
      java_apps = profile_apps["java_apps"]
    else
      java_apps = []
    end
    if profile_apps.has_key?("passenger_apps")
      passenger_apps = profile_apps["passenger_apps"]
    else
      passenger_apps = []
    end
    if profile_apps.has_key?("wsgi_apps")
      wsgi_apps = profile_apps["wsgi_apps"]
    else
      wsgi_apps = []
    end
    if profile_apps.has_key?("php_apps")
      php_apps = profile_apps["php_apps"]
    else
      php_apps = []
    end
    apps = java_apps + passenger_apps + wsgi_apps + php_apps
    
    apps.each do |app|
      if not app.has_key?('AppName')
        raise "application without AppName"
      end
      app_name = app['AppName']
      deleted_apps.each do |deleted_app|
        if not deleted_app.has_key?('AppName')
          raise "application without AppName"
        end
        deleted_app_name = deleted_app['AppName']
        if app_name == deleted_app_name
          raise "application #{app_name} is also in deleted section"
        end
      end
    
      if not app.has_key?('serials')
        next
      end
      serials = app['serials']
      if not serials.has_key?(env)
        next
      end
      
      fqdn = "#{app_name}.#{env}.#{domain}"
      service_certificates["pki::service::cert::#{fqdn}"] = {
        "fqdn"   => fqdn,
      }
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

      fqdn = "#{app_name}.#{env}.#{domain}"
      revoked_services["pki::service::revoked::#{fqdn}"] = {
        "fqdn"   => fqdn,
      }
  end

  create_resources(['pki::service::publishcert', service_certificates])
  create_resources(['pki::service::unpublishcert', revoked_services])
end
