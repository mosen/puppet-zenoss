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
  #http://download.oracle.com/otn-pub/java/jdk/6u38-b05/jre-6u38-linux-x64-rpm.bin
  # unzip creates jre-6u38-linux-amd64.rpm

  # TODO: Make it work with other platforms.
	$jdk_or_jre = "jre"
	$jdk_package = "-rpm"

	$jdk_url_root = "http://download.oracle.com/otn-pub/java/jdk"
	$jdk_release = "6u38"
	$jdk_release_dir = "6u38-b05"
	$jdk_file = "$jdk_or_jre-$jdk_release-$jdk_platform-$jdk_architecture$jdk_package$jdk_suffix"
	$jdk_file_extracted = "$jdk_or_jre-$jdk_release-$jdk_platform-amd64.rpm"

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
	  creates => "/var/tmp/jdk_extracted/$jdk_file_extracted", # TODO downloaded file is x64, extracted is amd64
	  returns => [ 0, 1 ], # Will return 1 if the file header is not actually ZIP content (which it isnt, but works anyway).
	  require => [ Package["unzip"], Exec["download-jdk"] ],
	}

	#exec { "install-jdk":
	#	require => Exec["extract-jdk"],
	# 	command => "/usr/bin/yum -y -d0 install /var/tmp/jdk_extracted/jdk-6u33-linux-amd64.rpm",
	#  unless => "/bin/rpm -q jdk"
	#}

	package { "$jdk_or_jre":
	  ensure   => installed,
	  source   => "/var/tmp/jdk_extracted/$jdk_file_extracted",
	  provider => rpm,
	  require  => Exec[ "extract-jdk" ],
	}



}