# manifest for Debian deployment server

# Suppression des accents pour simplification conversion d'encodage
# Convertion (ISO-8859-1) -> (UTF-8)

# Inutile - Réalisé par défaut dans l'image debian/bullseye64
# Raccourcissement du timeout de GRUB
#exec { 'update-grub':
#  command => '/usr/sbin/update-grub',
#  refreshonly => true
#}

#file_line { 'reduce_grub_timeout':
#  path  => '/etc/default/grub',
#  line  => 'GRUB_TIMEOUT=1',
#  match => 'GRUB_TIMEOUT',
#  notify => Exec['update-grub'],
#}

# Inutile - Réalisé par défaut dans l'image debian/bullseye64
# Conservervation du nommage des interfaces à l'ancienne type "eth0": net.ifnames=0
#file_line { 'ifnames':
#  path  => '/etc/default/grub',
#  line  => 'GRUB_CMDLINE_LINUX="net.ifnames=0"',
#  match => 'GRUB_CMDLINE_LINUX=',
#  notify => Exec['update-grub'],
#}


# Network tools
package { 'net-tools': ensure => 'latest' } # netstat
package { 'iftop': ensure => 'latest' }
# System tools
package { 'htop': ensure => 'latest' }

# NTLM proxy
package { 'cntlm': ensure => 'latest' }

exec { 'cntlm-restart':
  command => '/bin/systemctl restart cntlm.service',
  refreshonly => true
}

# cntlm pour authentification proxy externe
#
# 1) Proxy   MyFuckingProxy.local:8080
# 2) Only for user 'MyAccount', domain 'MyDomain' (à reprendre)
# PassLM          1XXXXF6F2E01598405B94E52DC3F363F
# PassNT          2XXXX73431190218ABF2E2F0859710C0
# PassNTLMv2      3XXXX99FF59506E8F62FD48521BD44BF
# 3) Gateway  yes
$cntlm_content = "#
# Cntlm Authentication Proxy Configuration
#
# NOTE: all values are parsed literally, do NOT escape spaces,
# do not quote. Use 0600 perms if you use plaintext password.
#

Username  MyAccount
Domain    MyDomain
#Password  password
# NOTE: Use plaintext password only at your own risk
# Use hashes instead. You can use a \"cntlm -M\" and \"cntlm -H\"
# command sequence to get the right config for your environment.
# See cntlm man page
# Example secure config shown below.
PassLM          11A0CF6F2E0159845269D21060F49ECE
PassNT          Q4A48F6950834B3D65003C158BAACA50
PassNTLMv2      6DA919CC1EFE5BC1FD26945525F63F12    # Only for user 'MyAccount', domain 'MyDomain'

# Specify the netbios hostname cntlm will send to the parent
# proxies. Normally the value is auto-guessed.
#
# Workstation netbios_hostname

# List of parent proxies to use. More proxies can be defined
# one per line in format <proxy_ip>:<proxy_port>
#
Proxy   MyFuckingProxy.local:8080

# List addresses you do not want to pass to parent proxies
# * and ? wildcards can be used
#
NoProxy   localhost, 127.0.0.*, 10.*, 192.168.*, *.MyCompagny.com

# Specify the port cntlm will listen on
# You can bind cntlm to specific interface by specifying
# the appropriate IP address also in format <local_ip>:<local_port>
# Cntlm listens on 127.0.0.1:3128 by default
#
Listen    3128

# If you wish to use the SOCKS5 proxy feature as well, uncomment
# the following option. It can be used several times
# to have SOCKS5 on more than one port or on different network
# interfaces (specify explicit source address for that).
#
# WARNING: The service accepts all requests, unless you use
# SOCKS5User and make authentication mandatory. SOCKS5User
# can be used repeatedly for a whole bunch of individual accounts.
#
#SOCKS5Proxy  8010
#SOCKS5User dave:password

# Use -M first to detect the best NTLM settings for your proxy.
# Default is to use the only secure hash, NTLMv2, but it is not
# as available as the older stuff.
#
# This example is the most universal setup known to man, but it
# uses the weakest hash ever. I won't have it's usage on my
# conscience. :) Really, try -M first.
#
#Auth   LM
#Flags    0x06820000

# Enable to allow access from other computers
#
Gateway  yes

# Useful in Gateway mode to allow/restrict certain IPs
# Specifiy individual IPs or subnets one rule per line.
#
#Allow    127.0.0.1
#Deny   0/0

