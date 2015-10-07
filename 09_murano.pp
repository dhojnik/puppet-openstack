$admin_password="rajalokan"

class { 'apt': }

apt::source { 'nectar-ubuntu':
    location            => "http://download.rc.nectar.org.au/nectar-ubuntu",
    repos               => "main",
    release             => "trusty-kilo-testing",
    include_src         => false,
}
->
exec { 'add-key':
    command             => "/usr/bin/wget -qO - http://download.rc.nectar.org.au/nectar-custom.gpg | sudo apt-key add -"
}

#class { "::mysql::server": }
#
#class { "murano::db::mysql":
#    passwor
#
##exec { 'apt-update':
##    command             => "/usr/bin/apt-get update"
##}
##-> Package <| |>
##
class { "murano":
    verbose             => true,
    admin_password      => $admin_password,
    package_ensure      => 'latest',
    rabbit_os_host      => "192.168.19.2",
    rabbit_os_port      => "5672",
    rabbit_os_user      => "openstack",
    rabbit_os_password  => $admin_password,
}
$admin_password="rajalokan"
$region_name="RegionOne"
$local_ip="192.168.19.2"


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
#
#keystone_service { 'murano':
#  ensure        => present,
#  type          => 'application_catalog',
#  description   => "Application Catalog Service",
#}
#
#keystone_endpoint { "${region_name}/application_catalog":
#  ensure        => present,
#  public_url    => "http://${local_ip}:8082",
#  admin_url     => "http://${local_ip}:8082",
#  internal_url  => "http://${local_ip}:8082",
#}
#
#keystone_user { 'murano':
#  ensure        => present,
#  enabled       => True,
#  password      => $admin_password,
#  email         => 'murano@openstack',
#}
#
#keystone_user_role { 'murano@services':
#  ensure        => present,
#  roles         => ['admin'],
#}
#
#class { "::mysql::server": }
#
#class { "murano::db::mysql":
#    passwor
#
class { "murano":
    verbose             => true,
    admin_password      => $admin_password,
    package_ensure      => 'latest',
    rabbit_os_host      => "${local_ip}",
    rabbit_os_port      => "5672",
    rabbit_os_user      => "openstack",
    rabbit_os_password  => $admin_password,
    rabbit_own_host     => "${local_ip}",
    rabbit_own_user     => "openstack",
    rabbit_own_password => $admin_password,
    auth_uri            => "${local_ip}:5000/v2.0/",
    identity_uri        => "${local_ip}:35357/v2.0",
    service_host        => "${local_ip}",
    database_connection => "mysql://murano:$admin_password@${local_ip}:3306/murano",
}

class { 'murano::api':
    host                => "${local_ip}",
}

class { 'murano::engine': }
