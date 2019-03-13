#!/bin/bash

# Récupération du répertoire d'éxecution du script
rep_firewall=$(dirname $(readlink -f $0))

#Chargement de l'entete de présentation
source "${rep_firewall}/config/entete"
read -s -n1 -p "Appuyez sur une touche pour continuer..."; echo

## chargement des module
modprobe ip_conntrack_ftp
modprobe ip_nat_ftp
modprobe ip_conntrack_irc
modprobe ip_conntrack
modprobe iptable_nat
#le module suivant n'est pas reconnu sous ubuntu bionic
#modprobe iptable_filte

##réinitialisation des tables
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -t nat -F POSTROUTING

####initialisation des variables
port_ssh=60022
# interfaces
source "${rep_firewall}/config/zones_def"
# port routage
source "${rep_firewall}/config/ports_routage"

## Autoriser le trafic local
iptables -A INPUT  -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

##Préréglage en mode fortress
iptables -P INPUT   DROP
iptables -P OUTPUT  DROP
iptables -P FORWARD DROP

echo "# Activation du forwading"
echo 1 > /proc/sys/net/ipv4/ip_forward
echo "# Enable Spoof protection (reverse-path filter) Turn on Source Address Verification in all interfaces to prevent some spoofing attacks"
echo 1 > /proc/sys/net/ipv4/conf/default/rp_filter
echo 1 > /proc/sys/net/ipv4/conf/all/rp_filter
echo "# Enable SYN Cookie"
echo 1 > /proc/sys/net/ipv4/tcp_syncookies
echo "# Do not accept ICMP redirects (prevent some MITM attacks)"
echo 0 > /proc/sys/net/ipv4/conf/all/accept_redirects
echo 0 > /proc/sys/net/ipv6/conf/all/accept_redirects
echo "# Accept ICMP redirects only for gateways listed in our default gateway list (enabled by default)"
echo 1 > /proc/sys/net/ipv4/conf/all/secure_redirects
echo "# Do not send ICMP redirects (we are not a router)"
echo 0 > /proc/sys/net/ipv4/conf/all/send_redirects
echo "# Do not accept IP source route packets (we are not a router)"
echo 0 > /proc/sys/net/ipv4/conf/all/accept_source_route
echo 0 > /proc/sys/net/ipv6/conf/all/accept_source_route
echo "#do not allow ACK pkts to create new connection (normal behavior SYN->, <-SYN,ACK, ACK->)"
echo 0 > /proc/sys/net/netfilter/nf_conntrack_tcp_loose
echo "#enable TCP timestamps as SYN cookies utilize this TCP"
echo 1 > /proc/sys/net/ipv4/tcp_timestamps
echo
echo "Quelque Tweaks"
echo "#Conntrack Entry Tuning (Calculate your own values ! depending on your hardware)"
echo 200000 > /proc/sys/net/netfilter/nf_conntrack_max
echo 500000 > /sys/module/nf_conntrack/parameters/hashsize
sysctl -p

## anti DOS
iptables -A INPUT -m state --state INVALID -j DROP


##Pour permettre à une connexion déjà ouverte de recevoir du trafic
iptables -A INPUT  -i "${int01_iface}"  -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -o "${int01_iface}"  -j ACCEPT
iptables -A INPUT  -i "${zone01_iface}" -j ACCEPT
iptables -A OUTPUT -o "${zone01_iface}" -j ACCEPT
iptables -A INPUT  -i "${zone02_iface}" -j ACCEPT
iptables -A OUTPUT -o "${zone02_iface}" -j ACCEPT

## On autorise les ports necessaires a notre configuration serveur :
iptables -A INPUT  -i "${int01_iface}"    -p tcp --dport ${port_ssh} -j ACCEPT
#iptables -A INPUT  -i "${int01_iface}"    -p tcp --dport 60443 -j ACCEPT

## autorisation de forward int<-->zone01 pour les liens établies, cette zone est une zone de travail
iptables -A FORWARD -i "${zone01_iface}" -o "${int01_iface}"  -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i "${int01_iface}"  -o "${zone01_iface}" -m state --state ESTABLISHED,RELATED     -j ACCEPT
## autorisation de forward int<-->zone02 pour les liens établies, cette zone est une dmz
iptables -A FORWARD -i "${zone02_iface}" -o "${int01_iface}"  -j ACCEPT
iptables -A FORWARD -i "${int01_iface}"  -o "${zone02_iface}" -j ACCEPT
## autorisation de forward zone01-->zone02, pour les liens établies
# tout ce qui vient de la zone01 en direction de la zone02 est accepter
iptables -A FORWARD -i "${zone01_iface}" -o "${zone02_iface}" -j ACCEPT
iptables -A FORWARD -i "${zone02_iface}" -o "${zone01_iface}" -m state --state ESTABLISHED,RELATED -j ACCEPT

## Mise en place du masquerade
# a l'exeption de tout ce qui est a destination de l'ip internet
# ce qui permet un rebouclage sur les service interne avec un DNS externe
iptables -t nat -A POSTROUTING -o "${int01_iface}" -s "${zone01_network}" -j MASQUERADE
iptables -t nat -A POSTROUTING -o "${int01_iface}" -s "${zone02_network}" -j MASQUERADE
# Mise en place du routage de port
for i in "${!port_routage[@]}"
    do
    service_name=`echo "${port_routage[$i]}" | cut -d "|" -f1`
    proto=`echo "${port_routage[$i]}" | cut -d "|" -f2`
    int01_port=`echo "${port_routage[$i]}" | cut -d "|" -f3`
    ip_destination=`echo "${port_routage[$i]}" | cut -d "|" -f4`
    port_destination=`echo "${port_routage[$i]}" | cut -d "|" -f5`
    echo "${service_name}"
    echo "iptables -t nat -A PREROUTING -d \"${int01_ip}\" -p \"${proto}\" --dport \"${int01_port}\" -j DNAT --to-destination \"${ip_destination}:${port_destination}\""
    iptables -t nat -A PREROUTING  -d "${int01_ip}" -p "${proto}" --dport "${int01_port}" -j DNAT --to-destination "${ip_destination}:${port_destination}"
    done

## on bloque tout le reste
iptables -A INPUT -i "${int01_iface}"    -j REJECT
iptables -A INPUT -i "${zone02_iface}" -j REJECT

iptables -nvL --line-number
iptables -t nat -vL --line-number