# GFI WebMonitor-handling plugin parameters, disabled by default
#
#ISAScannerSize     1024
#ISAScannerAgent    Wget/
#ISAScannerAgent    APT-HTTP/
#ISAScannerAgent    Yum/

# Headers which should be replaced if present in the request
#
#Header   User-Agent: Mozilla/4.0 (compatible; MSIE 5.5; Windows 98)

# Tunnels mapping local port to a machine behind the proxy.
# The format is <local_port>:<remote_host>:<remote_port>
# 
#Tunnel   11443:remote.com:443
"

file { 'cntlm_conf':
    path    => '/etc/cntlm.conf',
    ensure  => present,
    group   => root,
    owner   => root,
    mode    => "0600",
    content => $cntlm_content,
    require => Package['cntlm'],
    notify => Exec['cntlm-restart'],
}


# Suppression du package network-manager (configuration reseau graphique)
package { 'network-manager': ensure => 'absent' }

# DHCP + DNS
package { 'dnsmasq': ensure => 'latest' }
package { 'resolvconf': ensure => 'latest' }
# Http server
package { 'apache2': ensure => 'latest' }
# Caching Proxy for Debian Packages
package { 'apt-cacher-ng': ensure => 'latest' }
# TODO - cf. https://binfalse.de/2019/05/13/apt-cacher-ng-vs-apt-transport-https/
#package { 'apt-transport-https': ensure => 'latest' }

# todo - puppetmaster
# package { 'puppetmaster': ensure => 'latest' }

# Debian installer  
package { 'debian-installer-11-netboot-amd64': ensure => 'latest' }


exec { 'networking-restart':
  command => '/bin/systemctl restart networking.service',
  refreshonly => true
} 

exec { 'dnsmasq-restart':
  command => '/bin/systemctl restart dnsmasq.service',
  refreshonly => true
}

exec { 'apt-cacher-restart':
  command => '/bin/systemctl restart apt-cacher-ng.service',
  refreshonly => true
}

# TODO - Reprendre le proxy de /etc/apt/apt.conf positionné par le fichier preseed.cfg
# Nécessite que apt-cacher-ng soit en place ainsi que la résolution du nom apt-cacher.nursery.net 
# Acquire::http::Proxy "http://apt-cacher.nursery.net:3142";

# TODO - Resoudre le problème de nommage des interfaces eth0 et eth1
$interfaces_content = "# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface (always required)
auto lo
iface lo inet loopback

# Get our IP address from any DHCP server
auto eth0
allow-hotplug eth0
iface eth0 inet dhcp

# Assign a static IP for this DHCP server through eth1:
auto eth1
allow-hotplug eth1
iface eth1 inet static
    address 192.168.1.100
    netmask 255.255.255.0
    broadcast 192.168.1.255
"

file { 'interfaces':
    path    => '/etc/network/interfaces',
    ensure  => present,
    group   => root,
    owner   => root,
    mode    => "0644",
    content => $interfaces_content,
    notify => Exec['networking-restart'],
}

# TODO - Resoudre le problème de nommage des interfaces eth0 et eth1
$firewall_content = "#!/bin/sh

PATH=/usr/sbin:/sbin:/bin:/usr/bin

# Delete all existing rules.
iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X

# Always accept loopback traffic
iptables -A INPUT -i lo -j ACCEPT

# Allow established connections, and those not coming from the outside
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -m state --state NEW -i eth0 -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow outgoing connections from the LAN side.
iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT

# Masquerade.
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Don't forward from the outside to the inside.
iptables -A FORWARD -i eth0 -o eth1 -j REJECT

# Enable forwarding.
echo 1 > /proc/sys/net/ipv4/ip_forward
"

file { 'firewall':
    path    => '/etc/network/if-up.d/00-firewall',
    ensure  => present,
    group   => root,
    owner   => root,
    mode    => "0755",
    content => $firewall_content,
    notify => Exec['networking-restart'],
}

file_line { 'deb-proxy puppetmaster host entry':
    ensure => present,
    path   => '/etc/hosts',
    line   => '192.168.1.100     gateway deb-proxy pxe puppetmaster',
}
  
$dhcp_content = "# Specifies the interface to serve. - line 90
interface=eth1

