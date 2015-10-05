# TODO: cleanup unused variables

$admin_password = 'rajalokan'
$demo_password = $admin_password
$admin_token = '4b46b807-ab35-4a67-9f5f-34bbff2dd439'
$region_name = 'RegionOne'


$interface = 'eth0'
$ext_bridge_interface = 'br-ex'
$dns_nameservers = ['8.8.8.8', '8.8.4.4']
$private_subnet_cidr = '10.0.0.0/24'
$public_subnet_cidr = '192.168.209.0/24'
$public_subnet_gateway = '192.168.209.2'
$public_subnet_allocation_pools = ['start=192.168.209.30,end=192.168.209.50']

# Note: this is executed on the master
$gateway = generate('/bin/sh',
'-c', '/sbin/ip route show | /bin/grep default | /usr/bin/awk \'{print $3}\'')

$ext_bridge_interface_repl = regsubst($ext_bridge_interface, '-', '_')
$ext_bridge_interface_ip = inline_template("<%= scope.lookupvar('::ipaddress_${ext_bridge_interface_repl}') -%>")

if $ext_bridge_interface_ip {
  $local_ip = $ext_bridge_interface_ip
  $local_ip_netmask = inline_template("<%= scope.lookupvar('::netmask_${ext_bridge_interface_repl}') -%>")
} else {
  $local_ip = inline_template("<%= scope.lookupvar('::ipaddress_${interface}') -%>")
  $local_ip_netmask = inline_template("<%= scope.lookupvar('::netmask_${interface}') -%>")
}

if !$local_ip {
  fail('$local_ip variable must be set')
}

class { '::mysql::server': }

class { 'keystone::db::mysql':
  password      => $admin_password,
  allowed_hosts => '%',
}

class { 'keystone':
  verbose               => True,
  package_ensure        => latest,
  client_package_ensure => latest,
  catalog_type          => 'sql',
  admin_token           => $admin_token,
  database_connection   => "mysql://keystone:${admin_password}@${local_ip}/keystone",
}

# Installs the service user endpoint.
class { 'keystone::endpoint':
  public_url   => "http://${local_ip}:5000",
  admin_url    => "http://${local_ip}:35357",
  internal_url => "http://${local_ip}:5000",
  region       => $region_name,
}

keystone_tenant { 'admin':
  ensure  => present,
  enabled => True,
}

keystone_tenant { 'services':
  ensure  => present,
  enabled => True,
}

keystone_tenant { 'demo':
  ensure => present,
}

keystone_user { 'admin':
  ensure   => present,
  enabled  => True,
  password => $admin_password,
  email    => 'admin@openstack',
}

keystone_user { 'demo':
  ensure   => present,
  enabled  => True,
  password => $demo_password,
  email    => 'demo@openstack',
}

keystone_role { 'admin':
  ensure => present,
}

keystone_role { 'demo':
  ensure => present,
}

keystone_user_role { 'admin@admin':
  ensure => present,
  roles  => ['admin'],
}

keystone_user_role { 'admin@services':
  ensure => present,
  roles  => ['admin'],
}

keystone_user_role { 'demo@demo':
  ensure => present,
  roles  => ['demo'],
}

######## Keystone files to be sourced

file { '/home/okan/keystonerc_admin':
  ensure  => present,
  content =>
"export OS_AUTH_URL=http://${local_ip}:35357/v2.0
export OS_USERNAME=admin
export OS_PASSWORD=${admin_password}
export OS_TENANT_NAME=admin
export OS_VOLUME_API_VERSION=2
",
}

file { '/home/okan/keystonerc_demo':
  ensure  => present,
  content =>
"export OS_AUTH_URL=http://${local_ip}:35357/v2.0
export OS_USERNAME=demo
export OS_PASSWORD=${demo_password}
export OS_TENANT_NAME=demo
export OS_VOLUME_API_VERSION=2
",
}
