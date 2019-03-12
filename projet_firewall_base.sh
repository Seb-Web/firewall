#!/bin/bash

#
#Réalistion d'un firewall sur la base d'"iptables"
#
#
#code de base:
#

#                     -----
#                     | F |----| Zone 01 |
#                     | I |
#                     | R |----| zone 02 |
# ----| internet |----| E |
#                     | W |----| zone 03 |
#                     | A |        |
#                     | L |        |
#                     | L |----| zone 99 |
#                     -----
#
#
## chargement des module
modprobe ip_conntrack_ftp
modprobe ip_nat_ftp
modprobe ip_conntrack_irc
modprobe ip_conntrack
modprobe iptable_nat

#initialisation des variables
################################
#< à adapter par l'utilisateur >
################################
int_iface="eth0"
int_ip="xxx.xxx.xxx.xxx"
int_network="xxx.xxx.xxx.xxx/xx"
zone01_iface="eth1"
zone01_ip="192.168.0.254"
zone01_network="192.168.0.0/24"
zone02_iface="eth2"
zone02_ip="192.168.1.254"
zone02_network="192.168.1.0/24"
port_ssh="22"
#################################
#</ à adapter par l'utilisateur >
#################################

##réinitialisation des tables
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -t nat -F POSTROUTING

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
echo "#Conntrack Entry Tuning (Calculate your own values ! depending on your hardware)"

echo "Tweak dépendant du hardware"
################################
#< à adapter selon le hardware >
################################
echo 200000 > /proc/sys/net/netfilter/nf_conntrack_max
echo 500000 > /sys/module/nf_conntrack/parameters/hashsize 
#################################
#</ à adapter selon le hardware >
#################################
# prise en compte des Tweak
sysctl -p

## anti DOS
iptables -A INPUT -m state --state INVALID -j DROP

##Pour permettre à une connexion déjà ouverte de recevoir du trafic
iptables -A INPUT  -i "${int_iface}"    -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -o "${int_iface}"    -j ACCEPT
iptables -A INPUT  -i "${zone01_iface}"  -j ACCEPT
iptables -A OUTPUT -o "${zone01_iface}"  -j ACCEPT
iptables -A INPUT  -i "${zone02_iface}" -j ACCEPT
iptables -A OUTPUT -o "${zone02_iface}" -j ACCEPT

## On autorise les ports necessaires a notre configuration serveur :
iptables -A INPUT  -i "${int_iface}"    -p tcp --dport $port_ssh -j ACCEPT

## On refuse les pings entrants sur l'interface internet
iptables -A INPUT -i "${int_iface}"    -p icmp -j DROP
## On autorise les requettes ping sortantes
iptables -A OUTPUT -p icmp -j ACCEPT

## autorisation de forward int<-->zone01 pour les liens établies, cette zone est une zone de travail
iptables -A FORWARD -i "${zone01_iface}" -o "${int_iface}" -j ACCEPT
iptables -A FORWARD -i "${int_iface}"    -o "${zone01_iface}" -m state --state ESTABLISHED,RELATED -j ACCEPT
## autorisation de forward int<-->zone02 pour les liens établies, cette zone est une dmz 
iptables -A FORWARD -i "${zone01_iface}" -o "${int_iface}" -j ACCEPT
iptables -A FORWARD -i "${int_iface}"    -o "${zone02_iface}" -j ACCEPT
## autorisation de forward zone01-->orange, pour les liens établies
# tout ce qui vient de la zone01 en direction de la zone02 est accepter
iptables -A FORWARD -i "${zone01_iface}" -o "${zone02_iface}" -j ACCEPT
iptables -A FORWARD -i "${zone02_iface}" -o "${zone01_iface}" -m state --state ESTABLISHED,RELATED -j ACCEPT

## Mise en place du masquerade
# a l'exeption de tout ce qui est a destination de l'ip internet
# ce qui permet un rebouclage sur les service interne avec un DNS externe
iptables -t nat -A POSTROUTING -o "${int_iface}" ! -d "${int_ip}" -s "${zone01_network}" -j MASQUERADE
iptables -t nat -A POSTROUTING -o "${int_iface}" ! -d "${int_ip}" -s "${zone02_network}" -j MASQUERADE

# Mise en place du routage de port
################################
#< à adapter par l'utilisateur >
################################
#exemple redirection http vers un serveur 192.168.201.100 sur le port 80 sur la zone02
iptables -t nat -A PREROUTING -i "${int_iface}" -p "tcp" --dport "80"  -j DNAT --to-destination "192.168.201.100:80"
#exemple redirection https vers un serveur 192.168.201.100 sur le port 10443 sur la zone02
iptables -t nat -A PREROUTING -i "${int_iface}" -p "tcp" --dport "443" -j DNAT --to-destination "192.168.201.100:10443"

#exemple redirection tcp d'une plage de port 20000 à 20100 vers un serveur 192.168.201.160 à partir du port 20000 sur la zone02
iptables -t nat -A PREROUTING -i "${int_iface}" -p "tcp" --dport "20000:20100" -j DNAT --to-destination "192.168.201.160:20000"
#exemple redirection tcp d'une plage de port 24000 à 24100 vers un serveur 192.168.201.151 à partir du port 30000 sur la zone02
iptables -t nat -A PREROUTING -i "${int_iface}" -p "tcp" --dport "24000:24100" -j DNAT --to-destination "192.168.201.151:30000"

#exemple redirection udp du port 15000 vers un serveur 192.168.201.120 sur le port 15000 sur la zone02
iptables -t nat -A PREROUTING -i "${int_iface}" -p "udp" --dport "15000" -j DNAT --to-destination "192.168.201.120:15000"
#exemple redirection udp du port 15500 vers un serveur 192.168.201.125 sur le port 35001 sur la zone02
iptables -t nat -A PREROUTING -i "${int_iface}" -p "udp" --dport "15500" -j DNAT --to-destination "192.168.201.120:35001"

#exemple redirection udp d'une plage de port 10000 à 10100 vers un serveur 192.168.201.150 à partir du port 10000 sur la zone02
iptables -t nat -A PREROUTING -i "${int_iface}" -p "udp" --dport "10000:10100" -j DNAT --to-destination "192.168.201.150:10000"
#exemple redirection udp d'une plage de port 12000 à 12100 vers un serveur 192.168.201.151 à partir du port 20000 sur la zone02
iptables -t nat -A PREROUTING -i "${int_iface}" -p "udp" --dport "12000:12100" -j DNAT --to-destination "192.168.201.151:20000"
#################################
#</ à adapter par l'utilisateur >
#################################

## on bloque tout le reste
iptables -A INPUT -i "${red_iface}"    -j REJECT
iptables -A INPUT -i "${orange_iface}" -j REJECT

## on liste l'état des tables iptables avec le numero des lignes
iptables -nvL --line-number
iptables -L -t nat --line-number
