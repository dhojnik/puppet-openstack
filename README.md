# puppet-openstack
Puppet scripts to setup opinionated Ubuntu based OpenStack cloud customized for my needs. 

Steps:
* `sudo apt-get update && sudo apt-get upgrade`
* `git clone https://github.com/rajalokan/puppet-openstack.git && cd puppet-openstack`
* `sudo apt-get -y install puppet`
* `sudo puppet module install puppetlabs/apt && sudo puppet apply 01_base.pp`
* `sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys <XXXXX>`
* `sudo apt-get update` to verify there are no invalid gpg keys
* `sudo puppet module install puppetlabs/mysql && sudo puppet apply 02_mysql.pp`
* `sudo puppet module install openstack/keystone --version ">=6.0.0 <7.0.0" && sudo puppet apply 03_keystone.pp`
* `sudo puppet apply 04_rabbitmq.pp`
* `sudo puppet module install openstack/glance --version ">=6.0.0 <7.0.0" && sudo puppet apply 05_glance.pp`
* `sudo puppet module install openstack/nova --version ">=6.0.0 <7.0.0" && sudo puppet apply 06_nova.pp`
* `sudo puppet module install openstack/neutron --version ">=6.0.0 <7.0.0"`
* `sudo puppet module install example42/network`
* `sudo puppet module install saz/memcached`
* `sudo puppet apply 07_neutron.pp`
* `sudo puppet apply 08_dashboard.pp`

Credit: Much credit and thanks goes to https://github.com/cloudbase/openstack-puppet-samples/tree/master/kilo from where above puppet scripts are inspired. 
