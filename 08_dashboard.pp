$admin_password = 'rajalokan'

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
package { 'openstack-dashboard-ubuntu-theme':
  ensure => absent,
}
~> Service['apache2']
