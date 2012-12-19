# This class depends on puppetlabs/rabbitmq
# Centos 6.3 does not have a repo for the required rabbitMQ version.
class zenoss::install::deps::rabbitmq {

	# Zenoss Core Requires RabbitMQ which depends on erlang

  package { "erlang":
    ensure => installed,
 	}


  # RabbitMQ fails to start on my vagrant guest when DNS does not resolve the local hostname
  class { 'rabbitmq::server':
    port              => '5673',
    delete_guest_user => true,
  }

  # Configure the RabbitMQ instance

  $zenoss_mq_user = 'zenoss'
  $zenoss_mq_password = 'zenoss'

  rabbitmq_user { $zenoss_mq_user:
    admin    => true,
    password => $zenoss_mq_password,
    provider => 'rabbitmqctl',
    require  => Class['rabbitmq::server'],
  }

  rabbitmq_vhost { "zenoss":
    ensure   => present,
    require  => Class['rabbitmq::server'],
    provider => 'rabbitmqctl',
  }

  rabbitmq_user_permissions { "${zenoss_mq_user}@zenoss":
    configure_permission => '.*',
    read_permission      => '.*',
    write_permission     => '.*',
    require              => Class['rabbitmq::server'],
    provider 			       => 'rabbitmqctl',
  }
}