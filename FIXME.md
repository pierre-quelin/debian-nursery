# Install Debian Bullseye base (amd64)
Non testée

# Install Debian Bullseye deployment (amd64)
Non testée
- Drivers à installer manuellement
- Numéro de version dans motd à vérifier
- Voir comment supprimer /var/lib/dhcp/dhclient.eth0.leases avant ghost

# Install Debian Bullseye development (amd64)
Non testée
- Numéro de version dans motd à vérifier
- Ajout du domaine MyDomain à samba (/etc/samba/smb.conf)
- Installer Eclipse. Touver un moyen 'automatique' afin d'installer Eclipse et sa configuration
 - Encodage UTF8
 - MyCompagny style
- Configurer Gnome
 - Auto login pour user
 - Confidentialité -> Verrouillage de l'écran : Désactivé
 - Energie -> Mise en veille automatique : Désactivé
 - Nautilus - Préférences - Vues - Trier les dossiers avant les fichiers
 - Firefox français (firefox-esr-l10n-fr)
 
- Installer Docker
 - sudo puppet apply docker.pp

# Install Debian Bullseye kvm server (amd64)
Non testée - Aucune intervention humaine

# Install Debian Bullseye jitsi-meet server (amd64)
NOK - cntlm non solutionné
NOK - Problème de configuration par défaut sur les packages suivants :
sudo dpkg-reconfigure jitsi-videobridge2
sudo dpkg-reconfigure jitsi-meet-web-config

# Général
- Trouver une solution propre pour le nommage des interfaces réseau
- Voir comment basculer la responsabilité du compte et des mots de passe aux scripts puppet avec template
- Trouver une solution simple pour extraire la version dans le motd
