$admin_password = 'rajalokan'
class { 'mysql::server':
  root_password    => $admin_password,
  override_options => { 'mysqld' => { 'bind_address'           => '0.0.0.0',
                                      # Not necessary starting from MySQL 5.5
                                      'default_storage_engine' => 'InnoDB',
                                      'max_connections'        => 1024,
                                      'open_files_limit'       => -1 } },
  restart          => true,
}


