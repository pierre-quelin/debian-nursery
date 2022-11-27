# Suppression des accents pour simplification conversion d'encodage
# Convertion (ISO-8859-1) -> (UTF-8)

# preseed file for kvm server

## Integration du numero de version dans le "Message du jour"
file { '/etc/motd.custom':
    ensure  => present,
    group   => root,
    owner   => root,
    mode    => "0644",
    content => "Debian 11 x86_64 kvm-server - VX.YY.ZZ",
}

file_line { '/etc/pam.d/login':
  path  => '/etc/pam.d/login',
  after => '# and a static (admin-editable) part from /etc/motd.',
  line  => 'session    optional   pam_motd.so  motd=/etc/motd.custom noupdate',
  require => File['/etc/motd.custom'],
}
file_line { '/etc/pam.d/sshd':
  path  => '/etc/pam.d/sshd',
  after => '# and a static (admin-editable) part from /etc/motd.',
  line  => 'session    optional     pam_motd.so  motd=/etc/motd.custom noupdate',
  require => [
    File['/etc/motd.custom'],
    Package['ssh'],
  ],
}

# Raccourcissement du timeout de GRUB
exec { 'update-grub':
  command => '/usr/sbin/update-grub',
  refreshonly => true
}

file_line { 'reduce_grub_timeout':
  path  => '/etc/default/grub',
  line  => 'GRUB_TIMEOUT=1',
  match => 'GRUB_TIMEOUT',
  notify => Exec['update-grub'],
}

# A vérifer - Réalisé par défaut dans l'image debian/bullseye64
# Conservervation du nommage des interfaces à l'ancienne type "eth0": net.ifnames=0
file_line { 'ifnames':
  path  => '/etc/default/grub',
  line  => 'GRUB_CMDLINE_LINUX="net.ifnames=0"',
  match => 'GRUB_CMDLINE_LINUX=',
  notify => Exec['update-grub'],
}

package { 'ssh': ensure => 'latest' }
# Installation des packages necessaire a la virtualisation
# Virtual machines
package { 'qemu-kvm': ensure => 'latest' }
package { 'libvirt-daemon': ensure => 'latest' }
package { 'libvirt-clients': ensure => 'latest' }
package { 'virt-manager': ensure => 'latest' } # Pas d'interface graphique mais visiblement nécessaire pour les différents groups et droits
package { 'virt-top': ensure => 'latest' }
# Containers
package { 'lxc': ensure => 'latest' }
package { 'lxctl': ensure => 'latest' }
package { 'debootstrap': ensure => 'latest' }

# Création des répertoire de stockage /storevm/vm /storevm/iso
file { [ '/storevm', '/storevm/vm', '/storevm/iso' ]:
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0666',
}
# Partage systeme de fichier réseau nfs
package { 'nfs-kernel-server': ensure => 'latest' }
service { 'nfs-kernel-server.service':
    enable => true,
    require => Package['nfs-kernel-server'],
}
file_line { 'nfs vm entry':
  path  => '/etc/exports',
  line  => '/storevm/vm    172.17.202.0/24(rw,sync)',
  notify  => Service['nfs-kernel-server.service'],
  require => [
    File['/storevm', '/storevm/vm', '/storevm/iso'],
    Package['nfs-kernel-server'],
  ],
}
file_line { 'nfs iso entry':
  path  => '/etc/exports',
  line  => '/storevm/iso   172.17.202.0/24(rw,sync)',
  notify  => Service['nfs-kernel-server.service'],
  require => [
    File['/storevm', '/storevm/vm', '/storevm/iso'],
    Package['nfs-kernel-server'],
  ],
}
# TODO - A voir package { 'rpcbind': ensure => 'latest' }

# Droits utilisateur pour utilisation de libvirt
user { 'user':
    groups      => ['libvirt', 'libvirt-qemu'],
    membership  => minimum,
    require     => Package['libvirt-daemon'],
}

# Suppression du package network-manager (configuration reseau graphique)
package { 'network-manager': ensure => 'absent' }

# Mise en place d'un bridge sur eth0 en dhcp
package { 'bridge-utils': ensure => 'latest' }

exec { 'networking-restart':
  command => '/bin/systemctl restart networking.service',
  refreshonly => true
}

$content = "# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
allow-hotplug eth0
iface eth0 inet manual

# Bridging eth0
auto br0
iface br0 inet dhcp
     bridge_ports eth0 eth1
     bridge_stp off
     bridge_fd 0
     bridge_maxwait 0
"

file { 'interfaces':
    path    => '/etc/network/interfaces',
    ensure  => present,
    group   => root,
    owner   => root,
    mode    => "0644",
    content => $content,
    require => [
                File_line['ifnames'],
                Package['bridge-utils'],
                ],
    notify => Exec['networking-restart'],
}
