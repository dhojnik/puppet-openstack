#!/usr/bin/env bash
sudo apt-get -y update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade
sudo apt-get -y install git mosh linux-image-generic-lts-utopic make htop libffi-dev libssl-dev
sudo -H pip install -U pip requests pyopenssl ndg-httpsclient pyasn1
sudo apt-get -y install puppet


sudo touch /etc/puppet/hiera.yaml
sudo puppet module install puppetlabs/apt 2>/dev/null
sudo puppet module install puppetlabs/mysql 2>/dev/null
sudo puppet module install openstack/keystone 2>/dev/null
sudo puppet module install openstack/glance 2>/dev/null
sudo puppet module install openstack/nova 2>/dev/null
sudo puppet module install openstack/neutron 2>/dev/null
sudo puppet module install example42/network 2>/dev/null
sudo puppet module install saz/memcached 2>/dev/null
sudo puppet apply 01_base.pp
sudo puppet apply 02_mysql.pp
sudo puppet apply 03_keystone.pp
sudo puppet apply 04_rabbitmq.pp
sudo puppet apply 05_glance.pp
sudo puppet apply 06_nova.pp
sudo puppet apply okan.pp
