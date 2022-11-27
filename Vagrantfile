# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
#  if Vagrant.has_plugin?("vagrant-proxyconf")
#    config.proxy.http     = "http://MyFuckingProxy:3128/"
#    config.proxy.https    = "http://MyFuckingProxy:3128/"
#    config.proxy.no_proxy = "localhost,127.0.0.1,.MyDomain.com"
#  end

  config.vm.box = "debian/bullseye64"
  
  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  config.vm.network "private_network", virtualbox__intnet: "nursery", auto_config: false

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  config.vm.synced_folder "./www", "/var/www/html", type: "rsync"

  # Provisioning...
  # upgrade problème avec la saisie de la confirmation lors de la mise à jour de
  # openssh
  # apt-get upgrade -y
  # Installs the puppet packages required to configure the target
  config.vm.provision "shell", inline: <<-SHELL
    apt-get update
    apt-get install -y puppet \
                       puppet-module-puppet-archive \
                       puppet-module-puppetlabs-apt \
                       puppet-module-puppetlabs-rsync \
                       puppet-module-puppetlabs-stdlib \
                       puppet-module-puppetlabs-vcsrepo
  SHELL
  
  # Execute the puppet recipe /vagrant/deployment-server.pp
  # This is done because rsync and not the vboxfs system is used
  config.vm.provision "puppet" do |puppet|
    puppet.manifests_path = ["vm", "/vagrant"]
    puppet.manifest_file = "deployment-server.pp"
  end
end
