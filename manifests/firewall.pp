# Open firewall ports for Zenoss Core 4 Services
class zenoss::firewall {

	# Open firewall ports for Zenoss Core 4
	# Depends on: puppetlabs-firewall
	# Allow the following ports as specified in the zenoss core installation guide

	firewall { '680 zenoss allow memcached':
		proto  => 'tcp', # Should also be udp
		dport  => '11211',
		action => 'accept',
	}

	firewall { '681 zenoss allow webservice':
		proto  => 'tcp',
		dport  => '8080',
		action => 'accept',
	}

	firewall { '682 zenoss allow syslog':
		proto  => 'udp',
		dport  => '514',
		action => 'accept',
	}

	firewall { '682 zenoss allow snmptrap':
		proto  => 'udp',
		dport  => '162',
		action => 'accept',
	}
}