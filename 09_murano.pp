$admin_password="rajalokan"

class { "murano":
    verbose             => true,
    admin_password      => $admin_password,
    package_ensure      => 'latest',
    rabbit_os_host      => "192.168.19.2",
    rabbit_os_port      => "5672",
    rabbit_os_user      => "openstack",
    rabbit_os_password  => $admin_password,
}
