include apt

# User
#user { 'user': 
#  ensure   => present,
#  password => 'drowssap',
#}

# Désactivation du service puppet activé par défaut
service { 'puppet':
  enable => false,
}

# Network tools
#package { 'ssh': ensure => 'latest' }
#package { 'net-tools': ensure => 'latest' } #  netstat
#package { 'iftop': ensure => 'latest' }
# System tools
#package { 'htop': ensure => 'latest' }



# TODO - cf. https://binfalse.de/2019/05/13/apt-cacher-ng-vs-apt-transport-https/
#package { 'apt-transport-https': ensure => 'latest' }
  
# First install the Jitsi repository key onto your system:
# wget -qO - https://download.jitsi.org/jitsi-key.gpg.key | sudo apt-key add -
# Create a sources.list.d file with the repository:
# sudo sh -c "echo 'deb https://download.jitsi.org stable/' > /etc/apt/sources.list.d/jitsi-stable.list"
apt::source { 'jitsi-stable':
  comment  => 'Jitsi stable mirror',
#  location => 'https://download.jitsi.org',
  location => 'http://download.jitsi.org',
  release  => 'stable/',
  repos    => '',
  key      => {
    'id'     => '66A9CD0595D6AFA247290D3BEF8B479E2DC1389C',
    source   => 'https://download.jitsi.org/jitsi-key.gpg.key',
    ensure   => 'refreshed',
  },
  include  => {
    'deb' => true,
  },
#  require => Package['apt-transport-https'],
  notify => Exec['apt_update'],
}


# Install the full suite
# Need the hostname of the Jitsi Meet instance (FQDN) or the IP address
# Needed to generate a Let's Encrypt certificate (optional, recommended)
# hostname = jitsiserver.nursery.net vs 192.168.1.xxx (static)

# Use debconf-show or debconf-get-selections to find out about valid debconf entries for an installed package.
# cf. stm/debconf
# https://forge.puppet.com/stm/debconf#setup

# FIXME 
# jitsi-videobridge2 - The hostname of the current installation
# cf. https://github.com/jitsi/jitsi-videobridge/blob/master/debian/templates
# sudo dpkg-reconfigure jitsi-videobridge2
#debconf { 'jitsi_videobridge_hostname':
#  package => 'jitsi-videobridge2',
#  item    => 'jitsi-videobridge/jvb-hostname',
#  type    => 'string',
#  value   => 'jitsiserver',
#  seen    => false,
#}

# FIXME
# jitsi-meet-web-config - Generate a new self-signed certificate (You will later get a ... <Ok>
# cf. https://github.com/jitsi/jitsi-meet/blob/master/debian/jitsi-meet-web-config.templates
# sudo dpkg-reconfigure jitsi-meet-web-config
#debconf { 'jitsi_meet_cert':
#  package => 'jitsi-meet',
#  item    => 'jitsi-meet/cert-choice',
#  type    => 'select',
#  value   => 'Generate a new self-signed certificate (You will later get a chance to obtain a Let's encrypt certificate), I want to use my own certificate',
#  seen    => false,
#}

# FIXME - à réaliser à la main tant que les 2 points précédent ne sont pas réglé
#package { 'jitsi-meet':
#  ensure => 'latest',
#  require => Apt::Source['jitsi-stable'],
#}


# Option - Install the  SIP gateway
# Need SIP account and password
#package { 'jigasi':
#  ensure => 'latest',
#  require => Apt::Source['jitsi-stable'],
#}
