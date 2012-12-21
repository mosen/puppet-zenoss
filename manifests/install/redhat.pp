# Install Zenoss Core 4 on a RHEL/CentOS Node
# Some steps must still be performed manually, but will be automated in the near future.

#error: Failed dependencies:
#	mysql-shared >= 5.5.13 is needed by zenoss-4.2.0-1586.el6.x86_64
#	rrdtool >= 1.4.7 is needed by zenoss-4.2.0-1586.el6.x86_64

class zenoss::install::redhat (

	# Open firewall ports associated with Zenoss Core, you will not be able to access the administrative interface if they are blocked.
	$open_firewall = $zenoss::install::params::open_firewall,

	# Zenoss Core daemons will run as this user
	$zenoss_user = $zenoss::install::params::zenoss_user,
	$zenoss_password = $zenoss::install::params::zenoss_password,

	# Zenoss Core Web Application Data
	$zenoss_db_host = $zenoss::install::params::zenoss_db_host,
	$zenoss_db_user = $zenoss::install::params::zenoss_db_user,
	$zenoss_db_password = $zenoss::install::params::zenoss_db_password,

	# MySQL Administrator (zenoss will use this to create new databases on startup check)
	$zenoss_db_admin_user = $zenoss::install::params::zenoss_db_admin_user,
	$zenoss_db_admin_password = $zenoss::install::params::zenoss_db_admin_password

	) inherits zenoss::install::params {

	# DEPENDENCIES

  # EPEL provides nagios-plugins-*
  include epel

  # REPOFORGE (rpmforge-extras) provides rrdtool >= 1.7.4
  include repoforge

  # Les RPMS de Remi provides MySQL >= 5.5 except mysql-shared package.
  include zenoss::install::deps::repo_remi

  # Zenoss 4.2 Requires RabbitMQ
  include zenoss::install::deps::rabbitmq

  # Zenoss 4.2 Requires MySQL >= 5.5.13
  class { 'zenoss::install::deps::mysql':
    require => Class['zenoss::install::deps::repo_remi'],
  }

  # Zenoss 4.2 Requires some core nagios plugins
  class { 'zenoss::install::deps::nagios-plugins':
    require => Class['epel'],
  }

  # Zenoss 4.2 Explicitly states that only Oracle JRE may be used
  include zenoss::install::deps::jdk

  # Open up firewall ports for Zenoss and related services
  if ($open_firewall) {
    include zenoss::install::firewall
  }

	## Step Two: Prerequisite package and service installation

	# Zenoss Core Requires memcached
    
    package { "memcached":
    	ensure => installed,
	}

    service { "memcached":
    	ensure => running,
    	require => Package["memcached"],
	}

	# Zenoss Core Recommends snmpd and it is a sane default to have it installed.

	package { "net-snmp":
		ensure => installed,
	}

	package { "net-snmp-utils":
		ensure => installed,
	}

	service { "snmpd":
		ensure => running,
		require => Package["net-snmp"],
	}





	# Misc other requirements

  package { "pkgconfig":
    ensure => installed,
  }

  package { "dmidecode":
    ensure => installed,
  }

  package { "libxslt":
    ensure => installed,
  }

  package { "sysstat":
    ensure => installed,
  }

	package { "liberation-fonts-common":
		ensure => installed,
	}

	package { "liberation-mono-fonts":
		ensure => installed,
	}

	package { "liberation-sans-fonts":
		ensure => installed,
	}

	package { "liberation-serif-fonts":
		ensure => installed,
	}

	package { "libgcj":
		ensure => installed,
	}

	# Zenoss Core Requires rrdtool >= 1.7.4 which is currently only available from repoforge/rpmforge-extras
	# Only older versions are available on the base repo.
  # The repoforge module does not enable rpmforge-extras by default.

	package { "rrdtool":
		ensure  => latest, # Should be at least 1.7.4
		require => Class["repoforge"],
		# enablerepo rpmforge-extras
	}




	# Create the user that zenoss daemons will run as

	user { $zenoss_user:
		ensure => present,
	}

	file { "/home/${zenoss_user}":
		ensure  => directory,
		owner   => $zenoss_user,
		mode    => 0755,
		require => User[$zenoss_user],
	}

	file { "/home/${zenoss_user}/.bash_profile":
		ensure => present,
		owner  => $zenoss_user,
		mode   => 0644,
		require => File["/home/${zenoss_user}"],
		content => template('zenoss/zenoss_bash_profile.erb'),
	}





	# Install Zenoss Core 4

	$zenoss_pkg_url = "http://sourceforge.net/projects/zenoss/files/zenoss-4.2/zenoss-4.2.0/zenoss-4.2.0.el6.x86_64.rpm/download"

  # Added this because testing was taking an unreasonable amount of time when downloading zenoss repeatedly.
	exec { "download-zenoss-core-4":
		command => "/usr/bin/wget -O /var/tmp/zenoss-4.2.0.rpm $zenoss_pkg_url",
		creates => "/var/tmp/zenoss-4.2.0.rpm",
	}

	package { "zenoss":
		ensure   => installed,
		source   => "/var/tmp/zenoss-4.2.0.rpm",
		require  => [
		  Package[
				"liberation-fonts-common",
				"liberation-mono-fonts",
				"liberation-sans-fonts",
				"liberation-serif-fonts",
				"libgcj",
				"nagios-plugins",
				"net-snmp-utils",
				"rrdtool",
				"pkgconfig",
				"dmidecode",
        "libxslt",
        "sysstat"
	    ],
	    Exec[ 'download-zenoss-core-4' ],
	    Database[
        "zodb",
        "zodb_session",
        "zenoss_zep"
      ]
	  ],
		provider => rpm,
	}

	file { "/opt/zenoss/etc/global.conf":
		ensure  => present,
		content => template('zenoss/global.conf.erb'),
		require => Package["zenoss"],
	}

	service { "zenoss":
		ensure  => running,
		require => [ Package["zenoss"], File["/opt/zenoss/etc/global.conf"] ],
	}

	$zenpacks_url = "http://sourceforge.net/projects/zenoss/files/zenpacks-4.2/zenpacks-4.2.0/zenoss-core-zenpacks-4.2.0.el6.x86_64.rpm"

	package { "zenoss-core-zenpacks":
		ensure  => installed,
		source  => $zenpacks_url,
		require => Package["zenoss"],
	}
}