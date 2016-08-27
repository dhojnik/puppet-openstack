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

$dns_nameservers = ['8.8.8.8', '8.8.4.4']

$private_subnet_cidr = '10.0.0.0/24'
$public_subnet_cidr = '192.168.90.0/24'
$public_subnet_gateway = '192.168.90.1'
$public_subnet_allocation_pools = ['start=192.168.90.30,end=192.168.90.50']

# Note: this is executed on the master
$gateway = generate('/bin/sh', '-c', '/sbin/ip route show | /bin/grep default | /usr/bin/awk \'{print $3}\'')

$workers = $::processorcount

if !$local_ip {
  fail('$local_ip variable must be set')
}

######## Neutron

keystone_service { 'neutron':
  ensure      => present,
  type        => 'network',
  description => 'Openstack Networking Service',
}

keystone_endpoint { "${region_name}/neutron":
  ensure       => present,
  public_url   => "http://${local_ip}:9696",
  admin_url    => "http://${local_ip}:9696",
  internal_url => "http://${local_ip}:9696",
}

keystone_user { 'neutron':
  ensure   => present,
  enabled  => True,
  password => $admin_password,
  email    => 'neutron@openstack',
}

keystone_user_role { 'neutron@services':
  ensure => present,
  roles  => ['admin'],
}

class { '::neutron':
  enabled               => true,
  bind_host             => '0.0.0.0',
  rabbit_host           => $local_ip,
  rabbit_user           => 'openstack',
  rabbit_password       => $admin_password,
  verbose               => true,
  debug                 => false,
  core_plugin           => 'ml2',
  service_plugins       => ['router', 'metering'],
  allow_overlapping_ips => true,
}

class { 'neutron::server':
  auth_uri            => "http://${local_ip}:5000/v2.0",
  database_connection => "mysql://neutron:${admin_password}@${local_ip}/neutron?charset=utf8",
  sync_db             => true,
  api_workers         => $api_workers,
  rpc_workers         => $api_workers,
}

class { '::mysql::server': }

class { 'neutron::db::mysql':
  password      => $admin_password,
  allowed_hosts => '%',
}

class { '::neutron::server::notifications':
  nova_admin_tenant_name => 'services',
  nova_admin_password    => $admin_password,
}

class { '::neutron::agents::ml2::ovs':
  local_ip         => $local_ip,
  enable_tunneling => true,
  tunnel_types     => ['gre', 'vxlan'],
  bridge_mappings  => ['physnet1:br-ex'],
}
->
vs_port { 'eth0':
  ensure => present,
  bridge => 'br-ex',
}
->
network::interface { 'br-ex':
  ipaddress       => $local_ip,
  netmask         => $local_ip_netmask,
  gateway         => $gateway,
  dns_nameservers => join($dns_nameservers, ' '),
}

Vs_port['eth0']
->
network::interface { 'eth0':
  method => 'manual',
  up     => [ 'ifconfig $IFACE 0.0.0.0 up', 'ip link set $IFACE promisc on' ],
  down   => [ 'ip link set $IFACE promisc off', 'ifconfig $IFACE down' ],
}

vs_bridge { 'br-int':
  ensure => present,
}

vs_bridge { 'br-tun':
  ensure => present,
}

class { '::neutron::plugins::ml2':
  type_drivers         => ['flat', 'vlan', 'gre', 'vxlan'],
  tenant_network_types => ['flat', 'vlan', 'gre', 'vxlan'],
  vxlan_group          => '239.1.1.1',
  mechanism_drivers    => ['openvswitch'],
  flat_networks        => ['physnet1'],
  vni_ranges           => ['1001:2000'], #VXLAN
  tunnel_id_ranges     => ['1001:2000'], #GRE
  network_vlan_ranges  => ['physnet1:3001:4000'],
}

class { '::neutron::agents::l3':
  external_network_bridge  => 'br-ex',
  router_delete_namespaces => true,
}

class { '::neutron::agents::metadata':
  enabled       => true,
  shared_secret => $metadata_proxy_shared_secret,
  auth_user     => 'neutron',
  auth_password => $admin_password,
  auth_tenant   => 'services',
  auth_url      => "http://${local_ip}:35357/v2.0",
  auth_region   => $region_name,
  metadata_ip   => $local_ip,
}

class { '::neutron::agents::dhcp':
  enabled                => true,
  dhcp_delete_namespaces => true,
}

class { '::neutron::agents::lbaas':
  enabled => true,
}

class { '::neutron::agents::vpnaas':
  enabled => true,
}

class { '::neutron::agents::metering':
  enabled => true,
}

neutron_network { 'public':
  ensure                    => present,
  router_external           => 'True',
  tenant_name               => 'admin',
  provider_network_type     => 'flat',
  provider_physical_network => 'physnet1',
  shared                    => true,
}

neutron_subnet { 'public_subnet':
  ensure           => present,
  cidr             => $public_subnet_cidr,
  network_name     => 'public',
  tenant_name      => 'admin',
  enable_dhcp      => false,
  gateway_ip       => $public_subnet_gateway,
  allocation_pools => $public_subnet_allocation_pools,
}

neutron_network { 'private':
  ensure                => present,
  tenant_name           => 'demo',
  provider_network_type => 'vlan',
  shared                => false,
}

neutron_subnet { 'private_subnet':
  ensure          => present,
  cidr            => $private_subnet_cidr,
  network_name    => 'private',
  tenant_name     => 'demo',
  enable_dhcp     => true,
  dns_nameservers => $dns_nameservers,
}

neutron_router { 'demo_router':
  ensure               => present,
  tenant_name          => 'demo',
  gateway_network_name => 'public',
  require              => Neutron_subnet['public_subnet'],
}

neutron_router_interface { 'demo_router:private_subnet':
  ensure => present,
}
