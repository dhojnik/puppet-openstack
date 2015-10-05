$admin_password = 'rajalokan'
$demo_password = $admin_password
$admin_token = '4b46b807-ab35-4a67-9f5f-34bbff2dd439'
$metadata_proxy_shared_secret = '39c24deb-0d57-4184-81da-fc8ede37082e'
$region_name = 'RegionOne'

$cinder_lvm_loopback_device_size_mb = 10 * 1024

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

$cinder_loopback_base_dir = '/var/lib/cinder'
$cinder_loopback_device_file_name = "${cinder_loopback_base_dir}/\
cinder-volumes.img"
$cinder_lvm_vg = 'cinder-volumes'
$workers = $::processorcount

if !$local_ip {
  fail('$local_ip variable must be set')
}

######## Horizon

package { 'apache2':
  ensure => latest,
}

service { 'apache2':
    ensure  => running,
    enable  => true,
    require => Package['apache2'],
}

class { 'memcached':
  listen_ip => '127.0.0.1',
  tcp_port  => '11211',
  udp_port  => '11211',
}
->
package { 'openstack-dashboard':
  ensure => latest,
}
->
file_line { 'dashboard_openstack_host':
  ensure => present,
  path   => '/etc/openstack-dashboard/local_settings.py',
  line   => "OPENSTACK_HOST = '${local_ip}'",
  match  => '^OPENSTACK_HOST\s=.*',
}
->
file_line { 'dashboard_default_role':
  ensure => present,
  path   => '/etc/openstack-dashboard/local_settings.py',
  line   => 'OPENSTACK_KEYSTONE_DEFAULT_ROLE = \'user\'',
  match  => '^OPENSTACK_KEYSTONE_DEFAULT_ROLE\s=.*',
}
->
exec { 'get-openstack-dashboard-theme':
  command => 'wget -q https://github.com/cloudbase/horizon-cloudbase/releases/\
download/2015.1.1/openstack-dashboard-cloudbase-theme.deb -O \
/tmp/openstack-dashboard-cloudbase-theme.deb',
  unless  => [ 'test -f /tmp/openstack-dashboard-cloudbase-theme.deb' ],
  path    => [ '/usr/bin/', '/bin' ],
}
->
package { 'openstack-dashboard-ubuntu-theme':
  ensure => absent,
}
->
package { 'openstack-dashboard-cloudbase-theme':
  ensure   => latest,
  provider => dpkg,
  source   => '/tmp/openstack-dashboard-cloudbase-theme.deb'
}
~> Service['apache2']


