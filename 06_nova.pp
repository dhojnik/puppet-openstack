$admin_password = 'rajalokan'
$metadata_proxy_shared_secret = '39c24deb-0d57-4184-81da-fc8ede37082e'
$region_name = 'RegionOne'
$interface = 'eth0'
$ext_bridge_interface = 'br-ex'
$ext_bridge_interface_repl = regsubst($ext_bridge_interface, '-', '_')
$ext_bridge_interface_ip = inline_template("<%= scope.lookupvar('::ipaddress_${ext_bridge_interface_repl}') -%>")

if $ext_bridge_interface_ip {
  $local_ip = $ext_bridge_interface_ip
  $local_ip_netmask = inline_template("<%= scope.lookupvar('::netmask_${ext_bridge_interface_repl}') -%>")
} else {
  $local_ip = inline_template("<%= scope.lookupvar('::ipaddress_${interface}') -%>")
  $local_ip_netmask = inline_template("<%= scope.lookupvar('::netmask_${interface}') -%>")
}

$workers = $::processorcount

if !$local_ip {
  fail('$local_ip variable must be set')
}

######## Nova

keystone_service { 'nova':
  ensure      => present,
  type        => 'compute',
  description => 'Openstack Compute Service',
}

keystone_endpoint { "${region_name}/nova":
  ensure       => present,
  public_url   => "http://${local_ip}:8774/v2/%(tenant_id)s",
  admin_url    => "http://${local_ip}:8774/v2/%(tenant_id)s",
  internal_url => "http://${local_ip}:8774/v2/%(tenant_id)s",
}

keystone_user { 'nova':
  ensure   => present,
  enabled  => True,
  password => $admin_password,
  email    => 'nova@openstack',
}

keystone_user_role { 'nova@services':
  ensure => present,
  roles  => ['admin'],
}

class { 'nova':
  database_connection =>"mysql://nova:${admin_password}@${local_ip}/nova?charset=utf8",
  rabbit_userid       => 'openstack',
  rabbit_password     => $admin_password,
  image_service       => 'nova.image.glance.GlanceImageService',
  glance_api_servers  => "${local_ip}:9292",
  verbose             => true,
  rabbit_host         => $local_ip,
}

class { '::mysql::server': }

class { 'nova::db::mysql':
  password      => $admin_password,
  allowed_hosts => '%',
}

class { 'nova::api':
  enabled                              => true,
  auth_uri                             => "http://${local_ip}:5000/v2.0",
  identity_uri                         => "http://${local_ip}:35357",
  admin_user                           => 'nova',
  admin_password                       => $admin_password,
  admin_tenant_name                    => 'services',
  neutron_metadata_proxy_shared_secret => $metadata_proxy_shared_secret,
  osapi_compute_workers                => $api_workers,
  ec2_workers                          => $api_workers,
  metadata_workers                     => $api_workers,
  #ratelimits                          =>
  #'(POST, "*", .*, 10, MINUTE);\
  #(POST, "*/servers", ^/servers, 50, DAY);\
  #(PUT, "*", .*, 10, MINUTE)',
  validate                             => true,
}

class { 'nova::network::neutron':
  neutron_admin_password  => $admin_password,
}

class { 'nova::scheduler':
  enabled => true,
}

class { 'nova::conductor':
  enabled => true,
  workers => $api_workers,
}

class { 'nova::consoleauth':
  enabled => true,
}

class { 'nova::cert':
  enabled => true,
}

class { 'nova::objectstore':
  enabled => true,
}

class { 'nova::compute':
  enabled           => true,
  vnc_enabled       => true,
  vncproxy_host     => $local_ip,
  vncproxy_protocol => 'http',
  vncproxy_port     => '6080',
}

class { 'nova::vncproxy':
  enabled           => true,
  host              => '0.0.0.0',
  port              => '6080',
  vncproxy_protocol => 'http',
}

class { 'nova::compute::libvirt':
  migration_support => true,
  # Narrow down listening if not needed for troubleshooting
  vncserver_listen  => '0.0.0.0',
  libvirt_virt_type => 'qemu',
}

