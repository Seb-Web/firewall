# firewall
Scripts Firewall Routeur basé sur iptables

Réalisation d'un parefeu routeur à partir de scripts iptables.
Compatible avec les distributions linux Debian et indépendant de l'architecture matériel

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

le développement est réalisé sur un odroid XU4 équipé de 2 adaptateur usb/lan ASIX Electronics Corp. AX88179 Gigabit Ethernet

-Software

Ubuntu 18.04.2 LTS (GNU/Linux 4.14.102-156 armv7l) (buster/sid)
udev 237-3ubuntu10.13
iptables 1.6.1-2ubuntu2
bash 4.4.18-2ubuntu1

