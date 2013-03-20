# This class provides configuration of a Zenoss Core installation whether you used this module or not to install
# it in the first place. The module assumes that you have already done the installation at this stage.
class zenoss (

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

  # Open up firewall ports for Zenoss and related services
  if ($open_firewall) {
    include zenoss::install::firewall
  }

  # Implicit dependency: Package["zenoss"]
	file { "/opt/zenoss/etc/global.conf":
		ensure  => present,
		content => template('zenoss/global.conf.erb'),
		notify  => Service["zenoss"],
	}

  # Beware that init+puppet isn't all that good at determining whether the entire group of zenoss services are running.
  # Implicit dependency: Package["zenoss"]
  service { "zenoss":
    ensure  => running,
    require => [
      File[ "/opt/zenoss/etc/global.conf" ],
      User[ $zenoss_user ],
      Database[ 'zodb' ],
      Database[ 'zodb_session' ],
      Database[ 'zenoss_zep' ],
      Database_user[ "${zenoss_db_user}@${zenoss_db_host}" ],
      Database_grant[ "${zenoss_db_user}@${zenoss_db_host}/zodb" ],
      Database_grant[ "${zenoss_db_user}@${zenoss_db_host}/zodb_session" ],
      Database_grant[ "${zenoss_db_user}@${zenoss_db_host}/zenoss_zep" ],
      Rabbitmq_user[ $zenoss_mq_user ],
      Rabbitmq_vhost[ "zenoss" ],
      Rabbitmq_user_permissions[ "${zenoss_mq_user}@zenoss" ]
    ],
  }

  # Create the user that zenoss daemons will run as

  user { $zenoss_user:
    ensure => present,
    # TODO: password
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

  # Implicit dependency: Package["rabbitmq-server"]
 	service { "rabbitmq-server":
 	  ensure  => running,
 	}

  rabbitmq_user { $zenoss_mq_user:
    admin    => true,
    password => $zenoss_mq_password,
    provider => 'rabbitmqctl',
    require  => Service["rabbitmq-server"],
  }

  rabbitmq_vhost { "zenoss":
    ensure   => present,
    require  => Service["rabbitmq-server"],
    provider => 'rabbitmqctl',
  }

  rabbitmq_user_permissions { "${zenoss_mq_user}@zenoss":
    configure_permission => '.*',
    read_permission      => '.*',
    write_permission     => '.*',
    require              => Service["rabbitmq-server"],
    provider 			       => 'rabbitmqctl',
  }


}