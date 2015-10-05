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
