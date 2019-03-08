# firewall
Scripts Firewall Routeur basé sur iptables

Réalisation d'un parefeu routeur à partir de scripts iptables.
Compatible avec les distributions linux Debian et indépendant de l'architecture matériel

Note sur l'auteur:
Je ne suis pas expert informatique, mon expérience est purement autodidacte basé sur la lecture de tutoriel et documentation à ma disposition.
Mon Dévelopement est basé sur l'expérimentation et la compréhension des concepts mis en place.
Ne trouvant de solution à mon problème j'ai décidé de le résoudre moi même et de le partagé.
Merci pour vos futurs commentaires qui ne maqueront pas d'améliorer ce projet.


Pourquoi ce projet ?
Etant utilisateur de solution parfeu/routeur logiciel GNU, J'ai testé beaucoup de solution IPFire, IPcop ... etc
mon choix s'est arreter sur SmoothWall pour l'ergonomie de la configuration étant débutant je comprenait plus intuitivement la configuration du par feur avec leur interface.
Néanmoins toutes ces solutions utilisé ont un gros défaut trop souvent négliger. Ces solutions demandent un hardware extremement consomateur d'energie, même pour une configuration minimal, et au jour ou j'écrit cet article, les configurations minimal préconiser ne sufisent plus, avec la démocratisation de la fibre, on ne peut pas imaginer un firewall/routeur sans conexion Gigabit.
Exemple un firewall avec DMZ+ "n Zone physique" aura besoint de 2 carte Giga + "n Zone" carte Giga, ce qui demandera un materiel asser rescent. Dans ma derniere configuration "avec du materiel dit obsolete", le firewall consommer 100W et pour une machine alumé 24h/24h cela n'est pas du tout écologique et économique sous tous les points de vue.
Ma reflexion a donc porté sur ses 2 points: ECOLOGIE et ECONOMIE.

J'ai découvert depuis quelques années le monde des nanos PC (Architecture ARM) avec l'arrivée du "Raspberry pi".
    Technologie Low consomation permetant de faire des Firewall/routeur, malheuresement meme avec les dernières version ces nano PC manquent cruellement de puissance réseau ( inteface 100Mbit ) et meme avec l'ajout d'usb/lan Gigabit on est Brider par l'usb2 du boitier.
    
J'ai tester plusieur type de nano PC avant de m'arreter sur l'ODROID XU4 carte reseau integrer Giga 1 port usb2 et 2port usb3

Ce projet de parfeu est basé sur cette technologie.
A cette heure avec une version beta de scripts le nanoPC est pleinement opérationele avec une puisance consommer de 6W 

Ces scripts on était réalisé grace aux articles suivants:

Posted on 17/12/2015 by fred
https://memo-linux.com/configurer-un-simple-petit-routeur-nat-sous-debian-jessie/

Copyright © 2004 L'équipe Freeduc-Sup
http://www.linux-france.org/prj/edu/archinet/systeme/ch62s03.html

Copyright © 2005 par Red Hat, Inc.
http://web.mit.edu/rhel-doc/4/RH-DOCS/rhel-sg-fr-4/s1-firewall-ipt-fwd.html

minimoi 01/03/2012
http://www.admin6.fr/2012/03/regles-de-routage-simple-avec-iptables/

Redhad
https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/4/html/Security_Guide/s1-firewall-ipt-fwd.html

Kmeleon, eks, BeAvEr, maverick62, mydjey
https://doc.ubuntu-fr.org/iptables

par Arnaud de Bermingham révision par Jice, Fred, Jiel
http://lea-linux.org/documentations/Iptables

Posté le 2017-12-05 de TiTi	
https://geekeries.org/2017/12/configuration-avancee-du-firewall-iptables/?cn-reloaded=1

# Prérequis

-Hardware

    odroid XU4 

    2 adaptateur usb/lan ASIX Electronics Corp. AX88179 Gigabit Ethernet

-Software

    Ubuntu 18.04.2 LTS (GNU/Linux 4.14.102-156 armv7l) (buster/sid)

    udev 237-3ubuntu10.13

    iptables 1.6.1-2ubuntu2

    bash 4.4.18-2ubuntu1

