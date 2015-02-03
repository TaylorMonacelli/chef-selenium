def whyrun_supported?
  true
end

# returns port for 'localhost:1234' or '1234'
def port(webdriver)
  webdriver.match(/.*[:](.*)/).captures[0].to_i
rescue
  webdriver.to_i
end

# TODO: Get configuration file working and add ghostdriver parameters as well
# def config(resource)
#   config_file = "#{selenium_home}/config/#{resource.name}.json"
#   template config_file do
#     source 'phantomjs_config.erb'
#     cookbook 'selenium'
#     variables(
#       resource: resource
#     )
#     notifies :request, "windows_reboot[Reboot to start #{resource.name}]" if platform_family?('windows')
#     notifies :restart, "service[#{resource.name}]" unless platform_family?('windows')
#   end
#   config_file
# end

action :install do
  converge_by("Install PhantomJS Service: #{new_resource.name}") do
    # args = [%(--config="#{config(new_resource)}")]
    args = []
    args << "--webdriver=#{new_resource.webdriver}"
    if new_resource.webdriverSeleniumGridHub
      args << "--webdriver-selenium-grid-hub=#{new_resource.webdriverSeleniumGridHub}"
    end

    if platform?('windows')
      if new_resource.username && new_resource.password
        windows_foreground(new_resource.name, node['selenium']['windows']['phantomjs'], args, new_resource.username)
        autologon(new_resource.username, new_resource.password, new_resource.domain)
      else
        windows_service(new_resource.name, node['selenium']['windows']['phantomjs'], args)
      end
      windows_firewall(new_resource.name, port(new_resource.webdriver))
    else
      linux_service(new_resource.name, node['selenium']['linux']['phantomjs'], args, port(new_resource.webdriver), nil)
    end

    windows_reboot "Reboot to start #{new_resource.name}" do
      reason "Reboot to start #{new_resource.name}"
      timeout node['windows']['reboot_timeout']
      action :nothing
      only_if { platform_family?('windows') }
    end
  end
end
