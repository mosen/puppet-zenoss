# Zenoss Core 4.2 Requires MySQL >= 5.5.13
class zenoss::install::deps::mysql (
  # Sometimes MySQL will be installed by a different Resource, so there is the option to simply configure the Zenoss parts
  $install = true,
  $mysql_root_password = 'zenoss',

  # MySQL Configuration for Zenoss User
  $zenoss_db_host = 'localhost',
  $zenoss_db_user = 'zenoss',
  $zenoss_db_password = 'zenoss',

){

  if ($install) {
    class { 'mysql::server':
      config_hash => { 'root_password' => $mysql_root_password }
    }

    #class { 'mysql::client': }
  }

  Database {
    require => Class['mysql::server'],
  }

	# Zenoss wont run with MySQL < 5.5
	# TODO : Check for MySQL < 5.5 and raise error
	# Zenoss recommends setting my.cnf
	#[mysqld]
	# max_allowed_packet=16M
	# innodb_buffer_pool_size=256M
	# innodb_additional_mem_pool_size=20M



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




	# Remi RPMS provided most dependencies except mysql-shared
	# which i wgetted from wget http://cdn.mysql.com/Downloads/MySQL-5.5/MySQL-shared-5.5.27-1.el6.x86_64.rpm
}