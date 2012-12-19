class zenoss::install::deps::jdk () {

	# Zenoss wont run with OpenJDK at all. Remove it.
	
	package { "java-1.6.0-openjdk":
		ensure => absent,
	}

	package { "wget":
	  ensure => installed,
	}

	## Oracle JDK 1.6 update 33

	$jdk_platform = $::osfamily ? {
		'windows' => 'windows',
		default => 'linux'
	}

	$jdk_architecture = $::architecture ? {
		'x86_64' => 'x64'
	}

	$jdk_suffix = $::osfamily ? {
		'windows' => '.exe',
		default   => '.bin'
	}

	#sudo wget -c --no-cookies --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F" "http://download.oracle.com/otn-pub/java/jdk/6u33-b04/jdk-6u33-linux-x64-rpm.bin" --output-document "/var/tmp/jdk-6u33-linux-x64-rpm.bin"


  # TODO: Make it work with other platforms.
	$jdk_package = "-rpm"

	$jdk_url_root = "http://download.oracle.com/otn-pub/java/jdk"
	$jdk_release = "6u33"
	$jdk_release_dir = "6u33-b04"
	$jdk_file = "jdk-$jdk_release-$jdk_platform-$jdk_architecture$jdk_package$jdk_suffix"

	$jdk_url = "http://download.oracle.com/otn-pub/java/jdk/$jdk_release_dir/$jdk_file"


	exec { "download-jdk":
		command => "/usr/bin/wget -c --no-cookies --header 'Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F' --output-document /var/tmp/$jdk_file $jdk_url",
		creates => "/var/tmp/$jdk_file",
		require => Package["wget"],
	}

  package { "unzip":
    ensure => installed,
  }

	exec { "extract-jdk":
	  command => "/usr/bin/unzip -o /var/tmp/$jdk_file -d /var/tmp/jdk_extracted",
	  creates => "/var/tmp/jdk_extracted/jdk-6u33-linux-amd64.rpm",
	  require => [ Package["unzip"], Exec["download-jdk"] ],
	}

	#exec { "install-jdk":
	#	require => Exec["extract-jdk"],
	# 	command => "/usr/bin/yum -y -d0 install /var/tmp/jdk_extracted/jdk-6u33-linux-amd64.rpm",
	#  unless => "/bin/rpm -q jdk"
	#}

	package { "jdk":
	  ensure   => installed,
	  source   => "/var/tmp/jdk_extracted/$jdk_file",
	  provider => rpm,
	  require  => Exec[ "extract-jdk" ],
	}



}