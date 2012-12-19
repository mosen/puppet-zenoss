class zenoss::install::deps::nagios-plugins {

	# Zenoss Core Requires a basic set of Nagios plugins

	package { "nagios-plugins":
		ensure => installed,
	}

	package { "nagios-plugins-dig":
		ensure => installed,
	}

	package { "nagios-plugins-dns":
		ensure => installed,
	}

	package { "nagios-plugins-http":
		ensure => installed,
	}

	package { "nagios-plugins-ircd":
		ensure => installed,
	}

	package { "nagios-plugins-ldap":
		ensure => installed,
	}

	package { "nagios-plugins-ntp":
		ensure => installed,
	}

	package { "nagios-plugins-perl":
		ensure => installed,
	}

	package { "nagios-plugins-ping":
		ensure => installed,
	}

	package { "nagios-plugins-rpc":
		ensure => installed,
	}

	package { "nagios-plugins-tcp":
		ensure => installed,
	}

}