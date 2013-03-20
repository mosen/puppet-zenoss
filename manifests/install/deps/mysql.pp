# Zenoss Core 4.2 Requires MySQL >= 5.5.13
# EPEL and RPMforge do not carry MySQL >= 5.1, I use Les RPMS de Remi
# MariaDB 5.5 may be an option. TODO: Percona seems to work perfectly for this

class zenoss::install::deps::mysql (
  # Pretty often you will have MySQL defined elsewhere, so there is the option to omit that installation if $install == false
  $install = true,
  $mysql_root_password = 'zenoss',

  # MySQL Configuration for Zenoss User
  $zenoss_db_host = 'localhost',
  $zenoss_db_user = 'zenoss',
  $zenoss_db_password = 'zenoss',

){

  if ($install) {

    class { 'mysql::server':
      config_hash => { 'root_password' => $mysql_root_password },
      require     => Yumrepo['remi'], # Using the remi repo ensures that v5.5 is installed instead of v5.1
    }

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

	# Remi RPMS provided most dependencies except mysql-shared
	# which i wgetted from wget http://cdn.mysql.com/Downloads/MySQL-5.5/MySQL-shared-5.5.27-1.el6.x86_64.rpm
}