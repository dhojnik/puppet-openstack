### Base

class { 'apt': }

package { 'ubuntu-cloud-keyring':
  ensure                              => 'installed'
}

apt::source { 'ubuntu-cloud':
  location                            =>  'http://ubuntu-cloud.archive.canonical.com/ubuntu',
  repos                               =>  'main',
  release                             =>  'trusty-updates/mitaka',
  include                             => {
    src                               => false
  },
}
->
exec { 'apt-update':
  command                             => '/usr/bin/apt-get update'
}
-> Package <| |>
