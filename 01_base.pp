class { 'apt': }

# TODO: required_packages is depricated
apt::source { 'ubuntu-cloud':
  location          =>  'http://ubuntu-cloud.archive.canonical.com/ubuntu',
  repos             =>  'main',
  release           =>  'trusty-updates/kilo',
  include_src       => false,
  required_packages =>  'ubuntu-cloud-keyring',
}
->
exec { 'apt-update':
    command => '/usr/bin/apt-get update'
}
-> Package <| |>
