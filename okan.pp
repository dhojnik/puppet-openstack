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
$public_subnet_cidr = '192.168.167.0/24'
$public_subnet_gateway = '192.168.167.1'
$public_subnet_allocation_pools = ['start=192.168.167.151,end=192.168.167.200']

# Note: this is executed on the master
$gateway = generate('/bin/sh', '-c', '/sbin/ip route show | /bin/grep default | /usr/bin/awk \'{print $3}\'')

$workers = $::processorcount

if !$local_ip {
  fail('$local_ip variable must be set')
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

class { '::neutron::server':
  password              => "$admin_password",
  database_connection   => "mysql://neutron:${admin_password}@${local_ip}/neutron?charset=utf8",
  auth_uri              => "http://${local_ip}:5000/v2.0",
  auth_url              => "http://${local_ip}:35357/v2.0"
}


class { 'neutron::db::mysql':
  password      => $admin_password,
  allowed_hosts => '%',
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

class { '::neutron::agents::dhcp': }
class { '::neutron::agents::l3': }
class { '::neutron::agents::lbaas': }
class { '::neutron::agents::vpnaas': }
class { '::neutron::agents::metering': }

class { '::neutron::agents::metadata':
  enabled       => true,
  shared_secret => $metadata_proxy_shared_secret,
  metadata_ip   => $local_ip,
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