# Range of IP addresses, leases - line 141
dhcp-range=192.168.1.200,192.168.1.250,24h
# Network mask
dhcp-option=1,255.255.255.0
# Gateway
dhcp-option=3,192.168.1.100
# DNS
dhcp-option=6,192.168.1.100
# Broadcast
dhcp-option=28,192.168.1.255

# Should be set when dnsmasq is definitely the only DHCP server on a network - line 515
dhcp-authoritative
"
file { 'dnsmasq_dhcp_conf':
    path    => '/etc/dnsmasq.d/dhcp.conf',
    ensure  => present,
    group   => root,
    owner   => root,
    mode    => "0644",
    content => $dhcp_content,
    require => Package['dnsmasq'],
    notify => Exec['dnsmasq-restart'],
}

$dns_content = "# Tells dnsmasq to never forward A or AAAA queries for plain names,
# without dots or domain parts, to upstream nameservers. - line 19
domain-needed
# Bogus private reverse lookups.
bogus-priv

# Add the domain to simple names (without a period) in /etc/hosts
# in the same way as for DHCP-derived names. - line 119
expand-hosts
# Specifies DNS domains for the DHCP server. - line 128
domain=nursery.net

# Enable and set the size of dnsmasq's cache. - line 524
cache-size=256
"
file { 'dnsmasq_dns_conf':
    path    => '/etc/dnsmasq.d/dns.conf',
    ensure  => present,
    group   => root,
    owner   => root,
    mode    => "0644",
    content => $dns_content,
    require => Package['dnsmasq'],
    notify => Exec['dnsmasq-restart'],
}

$tftp_content = "# This  specifies  a  boot  option  which may appear in a PXE boot  menu. - line 450
pxe-service=x86PC, \"Debian Install\", pxelinux
# Enable the TFTP server function. - line 469
enable-tftp

# Look for files to transfer using TFTP relative to the given directory.
# The directory is only used for TFTP  requests  via  that interface eth1
tftp-root=/var/lib/tftpboot, eth1
"

file { 'dnsmasq_tftp_conf':
    path    => '/etc/dnsmasq.d/tftp.conf',
    ensure  => present,
    group   => root,
    owner   => root,
    mode    => "0644",
    content => $tftp_content,
    require => [Package['dnsmasq'], File['/var/lib/tftpboot']],
    notify => Exec['dnsmasq-restart'],
}


# tftp server
file { ['/var/lib/tftpboot',
        '/var/lib/tftpboot/pxelinux.cfg']:
   ensure => 'directory',
   owner  => 'root',
   group  => 'root',
   mode   => '0755',
   require => Package['debian-installer-11-netboot-amd64'],
}

file { '/var/lib/tftpboot/debian-installer':
   ensure => 'link',
   target => '/usr/lib/debian-installer',
   require => Package['debian-installer-11-netboot-amd64'],
}
file { '/var/lib/tftpboot/ldlinux.c32':
   ensure => 'link',
   target => '/usr/lib/debian-installer/images/11/amd64/text/ldlinux.c32',
   require => Package['debian-installer-11-netboot-amd64'],
}
file { '/var/lib/tftpboot/pxelinux.0':
   ensure => 'link',
   target => '/usr/lib/debian-installer/images/11/amd64/text/debian-installer/amd64/pxelinux.0',
   require => Package['debian-installer-11-netboot-amd64'],
}

$default_content = "PATH debian-installer/images/11/amd64/text/debian-installer/amd64/boot-screens/
DEFAULT debian-installer/images/11/amd64/text/debian-installer/amd64/boot-screens/vesamenu.c32

PROMPT 0
# Avoid an installation if nothing is specified at startup
TIMEOUT 40
ONTIMEOUT localhost

LABEL localhost
       MENU LABEL ^Local boot
       LOCALBOOT 0

LABEL Debian-amd64
       MENU LABEL ^Install Debian Bullseye (amd64)
       KERNEL debian-installer/images/11/amd64/text/debian-installer/amd64/linux
       APPEND vga=normal initrd=debian-installer/images/11/amd64/text/debian-installer/amd64/initrd.gz --quiet
       TEXT HELP
       Installation de Debian Bullseye amd64 standard
       ENDTEXT

