## Integration du numero de version dans le "Message du jour"
# TODO - "Debian 11 x86_64 Deploy Recovery - VX.YY.ZZ"
file { '/etc/motd.custom':
    ensure  => present,
    group   => root,
    owner   => root,
    mode    => "0644",
    content => "Debian 11 x86_64 Deploy Recovery - VX.YY.ZZ",
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

# Désactivation du service puppet activé par défaut
service { 'puppet':
  enable => false,
}

# TODO - Désactivation du service irqbalance
# "Daemon to balance interrupts for SMP systems"
#service { 'irqbalance':
#  enable => false,
#}

# Désactivation du service pcmcia
service { 'pcscd':
  enable => false,
}

#stage { 'first':
#  before => Stage['main'],
#}
#stage { 'last':
#}
#Stage['main'] -> Stage['last']
#
#file_line { 'activate apt proxy':
#  path  => '/etc/apt/apt.conf',
#  line  => 'Acquire::http::Proxy "http://MyCorporateProxy:3128";',
#  match => 'Acquire::http::Proxy',
#  stage => first
#}

# ? HTTP pipelining is broken and causes download failures ?
#file { '/etc/apt/apt.conf.d/pipeline.':
#  ensure  => present,
#  group   => root,
#  owner   => root,
#  mode    => "0440",
#  content => "Acquire::http { Pipeline-Depth \"0\"; }\n",
#}

### Customisation Specifique plate-forme de deploiement
# Installation du noyau temps reel
#package { 'linux-image-rt-686-pae': ensure => 'latest' }
# Desinstallation du noyau "standard".
#package { 'linux-image-686-pae': ensure => 'purged' }
#package { 'linux-image-686': ensure => 'purged' }
#package { 'linux-image-3.2.0-4-686-pae': ensure => 'purged' }
# Suppression de la surveillance des raid "LSI"
#package { 'mpt-status': ensure => 'purged' }

# Installation des divers logiciels
package { 'ssh': ensure => 'latest' }
package { 'gdbserver': ensure => 'latest' }
package { 'gdb': ensure => 'latest' } # gcore
package { 'rsync': ensure => 'latest' }
package { 'linux-perf': ensure => 'latest' }
package { 'beep': ensure => 'latest' }
package { 'psmisc': ensure => 'latest' }
package { 'ccze': ensure => 'latest' } # Coloration des logs

# Network tools
package { 'net-tools': ensure => 'latest' } #  netstat
package { 'iftop': ensure => 'latest' }
# System tools
package { 'htop': ensure => 'latest' }

# Dev. FTDI Chips (cf. ALPS)
file { '/etc/udev/rules.d/80-ftdi.rules':
  ensure  => present,
  group   => root,
  owner   => root,
  mode    => "0644",
  content => 'SUBSYSTEM=="usb", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", GROUP="realtime", MODE="0660"',
  require => Group['realtime'],
}
package { 'libftdi1': ensure => 'latest' }

# Changement des privileges pour le group realtime de maniere a pouvoir demarrer
# une application avec une priorite superieure a la normale
file { '/etc/security/limits.d/rtprio.conf':
  ensure  => present,
  group   => root,
  owner   => root,
  mode    => "0644",
  content => '@realtime - rtprio 99',
  require => Group['realtime'],
}

# Positionnement des droits pour la generation de corefiles
file { '/etc/security/limits.d/core.conf':
  ensure  => present,
  group   => root,
  owner   => root,
  mode    => "0644",
  content => '@realtime soft core unlimited',
  require => Group['realtime'],
}

# Positionnement des droits pour le verrouillage des pages mémoire
file { '/etc/security/limits.d/memlock.conf':
  ensure  => present,
  group   => root,
  owner   => root,
  mode    => "0644",
  content => '@realtime - memlock unlimited',
  require => Group['realtime'],
}

# Positionnement des droits pour l'utilisation du port imprimante
group { 'lp':
  ensure => 'present',
}
# Positionnement des droits pour l'utilisation des ports series
group { 'dialout':
  ensure => 'present',
}
# Positionnement des droits pour l'execution d'applicatifs temps reel
group { 'realtime':
  ensure => 'present',
}
user { 'user':
    groups      =>  ["dialout","realtime","lp"],
    membership  => minimum,
    require => Group['dialout','realtime',"lp"],
}

# Reprise du format de nommage des corefiles
file { '/etc/sysctl.d/core_pattern.conf':
    ensure  => present,
    group   => root,
    owner   => root,
    mode    => "0644",
    content => "kernel.core_pattern = core-%E-%e-%s-%t",
}

# Black lister les modules a risque
# blacklist pcspkr : retire pour diagnostique du boot
file { '/etc/modprobe.d/realtime-blacklist.conf':
    ensure  => present,
    group   => root,
    owner   => root,
    mode    => "0644",
    content => "blacklist acpi-cpufreq",
}

# Forcer le chargement de certains modules
file_line { 'modules.cfg':
  path => '/etc/modules-load.d/modules.conf',
  line => 'pcspkr',
}

# Suppression des UUIDs a voir...
# /etc/fstab
# Realisé dans le partitionnement de preseed.cfg
exec { 'update-grub':
  command => '/usr/sbin/update-grub',
  refreshonly => true
}

file_line { 'grub_disable_linux_uuid':
  path  => '/etc/default/grub',
  line  => 'GRUB_DISABLE_LINUX_UUID=true',
  match => 'GRUB_DISABLE_LINUX_UUID',
  notify => Exec['update-grub'],
}

# Raccourcissement du timeout de GRUB
file_line { 'reduce_grub_timeout':
  path  => '/etc/default/grub',
  line  => 'GRUB_TIMEOUT=1',
  match => 'GRUB_TIMEOUT',
  notify => Exec['update-grub'],
}

# Passage du nombre de ports series de 4 a 12
# Conservervation du nommage des interfaces à l'ancienne type "eth0": net.ifnames=0 
# Latence : Interdiction de basculer le système en C-state autre que 0 cf. https://access.redhat.com/articles/65410
file_line { 'increase_nr_uarts':
  path  => '/etc/default/grub',
  line  => 'GRUB_CMDLINE_LINUX="net.ifnames=0 8250.nr_uarts=12 processor.max_cstate=1 idle=poll"',
  match => 'GRUB_CMDLINE_LINUX=',
  notify => Exec['update-grub'],
}

# Nommage des interfaces  réseau "à l'ancienne" cf. net.ifnames=0
exec { 'networking-restart':
  command => '/bin/systemctl restart networking.service',
  refreshonly => true
}

$interfaces_content = "# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
allow-hotplug eth0
iface eth0 inet dhcp
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

# Suppression du lien interface reseau ethX <-> MAC adresse s'il a ete cree
file { '/etc/udev/rules.d/70-persistent-net.rules':
    ensure  => absent,
}

# Mise en place d'un client NTP (Network Time Protocol)
# cf. Gestion de l'heure locale sous Debian Bullseye
# Le passage à systemd apporte un nouveau service ntp client beaucoup plus simple.
# cf. systemd-timesyncd.service
# https://www.guillaume-leduc.fr/configurer-client-ntp-jessie-systemd.html
# TODO - Voir si ce service inclut la mise à jour de l'heure RTC et peut
# remplacer le service NTP
package { 'ntp': ensure => 'latest' }
# cf. puppetlabs/ntp
#include '::ntp'

# Positionner l'adresse locale comme DNS par defaut
file_line { 'dhclient.conf':
  path  => '/etc/dhcp/dhclient.conf',
  line  => 'prepend domain-name-servers 127.0.0.1;',
  match => 'prepend domain-name-servers 127.0.0.1',
}
 
# Correction automatique du systeme de fichier au demarrage
# TODO - A vérifier sous Bullseye mais doit être réalisé par défaut avec systemd
# cf. https://www.freedesktop.org/software/systemd/man/systemd-fsck@.service.html
#file_line { 'default.rcS':
#  path  => '/etc/default/rcS',
#  line  => 'FSCKFIX=yes',
#  match => 'FSCKFIX=',
#}

# Installation du script de synchronisation/demarrage des applications
# Terminal 1 en autologon pour le compte user
file { '/etc/systemd/system/getty@tty1.service.d':
   ensure => 'directory',
   group   => user,
   owner   => user,
   mode    => "0755",
}

$autologin_conf_content = '[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin user --noclear %I 38400 linux'

file { '/etc/systemd/system/getty@tty1.service.d/autologin.conf':
    ensure  => present,
    group   => user,
    owner   => user,
    mode    => "0744",
    content => $autologin_conf_content,
    require => File['/etc/systemd/system/getty@tty1.service.d'],
    notify => Exec['autologin_enable'],
}

exec { 'autologin_enable':
  command => '/bin/systemctl enable getty@tty1.service',
  refreshonly => true
}

# Modifier le script d'entree en session du compte user
file_line { 'profile':
  path  => '/home/user/.profile',
  line  => 'if [ -z "$DISPLAY" ] && [ $(tty) == /dev/tty1 ]; then ~/bootstrap.sh; fi',
}

# Creation du script ~/bootstrap.sh
# bootstrap.sh
$bootstrap_sh_content = "#!/bin/sh
ENTRY=~/bin/project_entry.sh

# Retourne l'adresse IP du serveur rsync
rsync_server()
{
   # En premiere approche c'est le serveur ntp qui fait office de serveur rsync
   # et c'est le serveur dhcp qui fournit l'adresse du serveur ntp (une seule adresse !)
   # - Recuperation des informations aupres de dhclient (Console)
   RSYNC_SRV=`cat /var/lib/dhcp/dhclient.eth0.leases | grep ntp-servers | tail -n 1 | cut -d' ' -f5 | cut -d';' -f1`
   echo \$RSYNC_SRV
}

# Test si le serveur est atteignable
ping -c 1 \$(rsync_server) > /dev/null
while [ \$? -ne 0 ] ; do
   sleep 1 # Une nouvelle tentative toute les secondes
   beep -r 1 -d 200 -l 400
   ping -c 1 \$(rsync_server) > /dev/null
done

# Synchronise le repertoire applicatif local depuis le repertoire applicatif distant
rsync -azv --delete user@\$(rsync_server)::processpc ~/bin/
while [ \$? -ne 0 ] ; do
   sleep 1 # Une nouvelle tentative toute les secondes
   beep -r 2 -d 200 -l 400
   rsync -azv --delete user@\$(rsync_server)::processpc ~/bin/
done

# Demarrage du point d'entree des applications
if [ -x \$ENTRY ] ; then
   \$ENTRY
else
   echo File \$ENTRY does not exists !
   while true ; do
      sleep 1
      beep -r 3 -d 200 -l 400
   done
fi
"

file { '/home/user/bootstrap.sh':
    ensure  => present,
    group   => user,
    owner   => user,
    mode    => "0744",
    content => $bootstrap_sh_content,
}
 
# Installation des benchmarks de tests de la plateforme (DKMS)
# Bench RT
package { 'rt-tests': ensure => 'latest' }
# Bench de charge
package { 'sysbench': ensure => 'latest' }
package { 'stress': ensure => 'latest' }
package { 'stress-ng': ensure => 'latest' }

# TODO - ne remplit pas la regle de exec (n fois)

## Nettoyage de la machine virtuelle
#exec { 'apt-get clean':
#  command => 'apt-get clean',
#  path => '/sbin'
#  stage => last
#}

## Desactivation du proxy
#file_line { 'deactivate apt proxy':
#  path  => '/etc/apt/apt.conf',
#  line  => '',
#  match => 'Acquire::http::Proxy',
#  stage => last
#}

## Arret du PC
#exec { 'halt':
#  command => 'halt',
#  path => '/sbin'
#  stage => last
#  require => Exec['apt-get clean'],
#  require => File_line['deactivate apt proxy'],
#}
