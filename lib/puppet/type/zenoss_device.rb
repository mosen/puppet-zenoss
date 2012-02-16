Puppet::Type.newtype(:zenoss_device) do
	@doc = "Manage zenoss devices
	
	This type should be used as a virtual resource, and then realized on the node running the zenoss
	web application if you want to have a more secure method of zenoss management via puppet.
	
	You can declare zenoss_device on the agents, but each agent will require the ability to contact the
	web application via port 8080. This presents a vector for a man-in-the-middle attack.
	eg. zenoss credentials captured via network traffic.
	
	This might not be a big problem if there are other security measures in place, or if you are using a
	test environment.
	"
	
	# TODO: require feature net::http and json gem
	
	ensurable
	
	newparam(:uid) do
	  desc "read-only property of zenoss device, uniquely identifies the device in the system"
	end
	
	newparam(:name) do
		desc "Name or IP of the device"
		
		isnamevar
	end

	newparam(:device_class) do
		desc "The device class
		
		The default class is /Server
		"
		
		defaultto "/Server"
		#TODO: loose validation
		#TODO: default via operatingsystem
	end
	
	newparam(:title) do
		desc "The descriptive title of the device"
	end
	
	newparam(:snmp_community) do
		desc "A specific SNMP community string to use for this device"
	end
	
	newparam(:snmp_port) do
		desc "A specific SNMP port to use for this device"

    validate do |value|
      if value.to_s !~ /^-?\d+$/
        raise ArgumentError, "SNMP port must be provided as a number."
      end      
    end
	end
	
	newparam(:location_path) do
		desc "Organizer path of the location for this device"
	end
	
	newparam(:system_paths) do
		desc "List of organizer paths for the device"
	end
	
	newparam(:group_paths) do
		desc "List of organizer paths for the device"
	end
	
	newparam(:model) do
		desc "Model the device if it is being created for the first time?"
		
		newvalues(:true, :false)
		defaultto :true
	end
	
	newparam(:collector) do
		desc "Collector to use for the device"
		
		defaultto "localhost"
	end
	
	newparam(:rack_slot) do
	  desc "Rack slot description"
	end
	
	newparam(:production_state) do
		desc "The zenoss production state"
		
		# States that are supplied out of the box with zenoss
		DEFAULT_STATES = {
		  :production     => 1000,
		  :pre_production => 500,
		  :test           => 400,
		  :maintenance    => 300,
		  :decommissioned => -1
		}

    # Allow usage of named production states
		munge do |value|
		  resource[:production_state] = DEFAULT_STATES[value] if DEFAULT_STATES.include? value
		end
		
		defaultto DEFAULT_STATES[:production]
	end
	
	newparam(:comments) do
	  desc "Comments on this device"
	  defaultto "This entry is managed by puppet. changes may be overridden."
	end
	
	newparam(:hw_manufacturer) do
	  desc "Hardware manufacturer name"
	  
	  defaultto Facter['manufacturer'].value
	end
	
	newparam(:hw_product_name) do
	  desc "Hardware product name"
	  
	  defaultto Facter['productname'].value  
	end
	
	newparam(:os_manufacturer) do
	  desc "OS manufacturer name"
	end
	
	newparam(:os_product_name) do
	  desc "OS product name"
	  
	  defaultto {
	    case Facter['operatingsystem'].value
      when 'Debian'
        Facter['lsbdistdescription'].value
      when 'Darwin'
        Facter['sp_os_version'].value
      else
        ''
	    end
	  }
	end
	
	newparam(:priority) do
		desc "Priority"
		
		# These priorities are supplied out of the box with Zenoss
		DEFAULT_PRIORITIES = {
		  :highest => 5,
		  :high    => 4,
		  :normal  => 3,
		  :low     => 2,
		  :lowest  => 1,
		  :trivial => 0
		}
		
		# Allow usage of named priorities
		munge do |value|
		  resource[:priority] = DEFAULT_PRIORITIES[value] if DEFAULT_PRIORITIES.include? value
		end
		
		defaultto DEFAULT_PRIORITIES[:normal]
	end
	
	newparam(:tag) do
	  desc "Tag number/code of this device"
	end
	
	newparam(:serial_number) do
	  desc "Serial number of this device"
	  
	  defaultto {
	    case Facter['operatingsystem'].value
	    when 'Darwin'
	      Facter['sp_serial_number'].value
	    else
	      nil
	    end
	  }
	end
	
	# Zenoss Monitor/Collector Details, TODO: find a better place for these
	newparam(:zenoss_host) do
	  desc "Hostname of the zenoss api host"
	  defaultto "localhost"
	end
	
	newparam(:zenoss_port) do
	  desc "Port number to use for the zenoss web application"
	  defaultto "8080"
	end
	
	newparam(:zenoss_username) do
	  desc "Username for the zenoss web application. must have permission to perform the requested actions"
	  defaultto "admin"
	end
	
	newparam(:zenoss_password) do
	  desc "Password for the zenoss web application."
    defaultto "password"
  end
end