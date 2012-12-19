# Install Zenoss Core 4 on a RHEL/CentOS Node
# Some steps must still be performed manually, but will be automated in the near future.

#	jre >= 1.6.0 is needed by zenoss-4.2.0-1586.el6.x86_64
#	libmysqlclient.so.18()(64bit) is needed by zenoss-4.2.0-1586.el6.x86_64
#	mysql-server >= 5.5.13 is needed by zenoss-4.2.0-1586.el6.x86_64
#	mysql-shared >= 5.5.13 is needed by zenoss-4.2.0-1586.el6.x86_64

# Can't find rabbitmq-server >= 2.8.4 in any repo?!?
#	rabbitmq-server >= 2.8.4 is needed by zenoss-4.2.0-1586.el6.x86_64
#

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

  # EPEL provides rabbitmq WRONG VERSION, nagios-plugins-*
  include epel

  # REPOFORGE provides rrdtool >= 1.7.4
  include repoforge

  # zeneventhub(?) >= 4.0 now requires RabbitMQ
  include zenoss::install::deps::rabbitmq

  # zodb uses mysql::server and prefers version >= 5.5
  include zenoss::install::deps::mysql

  # Zenoss Core 4 Requires various nagios plugins
  include zenoss::install::deps::nagios-plugins


  # Zenoss Core 4 Requires Oracle JRE for some reason
  include zenoss::install::deps::jdk

  # Open up firewall ports for Zenoss and related services
  include zenoss::install::firewall

	## Step One : Package Conflicts
	## Remove conflicting packages




	# Zenoss Core Recommends removing matahari to use RabbitMQ
	# TODO : Stop matahari first

	package { "matahari-network":
		ensure => absent,
	}

	package { "matahari-broker":
		ensure  => absent,
	}

	package { "matahari-service":
		ensure => absent,
	}

	package { "matahari-lib":
		ensure => absent,
		require => Package["matahari-agent-lib", "matahari-sysconfig", "matahari-network"],
	}

	package { "matahari-host":
		ensure => absent,
	}

	package { "matahari-sysconfig":
		ensure => absent,
	}

	package { "matahari":
		ensure => absent,
	}

	package { "matahari-agent-lib":
		ensure => absent,
	}

	# Zenoss Core Recommends removing qpid to use RabbitMQ
	# TODO : Stop qpid first

	package { "qpid-cpp-client-ssl":
		ensure => absent,
		require => Package["qpid-qmf"],
	}

	package { "qpid-qmf":
		ensure => absent,
	}

	package { "qpid-cpp-client":
		ensure => absent,
		require => Package["qpid-cpp-client-ssl", "qpid-qmf", "qpid-cpp-server"],
	}

	package { "qpid-cpp-server":
		ensure => absent,
		require => Package["qpid-cpp-server-ssl"],
	}

	package { "qpid-cpp-server-ssl":
		ensure => absent,
		require => Package["matahari-broker"],
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

	#exec { "download-zenoss-core-4":
	#	command => "/usr/bin/wget -O /var/tmp/zenoss-4.2.0.rpm $zenoss_url",
	#	creates => "/var/tmp/zenoss-4.2.0.rpm",
	#}

	package { "zenoss":
		ensure   => installed,
		source   => $zenoss_pkg_url,
		require  =>
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
        "sysstat",
        "jdk"
			],
		provider => rpm,
	}

	#	package { "zenoss":
  #		ensure   => installed,
  #		source   => $zenoss_pkg_url,
  #		require  => [
  #		  Package[
  #				"liberation-fonts-common",
  #				"liberation-mono-fonts",
  #				"liberation-sans-fonts",
  #				"liberation-serif-fonts",
  #				"libgcj",
  #				"nagios-plugins",
  #				"net-snmp-utils",
  #				"rrdtool",
  #				"pkgconfig",
  #				"dmidecode",
  #        "libxslt",
  #        "jdk"
  #			],
  #			Database[
  #			  "zodb",
  #			  "zodb_session",
  #			  "zenoss_zep"
  #			]
  #		],
  #		provider => rpm,
  #	}

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
		ensure => installed,
		source => $zenpacks_url,
		require => Package["zenoss"],
	}
}