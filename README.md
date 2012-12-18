Zenoss puppet module
--------------------

*IS BROKEN WHILE IN DEVELOPMENT INITIALLY*

This module aims to provide support for the Zenoss monitoring system.

Initially the development goal is to automate the addition and removal of devices from
zenoss that are also under management by puppet.

Development may further spread into managing MIB databases, ZenPacks etc. but there is
currently no requirement for this functionality.

Features
--------

In development:
- zenoss_device provider (add/remove/change) devices
- zenoss installation

Planned:
- zenoss_trigger provider

Long term:
- other API's (mib database, subnet, process)

Zenoss_device Usage
-------------------

The zenoss_device type allows you to add/remove/change devices within zenoss.

Before you define resources, you need to set up the zenoss host details as
resource defaults, shown below in example1.pp.

example1.pp
-----------
```ruby

# Set up our zenoss host information, this is the monitoring node.
Zenoss_device {
	zenoss_host     => "localhost",
	zenoss_port     => "8080",
	zenoss_username => "admin",
	zenoss_password => "password",
}

# Add a device to zenoss
zenoss_device { "192.168.1.1":
	ensure   => present,
	title    => "Ground level network switch",
}
```

