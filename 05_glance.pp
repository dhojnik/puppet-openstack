$admin_password = 'rajalokan'
$region_name = 'RegionOne'

$interface = 'eth0'
$ext_bridge_interface = 'br-ex'

$ext_bridge_interface_repl = regsubst($ext_bridge_interface, '-', '_')
$ext_bridge_interface_ip = inline_template(
"<%= scope.lookupvar('::ipaddress_${ext_bridge_interface_repl}') -%>")

if $ext_bridge_interface_ip {
  $local_ip = $ext_bridge_interface_ip
  $local_ip_netmask = inline_template(
"<%= scope.lookupvar('::netmask_${ext_bridge_interface_repl}') -%>")
} else {
  $local_ip = inline_template(
"<%= scope.lookupvar('::ipaddress_${interface}') -%>")
  $local_ip_netmask = inline_template(
"<%= scope.lookupvar('::netmask_${interface}') -%>")
}

$workers = $::processorcount

if !$local_ip {
  fail('$local_ip variable must be set')
}

######## Glance

# TODO: Fix deprecation warnings

class { 'glance::api':
  verbose             => true,
  keystone_tenant     => 'services',
  keystone_user       => 'glance',
  keystone_password   => $admin_password,
  database_connection => "mysql://glance:${admin_password}@${local_ip}/glance",
  workers             => $api_workers,
}

class { 'glance::registry':
  verbose             => true,
  keystone_tenant     => 'services',
  keystone_user       => 'glance',
  keystone_password   => $admin_password,
  database_connection => "mysql://glance:${admin_password}@${local_ip}/glance",
  # Added after kilo
  #workers             => $api_workers,
}

class { 'glance::backend::file': }

class { '::mysql::server': }

class { 'glance::db::mysql':
  password      => $admin_password,
  allowed_hosts => '%',
}

class { 'glance::keystone::auth':
  password     => $admin_password,
  email        => 'glance@example.com',
  public_url   => "http://${local_ip}:9292",
  admin_url    => "http://${local_ip}:9292",
  internal_url => "http://${local_ip}:9292",
  region       => $region_name,
}

class { 'glance::notify::rabbitmq':
  rabbit_password => $admin_password,
  rabbit_userid   => 'openstack',
  rabbit_hosts    => ["${local_ip}:5672"],
  rabbit_use_ssl  => false,
}

keystone_user_role { 'glance@services':
  ensure => present,
  roles  => ['admin'],
}

exec { 'retrieve_cirros_image':
  command => 'wget -q http://download.cirros-cloud.net/0.3.4/\
cirros-0.3.4-x86_64-disk.img -O /tmp/cirros-0.3.4-x86_64-disk.img',
  unless  => [ "glance --os-username admin --os-tenant-name admin \
--os-password ${admin_password} --os-auth-url http://${local_ip}:35357/v2.0 \
image-show cirros-0.3.4-x86_64" ],
  path    => [ '/usr/bin/', '/bin' ],
  require => [ Class['glance::api'], Class['glance::registry'] ]
}
->
exec { 'add_cirros_image':
  command => "glance --os-username admin --os-tenant-name admin --os-password \
${admin_password} --os-auth-url http://${local_ip}:35357/v2.0 image-create \
--name cirros-0.3.4-x86_64 --file /tmp/cirros-0.3.4-x86_64-disk.img \
--disk-format qcow2 --container-format bare --is-public True",
  # Avoid dependency warning
  onlyif  => [ 'test -f /tmp/cirros-0.3.4-x86_64-disk.img' ],
  path    => [ '/usr/bin/', '/bin' ],
}
->
file { '/tmp/cirros-0.3.4-x86_64-disk.img':
  ensure => absent,
}
