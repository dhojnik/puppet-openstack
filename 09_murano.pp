$admin_password="rajalokan"
$region_name = 'RegionOne'

# Evaluate local_ip
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

######## Murano

#class { 'apt': }
#
#apt::source { 'nectar-ubuntu':
#    location            => "http://download.rc.nectar.org.au/nectar-ubuntu",
#    repos               => "main",
#    release             => "trusty-kilo-testing",
#    include_src         => false,
#}
#->
#exec { 'add-key':
#    command             => "/usr/bin/wget -qO - http://download.rc.nectar.org.au/nectar-custom.gpg | sudo apt-key add -"
#}
#->
#exec { 'apt-update':
#    command             => "/usr/bin/apt-get update"
#}
#-> Package <| |>

keystone_service { 'murano':
  ensure      => present,
  type        => 'application_catalog',
  description => 'Application Catalog Service',
}

#keystone_endpoint { "${region_name}/application_catalog":
#  ensure       => present,
#  public_url   => "http://${local_ip}:8774/v2/%(tenant_id)s",
#  admin_url    => "http://${local_ip}:8774/v2/%(tenant_id)s",
#  internal_url => "http://${local_ip}:8774/v2/%(tenant_id)s",
#}

keystone_user { 'murano':
  ensure   => present,
  enabled  => True,
  password => $admin_password,
  email    => 'murano@openstack',
}

keystone_user_role { 'murano@services':
  ensure => present,
  roles  => ['admin'],
}

#class { "murano":
#    verbose             => true,
#    database_connection => "mysql://murano:$admin_password@${local_ip}:3306/murano",
#}

class { '::mysql::server': }

class { 'murano::db::mysql':
  password      => $admin_password,
  allowed_hosts => '%',
}
