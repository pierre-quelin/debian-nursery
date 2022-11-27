# Debian Nursery

## Nursery for automatic deployment of Debian systems

Concept :
* PXE Boot
* Retrieving a minimal preseed file (debian installer)
* Local application of a puppet manifest corresponding to the desired target

Targets available:
* Install Debian Bullseye manual (amd64)
* Install Debian Bullseye (amd64)
* Install Debian Bullseye deployment (amd64)
* Install Debian Bullseye development (amd64)
* Install Debian Bullseye kvm server (amd64)
* Install Debian Bullseye jitsi-meet server (amd64)

## Requirements

- Install VirtualBox 6.1.26
- Install Vagrant 2.2.18 - cf. [vagrant command-line interface](https://www.vagrantup.com/docs/cli)
- Install Git-2.29.2-64-bit (shell)

## Starting the Nursery server

- Start the box to make the PXE server operational for the private subnet *nursery*.

    vagrant up

## Stop the Nursery server

- Stop the box

    vagrant halt

## Deploying a target on a virtual machine

- Start the server

- Create a blank virtual machine with the desired characteristics.

- On the virtual machine, connect the first network interface on the private subnet *nursery*.

- Booting the virtual machine via PXE

- Select the desired target in the PXE menu

## Deploying a target on a real machine

- On the server, disable the second network interface of the private subnet *nursery*.

- On the server, add a new network interface via USB<->ETH adapter for example.

- Start the server

- On the real machine, connect the first network interface to the private subnet *nursery* via the USB adapter.

- Booting the real machine via PXE

- Select the desired target in the PXE menu

## Miscellaneous

- Destroy the box and associated resources

    vagrant destroy

- Connect to the box via ssh

    vagrant ssh

- To keep the /vagrant and /var/www/html directories synchronized for testing, run the following command in a shell host:

    vagrant rsync-auto

## Converting a vdi disk to qcow2 for deployment on a kvm infrastructure

    qemu-img convert -f vdi disk.vdi -O qcow2 disk.qcow2 

## Optional. For those who like to work with chains - Start server with NTLM corporate proxy

- Add a .profile file in the user's directory to configure the web proxy

    # Proxy Settings
    export ALL_PROXY=http://NtlmCorporateProxy:3128
    export http_proxy=$ALL_PROXY
    export https_proxy=$ALL_PROXY

- Install the Vagrant vagrant-proxyconf plugin

    vagrant plugin install vagrant-proxyconf

- Modify the Vagranfile.ntlm file to position the web proxy. **NtlmCorporateProxy**

- Replace the Vagrantfile with Vagrantfile.ntlm.pp

- Replace the **MyDomain** account in the puppet recipe file *deployment-server.ntlm.pp*. cf. **MyAccount** to configure the web proxy

- Replace deployment-server.pp with deployment-server.ntlm.pp

- Start the box

    vagrant up

- Connect to the box via ssh

    vagrant ssh

- - To keep the /vagrant and /var/www/html directories synchronized, run the following command in a shell host:

    vagrant rsync-auto

- In the box run the command "sudo cntlm -H" in order to generate the hash for the web proxy cntlm

- Copy the generated hashes into the puppet recipe file *deployment-server.pp*. cf. **MyHash**

- Re-execute the puppet recipe to take into account these changes

    sudo puppet apply /vagrant/deployment-server.pp

- Resume the web proxy for apt to use the same **NtlmCorporateProxy** (todo...)

   /etc/apt/apt.conf.d/01proxy
   Acquire::http::Proxy "http://localhost:3128/";
   Acquire::https::Proxy "https://localhost:3128/";

- Exit the box with the "logout" command

- Stop the box

    vagrant halt

- Disable the proxy in the Vagrantfile so as not to cascade web proxies

    if Vagrant.has_plugin?("vagrant-proxyconf")
     config.proxy.http     = "http://NtlmCorporateProxy.MyDomain:3128/"
     config.proxy.https    = "https://NtlmCorporateProxy.MyDomain:3128/"
     config.proxy.no_proxy = "localhost,127.0.0.1,.MyDomain"
    end

- restart the box

    vagrant up

- The PXE server should finally be operational on the private network *nursery*!!!
If not, please contact the "Specialists" of your IS ;-)
