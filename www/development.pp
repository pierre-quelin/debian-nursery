## Integration du numero de version dans le "Message du jour"
file { '/etc/motd.custom':
    ensure  => present,
    group   => root,
    owner   => root,
    mode    => "0644",
    content => "Debian 11 x86_64 Development - VX.YY.ZZ",
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

# Environement graphique : gnome
package { 'gnome': ensure => 'latest' }
# Outils réseau graphique
package { 'gnome-nettool': ensure => 'latest' }

# Outils divers
#gnome-paint
#gnome-photos
#gnome-todo
#conky
#gnome-phone-manager
# TODO - Bullseye - firefox-esr-l10n-fr

## Mandatory Access Control frameworks
# AppArmor - enable by default (Immunix, SUSE, Novel, Canonical Ltd)
#package { 'apparmor-utils': ensure => 'latest' }
#package { 'apparmor-profiles': ensure => 'latest' }
#package { 'apparmor-profiles-extra': ensure => 'latest' }
# SELinux - disable by default (N.S.A.)

# Drivers video si pas VM
package { 'xserver-xorg-video-all': ensure => 'latest' }
# Gestion des packages avec interface graphique
package { 'gnome-software': ensure => 'latest' }
#package { 'gnome-software-plugin-flatpack': ensure => 'latest' }
#package { 'gnome-software-plugin-snap': ensure => 'latest' }
package { 'synaptic': ensure => 'latest' } # Incompatible en mode Wayland
#package { 'gnome-packagekit': ensure => 'latest' } # Compatible Wayland

#package { 'gnome-screensaver': ensure => 'latest' }
#package { 'gnome-search-tool': ensure => 'latest' }

# vmware tools
package { 'open-vm-tools': ensure => 'latest' }
# TODO - Déprécié package { 'open-vm-tools-dkms': ensure => 'latest' }
package { 'open-vm-tools-desktop': ensure => 'latest' }
# virtualbox tools - Retiré depuis stretch

package { 'samba': ensure => 'latest' }
# TODO - Question à l'install du package
# "Modifier smb.conf pour utiliser les paramètres WINS fournis par DHCP ?
# Si votre ordinateur obtient ses paramètres à partir d'un réseau, ce serveur peut aussi
# fournir des informations WINS (serveur de noms NetBIOS) présents sur le réseau.
# Une modification du fichier smb.conf est nécessaire afin que les réglages WINS fournis
# par le serveur DHCP soient lus dans /var/lib/samba/dhcp.conf.
# Le paquet dhcp-client doit être installé pour utiliser cette fonctionnalité."
package { 'nautilus-share': ensure => 'latest' }
file_line { 'samba_group':
  path => '/etc/samba/smb.conf',
  line => 'workgroup = MyDomain',
  match => '^workgroup.*=.*',
  require => Package['samba'],
}

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
"

file { '/etc/network/interfaces':
    ensure  => present,
    group   => root,
    owner   => root,
    mode    => "0644",
    content => $interfaces_content,
    notify => Exec['networking-restart'],
    require => Package['network-manager-gnome'], # Assure le basculement du dhcp
}

# Gestion du réseau par l'interface graphique
package { 'network-manager-gnome': ensure => 'latest' }
#package { 'network-manager-openvpn-gnome': ensure => 'latest' }
package { 'network-manager-ssh-gnome': ensure => 'latest' }

# Debian handbook
package { 'debian-handbook': ensure => 'latest' }
package { 'debian-reference': ensure => 'latest' }

# Time tracking tool
# package { 'hamster-applet': ensure => 'latest' }

# Remote desktop
# package { 'remmina': ensure => 'latest' } # TODO - retiré de Stretch
package { 'gnome-remote-desktop': ensure => 'latest' } # vnc server
  
# Dev. tools
package { 'build-essential': ensure => 'latest' }
# Voir si nécessité compilation i386 et amd64. Clarifier multilib vs multiarch
package { 'ssh': ensure => 'latest' }
package { 'cmake': ensure => 'latest' }
package { 'cmake-doc': ensure => 'latest' }
package { 'subversion': ensure => 'latest' }
package { 'git': ensure => 'latest' }
package { 'libsvn-java': ensure => 'latest' } # Eclipse
package { 'libcanberra-gtk-module': ensure => 'latest' } # Bosque - A clarifier

# Debian Packaging
package { 'fakeroot': ensure => 'latest' }
package { 'devscripts': ensure => 'latest' }
package { 'debhelper': ensure => 'latest' }
package { 'dh-make': ensure => 'latest' }
package { 'dkms': ensure => 'latest' }
package { 'dos2unix': ensure => 'latest' }

# Pythonneries
#package { 'python3-numpy': ensure => 'latest' } 
#package { 'python3-scipy': ensure => 'latest' } 
#package { 'python3-matplotlib': ensure => 'latest' }
# TODO - A voir... 
# package { 'python-pyserial': ensure => 'latest' } 
  
# Dev. FTDI Chips (cf. ALPS)
package { 'libftdi-dev': ensure => 'latest' }

# package { 'default-jdk': ensure => 'latest' }
package { 'linux-perf': ensure => 'latest' } # perf,... + droits
package { 'cppcheck': ensure => 'latest' }
package { 'valgrind': ensure => 'latest' }
package { 'systemtap': ensure => 'latest' }
package { 'wine': ensure => 'latest' }
#package { 'winetricks': ensure => 'latest' }
# TODO - Questionnement lors de l'install afin de savoir si l'utilisateur a le droit de capturer des paquets
# ajout de l'utilisateur au group : sudo usermod -a -G wireshark user
# gtk : évite d'installer les librairies qt
package { 'wireshark-gtk': ensure => 'latest' }
package { 'filezilla': ensure => 'latest' }

# Compilateurs joker
# clang
package { 'clang': ensure => 'latest' }
package { 'clang-format': ensure => 'latest' }
package { 'clang-tidy': ensure => 'latest' }
# Development environment targeting 32- and 64-bit Windows
package { 'mingw-w64': ensure => 'latest' }
package { 'gdb-mingw-w64': ensure => 'latest' }
package { 'gdb-mingw-w64-target': ensure => 'latest' }

# TODO - Environnement de dev. Qt à voir...
#package { 'qt5-default': ensure => 'latest' }
#package { 'qtcreator': ensure => 'latest' } # Integrated Development Environment for Qt

# Nautilus tools
#package { 'nautilus-compare': ensure => 'latest' }
#package { 'nautilus-open-terminal': ensure => 'latest' } # TODO - Doublon ?
package { 'nautilus-sendto': ensure => 'absent' }

# Compiler cache for fast recompilation of C/C++ code
package { 'ccache': ensure => 'latest' }
file { '/home/user/bin':
   ensure => 'directory',
   group   => user,
   owner   => user,
   mode    => "0755",
}
file { '/home/user/bin/gcc':
   ensure => 'link',
   target => '/usr/bin/ccache',
   group   => user,
   owner   => user,
   mode    => "0777",
   require => [
     File['/home/user/bin'],
     Package['build-essential'],
     Package['ccache']
   ],
}
file { '/home/user/bin/g++':
   ensure => 'link',
   target => '/usr/bin/ccache',
   group   => user,
   owner   => user,
   mode    => "0777",
   require => [
    File['/home/user/bin'],
    Package['build-essential'],
    Package['ccache']
   ],
}
file { '/home/user/bin/c++':
   ensure => 'link',
   target => '/usr/bin/ccache',
   group   => user,
   owner   => user,
   mode    => "0777",
   require => [
    File['/home/user/bin'],
    Package['build-essential'],
    Package['ccache']
   ],
}
file { '/home/user/bin/cc':
   ensure => 'link',
   target => '/usr/bin/ccache',
   group   => user,
   owner   => user,
   mode    => "0777",
   require => [
    File['/home/user/bin'],
    Package['build-essential'],
    Package['ccache']
   ],
}

# Virtualisation tools
package { 'virt-manager': ensure => 'latest' }
# TODO - retiré de Bullseye - package { 'virt-top': ensure => 'latest' }
package { 'ssh-askpass-gnome': ensure => 'latest' }
package { 'lxc': ensure => 'latest' }
package { 'lxctl': ensure => 'latest' }
# Docker - TODO
# Vagrant - TODO
#package { 'vagrant': ensure => 'latest' }
#package { 'vagrant-lxc': ensure => 'latest' }
#package { 'vagrant-libvirt': ensure => 'latest' }
#package { 'vagrant-sshfs': ensure => 'latest' }
#package { 'vagrant-cachier': ensure => 'latest' }

  
#============ Environnement multi-arch (amd64 + i386)
#exec { 'apt-get_update':
#  command => '/usr/bin/apt-get update',
#  refreshonly => true
#}
#exec { 'multiarch_i386':
#  command => '/usr/bin/dpkg --add-architecture i386',
#  notify => Exec['apt-get_update'],
#}
# runtime
#package { 'libstdc++6:i386':
#  ensure => 'latest',
#  require => Exec['multiarch_i386'],
#}

# Realtime rights
group { 'realtime':
  ensure => 'present',
}
group { 'dialout':
  ensure => 'present',
}
group { 'sambashare':
  ensure => 'present',
  require => Package['samba'],
}

user { 'user':
    groups      => ['sambashare','dialout','realtime'],
    membership  => minimum,
    require => Group['sambashare','dialout','realtime'],
}

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
file { '/etc/security/limits.d/core.conf.inhibited':
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


#============ Passage du clavier en Francais sous gnome pour user
# Ajout de deux sources
# gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'fr')]"
# Ajout d'une seule source
# gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'fr')]"
exec {'set_gnome_keyboard':
  command => "/usr/bin/gsettings set org.gnome.desktop.input-sources sources \"[(\'xkb\', \'fr\')]\"",
  user => 'user',
  require => Package['gnome'],
}


#============ Activation de l'autologin
# TODO - Section [daemon]
# TODO - Confusion AutomaticLogin et AutomaticLogin+Enable
file_line { 'gdm3_autologin_enable':
  ensure => present,
  path   => '/etc/gdm3/daemon.conf',
  line   => 'AutomaticLoginEnable = true',
  match  => 'AutomaticLoginEnable',
  require => Package['gnome'],
}
file_line { 'gdm3_autologin_user':
  ensure => present,
  path   => '/etc/gdm3/daemon.conf',
  line   => 'AutomaticLogin = user',
  match  => 'AutomaticLogin ', # Espace ' ' pour eviter la confusion avec AutomaticLoginEnable
  require => Package['gnome'],
}

#============ Desactivation de la mise en veille de l'écran sur inactivité
# gsettings set org.gnome.desktop.screensaver idle-activation-enabled false
exec { 'disable_idle-activation':
     command => "/usr/bin/gsettings set org.gnome.desktop.screensaver idle-activation-enabled false",
     user => 'user',
     require => Package['gnome'],
}

#============ Desactivation du verrouillage auto de l'economiseur d'ecran
# cf. Paramètres -> Confidentialité -> Vérrouillage de l'écran
#  gsettings set org.gnome.desktop.screensaver lock-enabled false
exec { 'disable_idle_lock':
     command => "/usr/bin/gsettings set org.gnome.desktop.screensaver lock-enabled false",
     user => 'user',
     require => Package['gnome'],
}


#==================================== TODO ====================================

# Clavier en console OK
class keyboard (
  $model     = 'pc105',
  $layout    = 'us',
  $variant   = '',
  $options   = '',
  $backspace = 'guess'
) {

  package { 'keyboard-configuration': ensure => present }

  file { '/etc/default/keyboard':
    content => inline_template('# KEYBOARD CONFIGURATION FILE
# Consult the keyboard(5) manual page.
XKBMODEL="<%= @model %>"
XKBLAYOUT="<%= @layout %>"
XKBVARIANT="<%= @variant %>"
XKBOPTIONS="<%= @options %>"
BACKSPACE="<%= @backspace %>"
')
  }

  exec { 'apply-keyboard-configuration':
    command     => '/usr/sbin/dpkg-reconfigure -f noninteractive keyboard-configuration',
    subscribe   => File['/etc/default/keyboard'],
    require     => [ File['/etc/default/keyboard'], Package['keyboard-configuration'], ],
    refreshonly => true
  }
}

class { 'keyboard':
  layout => 'fr',
  variant => 'latin9'
}
# rem : ok en console

#============ Eclipse
package { 'default-jre': ensure => 'latest' }

# FIXME .local/share à créer
# TODO - Le répertoire est créé lors de la première ouverture de session Gnome
file { '/home/user/.local/share/applications':
  ensure => 'directory',
  group   => user,
  owner   => user,
  mode    => "0755",
}
# TODO - Récupération et Install depuis le site d'Eclipse
file { '/home/user/bin/Eclipse':
  ensure => 'directory',
  group   => user,
  owner   => user,
  mode    => "0755",
  require => File['/home/user/bin'],
}
file { 'eclipse':
  path    => '/home/user/bin/Eclipse/eclipse',
  ensure  => present,
  group   => user,
  owner   => user,
  mode    => "0755",
  require => File['/home/user/bin/Eclipse'],
}

# Intégration à l'environnement
file { '/home/user/bin/eclipse':
  ensure => 'link',
  target => '/home/user/bin/Eclipse/eclipse',
  require => File['eclipse'],
}

$eclipse_desktop_content = "[Desktop Entry]
Version=1.0
Name=Eclipse IDE
Comment=Eclipse IDE for C/C++ Linux Developers
Exec=/home/user/bin/eclipse
Terminal=false
X-MultipleArgs=false
Type=Application
Icon=/home/user/bin/Eclipse/icon.xpm
StartupNotify=true
"
file { 'eclipse_desktop':
  path    => '/home/user/.local/share/applications/eclipse.desktop',
  ensure  => present,
  group   => user,
  owner   => user,
  mode    => "0644",
  content => $eclipse_desktop_content,
#  require => File['/home/user/bin'],
}

# TODO - Template de fichiers

# TODO - à voir...
# Menu contextuel - Retirer le fond noir
# nano /home/user/bin/eclipse/eclipse.ini
#--launcher.GTK_version
#2
#-startup
#...

# TODO - Configuration et installation des différents plugins
# Subversive (Ajouter http://download.eclipse.org/technology/subversive/4.0/update-site/ )
# PyDev
# XML Editors and Tools
# TM Terminal
# ShellEd
# BashEditor
# PHP

# Configurer
# - Encodage
# - Format C++ custom
# - Toujours en tache de fond
# - Show Heap
# - Raccourci compilation Ctrl+B
# - Obsolète - Raccourci Ctrl+Z
# - Compilation systématique avant débug à retirer
# - Configurer la Recherche Ctrl+H
# - Configurer les repository SVN
# - Ajouter les fichiers .inl avec éditeur C++
# - Ajouter un lien Jenkins/Hudson
# - Configurer les Tools propriétaires

#============ Configuration de wine H: -> /home/user
# dpkg --add-architecture i386 && apt-get update && apt-get install wine32
#
# bug winecfg oblige de lancer wine64 winecfg
# Probleme, /home/user/.wine n'est cree que lors du lancement de >wine64 winecfg
#file { '/home/user/.wine/dosdevices/h:':
#   ensure => 'link',
#   target => '/home/user',
#   group   => user,
#   owner   => user,
#   mode    => "0777",
#   require => Package['wine'],
#}
# wine winecfg
# Comment récupérer wine-mono ?
# wine msiexec /i wine-mono-4.6.3.msi

# Créer des raccourcis
# workspace, vserv..., redmine,...


#============ Drivers

#============ Reconfigurer le reseau - Supprimer le proxy apt

# Reseau Local (a voir..)
#file_line { 'local_group':
#  path => '/etc/nsswitch.conf',
#  line => 'hosts:          files mdns4_minimal dns mdns4',
#  match => '# hosts:          files mdns4_minimal [NOTFOUND=return] dns mdns4',
#}
#service { 'avahi-daemon':
#  restart => true,
#}

#============ Fixer un fond d'ecran distinctif afin d'identifier la version
#file { "/usr/share/backgrounds/warty-final-ubuntu.png":
#   source => "puppet://server/modules/module_name/background.jpg" 
#}
#define set_bg($name) {
#    exec {"set bg for $name":
#        command => "/usr/bin/gsettings set org.gnome.desktop.background picture-uri file:///usr/share/backgrounds/warty-final-ubuntu.png",
#        user => "$name",
#    }
#}
#user { "joe":
#  ensure      =>  "present",
#  uid         =>  "1005",
#  comment     =>  "Joe",
#  home        =>  "/home/joe",
#  shell       =>  "/bin/bash",
#  managehome  =>  "true"
#} 
#set_bg { "joe": name=>"joe" }