LABEL Debian-preseed-amd64 deployment
       MENU LABEL Install Debian Bullseye deployment (amd64)
       KERNEL debian-installer/images/11/amd64/text/debian-installer/amd64/linux
       APPEND vga=normal initrd=debian-installer/images/11/amd64/text/debian-installer/amd64/initrd.gz languagechooser/language-name=French locale=fr_FR.UTF-8 keyboard-configuration/xkb-keymap=fr-latin9 netcfg/wireless_wep= netcfg/choose_interface=auto domain=nursery.net netcfg/get_hostname=deployment preseed/url=http://pxe.nursery.net/preseed-dep.cfg --
       TEXT HELP
       Installation de Debian Bullseye deploiement amd64 avec fichier preseed
       ENDTEXT

LABEL Debian-preseed-amd64 development
       MENU LABEL Install Debian Bullseye development (amd64)
       KERNEL debian-installer/images/11/amd64/text/debian-installer/amd64/linux
       APPEND vga=normal initrd=debian-installer/images/11/amd64/text/debian-installer/amd64/initrd.gz languagechooser/language-name=French locale=fr_FR.UTF-8 keyboard-configuration/xkb-keymap=fr-latin9 netcfg/wireless_wep= netcfg/choose_interface=auto domain=nursery.net netcfg/get_hostname=development preseed/url=http://pxe.nursery.net/preseed-dev.cfg --
       TEXT HELP
       Installation de Debian Bullseye développement amd64 avec fichier preseed
       ENDTEXT

LABEL Debian-preseed-amd64 kvm server
       MENU LABEL Install Debian Bullseye kvm server (amd64)
       KERNEL debian-installer/images/11/amd64/text/debian-installer/amd64/linux
       APPEND vga=normal initrd=debian-installer/images/11/amd64/text/debian-installer/amd64/initrd.gz languagechooser/language-name=French locale=fr_FR.UTF-8 keyboard-configuration/xkb-keymap=fr-latin9 netcfg/wireless_wep= netcfg/choose_interface=auto domain=nursery.net netcfg/get_hostname=kvmserver preseed/url=http://pxe.nursery.net/preseed-kvm-server.cfg --
       TEXT HELP
       Installation de Debian Bullseye kvm serveur amd64 avec fichier preseed
       ENDTEXT

LABEL Debian-preseed-amd64 jitsi-meet server
       MENU LABEL Install Debian Bullseye jitsi-meet server (amd64)
       KERNEL debian-installer/images/11/amd64/text/debian-installer/amd64/linux
       APPEND vga=normal initrd=debian-installer/images/11/amd64/text/debian-installer/amd64/initrd.gz languagechooser/language-name=French locale=fr_FR.UTF-8 keyboard-configuration/xkb-keymap=fr-latin9 netcfg/wireless_wep= netcfg/choose_interface=auto domain=nursery.net netcfg/get_hostname=jitsiserver preseed/url=http://pxe.nursery.net/preseed-jitsi-server.cfg --
       TEXT HELP
       Installation de Debian Bullseye jitsi-meet serveur amd64 avec fichier preseed
       ENDTEXT
"

file { 'pxelinux_default':
    path    => '/var/lib/tftpboot/pxelinux.cfg/default',
    ensure  => present,
    group   => root,
    owner   => root,
    mode    => "0644",
    content => $default_content,
}

file_line { 'apt-cacher_bind':
  ensure => present,
  path  => '/etc/apt-cacher-ng/acng.conf',
  line  => 'BindAddress: localhost 192.168.1.100',
  require => Package['apt-cacher-ng'],
  notify => Exec['apt-cacher-restart'],
}

file_line { 'apt-cacher_proxy':
  ensure => present,
  path  => '/etc/apt-cacher-ng/acng.conf',
  line  => 'Proxy: http://localhost:3128',
  require => Package['apt-cacher-ng'],  
  notify => Exec['apt-cacher-restart'],
}


# Remap https pour jitsi et docker
# Conflict TLS encrypted traffic apt-transport-https and apt-cacher-ng
# cf. https://binfalse.de/2019/05/13/apt-cacher-ng-vs-apt-transport-https/
file_line { 'jitsi remap':
  ensure => present,
  path   => '/etc/apt-cacher-ng/acng.conf',
  line   => 'Remap-jitsiorg: http://download.jitsi.org /jitsi ; https://download.jitsi.org # Jitsi Archives',
}

file_line { 'docker remap':
  ensure => present,
  path   => '/etc/apt-cacher-ng/acng.conf',
  line   => 'Remap-dockercom: http://download.docker.com /docker ; https://download.docker.com # Docker Archives',
}
