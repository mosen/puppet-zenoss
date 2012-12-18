# Install Zenoss Core 4 on a RHEL/CentOS Node
# Some steps must still be performed manually, but will be automated in the near future.

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
	
	## Step One : Package Conflicts
	## Remove conflicting packages


	# Zenoss wont run with MySQL < 5.5
	# TODO : Check for MySQL < 5.5 and raise error

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

	# Zenoss Core Requires RabbitMQ which depends on erlang
	
	package { "erlang":
		ensure => installed,
	}

	# This class is defined in puppetlabs module: puppetlabs-rabbitmq
	class { 'rabbitmq::repo::rhel':
        version    => "2.8.4",
        relversion => "1",
        require => Package["erlang"],
    }

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

	# Misc other requirements

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
	
	package { "rpmforge-release":
		ensure => installed,
		source => "http://packages.sw.be/rpmforge-release/rpmforge-release-0.5.2-2.el6.rf.x86_64.rpm",
	}

	package { "rrdtool":
		ensure  => latest, # Should be at least 1.7.4
		require => Package["rpmforge-release"],
	}


	# Zenoss recommends setting my.cnf
	#[mysqld]
	# max_allowed_packet=16M
	# innodb_buffer_pool_size=256M
	# innodb_additional_mem_pool_size=20M








	# Remi RPMS provided most dependencies except mysql-shared
	# which i wgetted from wget http://cdn.mysql.com/Downloads/MySQL-5.5/MySQL-shared-5.5.27-1.el6.x86_64.rpm

	# rrdtool newer than base was obtained from repoforge (rpmforge-extras)


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

	# Create the zenoss databases
	# Normally these would be created by the zenoss startup process
	# but explicitly creating them here gives us greater control over parameters.
	# Dependency: puppetlabs-mysql

	database { 'zodb':
		ensure   => present,
		charset  => 'utf8',
		provider => 'mysql',
		require  => Class['mysql::server'],
	}

	database { 'zodb_session':
		ensure   => present,
		charset  => 'utf8',
		provider => 'mysql',
		require  => Class['mysql::server'],
	}

	database { 'zenoss_zep':
		ensure   => present,
		charset  => 'utf8',
		provider => 'mysql',
		require  => Class['mysql::server'],
	}

	database_user { "${zenoss_db_user}@${zenoss_db_host}":
		ensure        => present,
		password_hash => mysql_password($zenoss_db_password),
		provider      => 'mysql',
		require       => Class['mysql::server'],
	}

	database_grant { "${zenoss_db_user}@${zenoss_db_host}/zodb":
		privileges => ['all'],
		provider   => 'mysql',
		require    => [ database_user["${zenoss_db_user}@${zenoss_db_host}"], database["zodb"] ],
	}

	database_grant { "${zenoss_db_user}@${zenoss_db_host}/zodb_session":
		privileges => ['all'],
		provider   => 'mysql',
		require    => [ database_user["${zenoss_db_user}@${zenoss_db_host}"], database["zodb_session"] ],
	}

	database_grant { "${zenoss_db_user}@${zenoss_db_host}/zenoss_zep":
		privileges => ['all'],
		provider   => 'mysql',
		require    => [ database_user["${zenoss_db_user}@${zenoss_db_host}"], database["zenoss_zep"] ],
	}

	# Configure the RabbitMQ instance

	$zenoss_mq_user = 'zenoss'
	$zenoss_mq_password = 'zenoss'

    rabbitmq_user { $zenoss_mq_user:
      admin    => true,
      password => $zenoss_mq_password,
      provider => 'rabbitmqctl',
    }

    rabbitmq_vhost { "zenoss":
      ensure   => present,
      provider => 'rabbitmqctl',
    }

    rabbitmq_user_permissions { "${zenoss_mq_user}@zenoss":
      configure_permission => '.*',
      read_permission      => '.*',
      write_permission     => '.*',
      provider 			   => 'rabbitmqctl',
    }


	# Install Zenoss Core 4

	$zenoss_url = "http://sourceforge.net/projects/zenoss/files/zenoss-4.2/zenoss-4.2.0/zenoss-4.2.0.el6.x86_64.rpm/download"

	exec { "download-zenoss-core-4":
		command => "/usr/bin/wget -O /var/tmp/zenoss-4.2.0.rpm $zenoss_url",
		creates => "/var/tmp/zenoss-4.2.0.rpm",
	}

	package { "zenoss":
		ensure   => installed,
		source   => "/var/tmp/zenoss-4.2.0.rpm",
		require  => [ 
			Exec["download-zenoss-core-4"], 
			Package[
				"liberation-fonts-common",
				"liberation-mono-fonts",
				"liberation-sans-fonts",
				"liberation-serif-fonts",
				"libgcj",
				"nagios-plugins",
				"net-snmp-utils",
				"rrdtool"
			],
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
		ensure => installed,
		source => $zenpacks_url,
		require => Package["zenoss"],
	}
}