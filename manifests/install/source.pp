# Install zenoss core from source repository
# The build process is fairly complex so, this could become a non option due to the support nightmare :)

class zenoss::install::source(
	$install_dir = "/usr/local/zenoss", 
	$source_repo = "http://dev.zenoss.org/svn/branches/zenoss-3.0.x/inst"
) {
	
	package { "gcc":
		ensure => installed,
	}
	
	package { "g++":
		ensure => installed,
	}
	
	package { "binutils":
		ensure => installed,
	}
	
	package { "make":
		ensure => installed,
	}
	
	package { "swig":
		ensure => installed,
	}
	
	package { "autoconf":
		ensure => installed,
	}
	
	# Install MySQL 5.0.x
	
	
	# Configure zenoss daemon user and user environment
	
	group { "zenoss":
		ensure => present,
	}
	
	$home_base_dir = $operatingsystem ? {
		'Darwin' => "/Users", 
		default  => "/home",
	}
	
	user { "zenoss":
		ensure  => present,
		comment => "Zenoss Core Daemon User",
		gid     => "zenoss",
		home    => "{$home_base_dir}/zenoss",
		require => Group["zenoss"],
	}
	
	file { "{$home_base_dir}/zenoss":
		ensure  => directory,
		owner   => "zenoss",
		group   => "zenoss",
		mode    => 0755,
		require => User["zenoss"], 
	}
	
	file { "{$home_base_dir}/zenoss/.profile":
		ensure	=> present,
		content => template('zenoss/zenoss_bash_profile.erb'),
		owner   => "zenoss",
		group   => "zenoss",
		mode    => 0600,
		require => File["{$home_base_dir/zenoss}"],
	}
	
	# Install zenoss core from source repository
	
	file { $install_dir:
		ensure => directory,
		owner  => "zenoss",
		group  => "zenoss",
		mode   => 0755,
	}
	
	vcsrepo { "{$install_dir}/zenossinst":
		ensure   => latest,
		require  => File["install_dir"],
		source   => $source_repo,
		provider => svn,
	}
	
	# Install script creates several tables and triggers, and requires "SUPER" permission
	exec { "{$install_dir}/zenossinst/install.sh":
		cwd         => "{$install_dir}/zenossinst",
		environment => "SVNTAG=branches/zenoss-3.0.x",
		group       => "zenoss",
		require     => Vcsrepo["{$install_dir}/zenossinst"],
	}
	
	# Set zope.conf if you want to modify the listen port for zenoss
	
	# zensocket needs setuid to open raw sockets
	# TODO: only if already installed?
	file { "{$install_dir}/bin/zensocket":
		owner => "root",
		group => "zenoss",
		mode  => 04750,
	}
	
	# TODO: init service?
	service { "zenoss":
		start  => "{$install_dir}/bin/zenoss start",
		stop   => "{$install_dir}/bin/zenoss stop",
		status => "{$install_dir}/bin/zenoss status",
	}
}