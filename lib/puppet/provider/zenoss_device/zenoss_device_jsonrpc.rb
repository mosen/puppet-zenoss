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
  
  DEVICECLASS_PREFIX = "/zport/dmd/Devices" # Some API requires this prefix for deviceClass
  
  # TODO: how can we grab instances without the zenoss config being external to the type definition?
  # def self.instances
  #   puts 'grabbing instances'
  #   devices = self.get_devices
  #   puts devices.inspect
  # end
  # 
  # def self.prefetch(resources)
  #   puts 'prefetching devices'
  #   
  #   resources.each do |name, device|
  #     puts name
  #     puts device.title
  #   end
  # end
  
  def create
    self.login if !@cookie
    
    device_properties = {
      "deviceName"      => resource[:name],
      "deviceClass"     => resource[:device_class],
      "title"           => resource[:title],
      "snmpCommunity"   => resource[:snmp_community],
      "snmpPort"        => resource[:snmp_port],
      "locationPath"    => resource[:location_path],
      "systemPaths"     => resource[:system_paths],
      "groupPaths"      => resource[:group_paths],
      "model"           => resource[:model],
      "collector"       => resource[:collector],
      "rackSlot"        => resource[:rack_slot],
      "productionState" => resource[:production_state],
      "comments"        => resource[:comments],
      "hwManufacturer"  => resource[:hw_manufacturer],
      "hwProductName"   => resource[:hw_product_name],
      "osManufacturer"  => resource[:os_manufacturer],
      "osProductName"   => resource[:os_product_name],
      "priority"        => resource[:priority],
      "tag"             => resource[:tag],
      "serialNumber"    => resource[:serial_number]
    }
    
    device_properties.delete_if {|k, v| v.nil? }
    
    result = add_device(device_properties)
    
    raise Puppet::Error, "There was an error adding a device to zenoss..." if !result["success"]
    
    Puppet.debug "Zenoss device created with jobId #{result['jobId']}, check jobs page for status"
  end
  
  def destroy
    self.login if !@cookie
    
    # TODO: prefetch devices, populate resources with UID prior to destroy being run.
    devices = get_devices(resource[:device_class])
    result = nil
    
    devices.each do |d|
      if d["name"] == resource[:name] || d["name"] == resource[:title]
        result = remove_devices([d["uid"]])
      end
    end
    
    device_names = devices.map {|d| d["name"] }
    
    raise Puppet::Error, "Zenoss attempted to delete a device that wasnt listed." if result.nil?
      
    result
  end
  
  def exists?
    self.login if !@cookie
    devices = get_devices(resource[:device_class])
    device_names = devices.map {|d| d["name"] }
    #device_titles = devices.map{|d| d["title"] }
    
    device_names.include?(resource[:name]) || device_names.include?(resource[:title])
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
      JSON.parse(response.body)
    rescue
      Puppet.debug response.body # TODO: attempt parse of response to glean error message
      raise Puppet::Error, "Zenoss rejected one of our requests, please check the zenoss host details to ensure they are correct."
    end
  end
  
  def get_devices(device_class='')
    device_class = DEVICECLASS_PREFIX + device_class 
    response = _router_request("DeviceRouter", "getDevices", [{
      "uid"    => device_class,
      "params" => {} # TODO: support full API getDevices with filter parameters.
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
    Puppet.debug "Zenoss removing devices with UIDs: " + uids.join(',')
    
    response = _router_request("DeviceRouter", "removeDevices", [{
      "uids"         => uids,
      "hashcheck"    => @hashcheck,
      "action"       => action
      # "deleteEvents" => true, # TODO: make configurable
      # "deletePerf"   => true
    }])
    
    raise Puppet::Error, "Zenoss cannot delete the device, " + response["message"] if response["type"] == "exception"
    
    response["result"]
  end
end