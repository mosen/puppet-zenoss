# Install Zenoss Core 4 on a RHEL/CentOS Node
# Some steps must still be performed manually, but will be automated in the near future.

#error: Failed dependencies:
#	mysql-shared >= 5.5.13 is needed by zenoss-4.2.0-1586.el6.x86_64
#	rrdtool >= 1.4.7 is needed by zenoss-4.2.0-1586.el6.x86_64

class zenoss::install::redhat (

	# Open firewall ports associated with Zenoss Core, you will not be able to access the administrative interface if they are blocked.
	$open_firewall = $zenoss::params::open_firewall,

  # You can enable or disable automatic installation of dependencies here
  # Eg. if you have those dependencies declared somewhere else, you can set these to false.
  $install_jre = $zenoss::params::install_jre,
  $install_mysql = $zenoss::params::install_mysql,
  $install_rabbitmq = $zenoss::params::install_rabbitmq,

	# Zenoss Core daemons will run as this user
	$zenoss_user = $zenoss::params::zenoss_user,
	$zenoss_password = $zenoss::params::zenoss_password,

	# Zenoss Core Web Application Data
	$zenoss_db_host = $zenoss::params::zenoss_db_host,
	$zenoss_db_user = $zenoss::params::zenoss_db_user,
	$zenoss_db_password = $zenoss::params::zenoss_db_password,

	# Zenoss Core Event Server Data
	$zenoss_event_db_host = $zenoss::params::zenoss_event_db_host,
	$zenoss_event_db_user = $zenoss::params::zenoss_event_db_user, # cannot be identical to the zenoss_db_user parameter
	$zenoss_event_db_password = $zenoss::params::zenoss_event_db_password,

  # Zenoss RabbitMQ User
  $zenoss_mq_user = $zenoss::params::zenoss_mq_user,
  $zenoss_mq_password = $zenoss::params::zenoss_mq_password,

	# MySQL Administrator (zenoss will use this to create new databases on startup check)
	$zenoss_db_admin_user = $zenoss::params::zenoss_db_admin_user,
	$zenoss_db_admin_password = $zenoss::params::zenoss_db_admin_password,

  # These components make up the package url
	$zenoss_version_short = $zenoss::params::zenoss_version_short,
	$zenoss_version = $zenoss::params::zenoss_version,
	$zenoss_package_name = $zenoss::params::zenoss_package_name,

	# Package will be fetched from this location
	$zenoss_package_url = $zenoss::params::zenoss_package_url

	) inherits zenoss::params {

	# DEPENDENCIES

  # EPEL provides nagios-plugins-*
  include epel

  # REPOFORGE (rpmforge-extras) provides rrdtool >= 1.7.4
  include repoforge

  # Les RPMS de Remi provides MySQL >= 5.5 except mysql-shared package.
  # TODO: Consider using percona or mariadb instead.
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

	# Install Zenoss Core 4

  # I added this as an exec because using a yum/rpm http source was taking a huge amount of time during testing.
	exec { "download-zenoss-core":
		command => "/usr/bin/wget -O /var/tmp/zenoss.rpm $zenoss_package_url",
		creates => "/var/tmp/zenoss.rpm",
	}

	package { "zenoss":
		ensure   => installed,
		source   => "/var/tmp/zenoss.rpm",
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
	    Exec[ 'download-zenoss-core' ],
	    Database[
        "zodb",
        "zodb_session",
        "zenoss_zep"
      ]
	  ],
		provider => rpm, # TODO: yum should probably be used instead to perform proper package upgrades
	}


  # Zenoss Core 4.2.3 states that zenpacks are now integrated into the rpm
#	$zenpacks_url = "http://sourceforge.net/projects/zenoss/files/zenpacks-4.2/zenpacks-4.2.0/zenoss-core-zenpacks-4.2.0.el6.x86_64.rpm"
#
#	package { "zenoss-core-zenpacks":
#		ensure  => installed,
#		source  => $zenpacks_url,
#		require => Package["zenoss"],
#	}
}