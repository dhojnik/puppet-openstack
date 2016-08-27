######## RabbitMQ

$admin_password = 'rajalokan'

package { 'rabbitmq-server':
  ensure                              => 'installed'
}

rabbitmq_user { 'openstack':
  admin                               => false,
  password                            => $admin_password,
  tags                                => ['openstack'],
}

rabbitmq_vhost { '/':
  ensure => present,
}

rabbitmq_user_permissions { 'openstack@/':
  configure_permission                => '.*',
  read_permission                     => '.*',
  write_permission                    => '.*',
}
