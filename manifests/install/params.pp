# Zenoss Core 4 : Installation Parameters
class zenoss::install::params {

	# Open firewall ports associated with Zenoss Core, you will not be able to access the administrative interface if they are blocked.
	$open_firewall = true

	# Zenoss Core daemons will run as this user
	$zenoss_user = 'zenoss'
	$zenoss_password = 'zenoss'

	# Zenoss Core Web Application Data
	$zenoss_db_host = 'localhost'
	$zenoss_db_user = 'zenoss'
	$zenoss_db_password = 'zenoss'

	# Zenoss Core Event Server Data
	$zenoss_event_db_host = 'localhost'
	$zenoss_event_db_user = 'zenoss_zep' # cannot be identical to the zenoss_db_user parameter
	$zenoss_event_db_password = 'zenoss'

	# MySQL Administrator (zenoss will use this to create new databases on startup check)
	$zenoss_db_admin_user = 'root'
	$zenoss_db_admin_password = ''

	# Package will be fetched from this location
	$zenoss_version_short = '4.2'
	$zenoss_version = '${zenoss_version_short}.0'
	

	case $::osfamily {
		'redhat' : {
			$package_platform = $::lsbmajdistrelease ? {
				6 => 'el6',
				5 => 'rhel5'
			}

			$zenoss_package_name = "zenoss-${zenoss_version}.${package_platform}.${::architecture}.rpm"
		}
	}

	$zenoss_package_url = 'http://sourceforge.net/projects/zenoss/files/zenoss-${zenoss_version_short}/zenoss-${zenoss_version}/${zenoss_package_name}/download'


}