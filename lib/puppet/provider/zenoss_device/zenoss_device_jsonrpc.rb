require 'net/http'
require 'rubygems'
require 'json'
require 'facter'

Puppet::Type.type(:zenoss_device).provide :zenoss_device_jsonrpc, :parent => Puppet::Provider do  

  desc "Zenoss device management via the Zenoss 3.0 JSON API
  
  This provider interacts with the Zenoss monitoring system through its JSON API.
  
  The type should be used as a virtual resource, with the zenoss monitor realizing all of those virtually
  declared zenoss resources. This way, zenoss traffic doesn't pass from the agent to the zenoss collector,
  which gives us a tiny bit of security.
  "
  
  ROUTERS = {
    "MessagingRouter" => "messaging",
    "EventsRouter"    => "evconsole",
    "ProcessRouter"   => "process",
    "ServiceRouter"   => "service",
    "DeviceRouter"    => "device",
    "NetworkRouter"   => "network",
    "TemplateRouter"  => "template",
    "DetailNavRouter" => "detailnav",
    "ReportRouter"    => "report",
    "MibRouter"       => "mib",
    "ZenPackRouter"   => "zenpack"
  }
  
  # def self.instances
  #   puts 'grabbing instances'
  #   devices = self.get_devices
  #   puts devices.inspect
  # end
  # 
  # def self.prefetch(resources)
  #   puts 'prefetching devices'
  # end
  
  def create
    self.login if !@cookie
    
    result = add_device({
      "deviceName"  => resource[:name],
      "deviceClass" => resource[:device_class],
      "title"       => resource[:title],
      "priority"    => resource[:priority],
      "productionState" => resource[:production_state]
    })
    
    raise Puppet::Error, "There was an error adding a device to zenoss..." if !result["success"]
    
    Puppet.debug "Zenoss device created with jobId #{result['jobId']}"
  end
  
  def destroy
    # self.login if !@cookie
    
    # TODO: prefetch devices, populate resources with UID prior to destroy being run.
    # devices = get_devices(resource[:class])
    # device_names = devices.map {|d| d["name"] }
    # current_device = device_names[resource[:name]]
    # 
    # result = remove_devices([current_device["uid"]])
  end
  
  def exists?
    self.login if !@cookie
    devices = get_devices(resource[:device_class])
    device_names = devices.map {|d| d["name"] }
    
    device_names.include? resource[:name]
  end
  
  # Initialize the API connection, log in, and store authentication cookie
  def login

    zenoss_username = resource[:zenoss_username]
    zenoss_password = resource[:zenoss_password]
    
    zenoss_uri = self.uri
    came_from = zenoss_uri + "/zport/dmd"
    
    login_form = {
      "__ac_name"     => zenoss_username,
      "__ac_password" => zenoss_password,
      "submitted"     => "true",
      "came_from"     => came_from
    }

    req = Net::HTTP::Post.new("/zport/acl_users/cookieAuthHelper/login")
    req.set_form_data(login_form)

    response = Net::HTTP.new(self.host, self.port).start {|http| 
      http.request(req) 
    }
    
    # TODO: determine if login was successful ? we don't seem to get any result code from the form submission.
    # At the moment we just have to raise errors when calling API that fails with 'unauthorized'
    Puppet.debug "Zenoss submitted HTTP login, redirect to: #{response.response['location']}"
    
    @cookie = response.response['set-cookie']
  end
  
  def host
    resource[:zenoss_host]
  end
  
  def port
    resource[:zenoss_port]
  end
  
  def uri
    zenoss_host = self.host
    zenoss_port = self.port
    "http://#{zenoss_host}:#{zenoss_port}"
  end
  
  def _router_request(router, method, data = [])

    raise Puppet::Error, "Router #{router} not available." if !router.include? router
    
    request_headers = {
      'Content-Type' =>'application/json', 
      'Cookie' => @cookie
    }
    
    req = Net::HTTP::Post.new(self.uri + "/zport/dmd/" + ROUTERS[router] + "_router", 
      request_headers)
      
    req.body = {
      "action" => router,
      "method" => method,
      "data"   => data,
      "type"   => "rpc",
      "tid"    => 1 # TODO: real request transaction id
    }.to_json
    
    response = Net::HTTP.new(self.host, self.port).start {|http| http.request(req) }

    begin
      response_obj = JSON.parse(response.body)
      response_obj
    rescue
      Puppet.debug response.body # TODO: attempt parse of response to glean error message
      raise Puppet::Error, "Zenoss rejected one of our requests, please check the zenoss host details to ensure they are correct."
    end
  end
  
  def get_devices(device_class = '/zport/dmd/Devices')
    response = _router_request("DeviceRouter", "getDevices", [{
      "uid"    => device_class,
      "params" => {}
    }])
    
    # Used to detect whether devices have changed between requests, prevents changes happening if
    # another call was made between our requests by another party.
    @hashcheck = response["result"]["hash"]
    Puppet.debug "Zenoss returned results with hash #{@hashcheck}"
    
    response["result"]["devices"]
  end
  
  # Add device using any of the properties from the JSON API spec addDevice
  def add_device(properties)
    _router_request("DeviceRouter", "addDevice", [properties])["result"]
  end
  
  # Remove device(s) by uids
  # TODO: maybe support full parameters list of this function, but most of it falls outside puppet scope.
  def remove_devices(uids, action="delete")
    response = _router_request("DeviceRouter", "removeDevices", [{
      "uids"         => uids,
      "hashcheck"    => @hashcheck,
      "action"       => action,
      "deleteEvents" => true, # TODO: make configurable
      "deletePerf"   => true
    }])
    
    response["result"]
  end
end