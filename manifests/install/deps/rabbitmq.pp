# This class depends on puppetlabs/rabbitmq
# CentOS 6.3 does not have a repo for the required RabbitMQ version >= 2.8
# so we have to install directly from RabbitMQ
class zenoss::install::deps::rabbitmq {


	# Zenoss Core Recommends removing matahari to use RabbitMQ
	# TODO : Stop matahari first

	package { "matahari-agent-lib":
		ensure => absent,
	}

	package { "matahari-sysconfig":
		ensure => absent,
	}

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

	package { "matahari":
		ensure => absent,
	}

	# Zenoss Core Recommends removing qpid/matahari to use RabbitMQ

  service { "qpid":
    ensure => stopped,
  }

	package { "qpid-qmf":
		ensure  => absent,
		require => Service['qpid'],
	}

	package { "qpid-cpp-client-ssl":
		ensure => absent,
		require => Package["qpid-qmf"],
	}

	package { "qpid-cpp-server-ssl":
		ensure => absent,
		require => Package["matahari-broker"],
	}

	package { "qpid-cpp-client":
		ensure => absent,
		require => Package["qpid-cpp-client-ssl", "qpid-qmf", "qpid-cpp-server"],
	}

	package { "qpid-cpp-server":
		ensure => absent,
		require => Package["qpid-cpp-server-ssl"],
	}


	# Zenoss Core Requires RabbitMQ which depends on erlang

  package { "erlang":
    ensure => installed,
 	}

 	package { "rabbitmq-server":
 	  ensure   => "3.0.1-1",
 	  source   => "http://www.rabbitmq.com/releases/rabbitmq-server/v3.0.1/rabbitmq-server-3.0.1-1.noarch.rpm",
 	  provider => rpm,
 	}

  # RabbitMQ fails to start on my vagrant guest when DNS does not resolve the local hostname

  #class { 'rabbitmq::server':
  #  port              => '5673',
  #  delete_guest_user => true,
  #  require           => Package["rabbitmq-server"], # Use our manual package installation instead of the Repo copy
  #}


}