$admin_password = 'rajalokan'

######## RabbitMQ

# TODO: fix warnings

class { '::rabbitmq':
  service_ensure    => 'running',
  port              => '5672',
  delete_guest_user => true,
}

rabbitmq_user { 'openstack':
  admin    => false,
  password => $admin_password,
  tags     => ['openstack'],
}

rabbitmq_vhost { '/':
  ensure => present,
}

rabbitmq_user_permissions { 'openstack@/':
  configure_permission => '.*',
  read_permission      => '.*',
  write_permission     => '.*',
}
