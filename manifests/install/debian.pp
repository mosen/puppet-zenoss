class zenoss::install::debian {
	
	# Zenoss Repository
	apt::repository { "zenoss-stable":
		url        => "http://dev.zenoss.org/deb",
		distro     => "main",
		repository => "stable",
		source     => false,
	}

	package { "zenoss-stack":
		ensure => present,
		require => Apt::Repository["zenoss-stable"],
	}
	
	service { "zenoss-stack":
		ensure => running,
		require => Package["zenoss-stack"],
	}
}