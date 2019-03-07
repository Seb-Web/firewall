#!/bin/bash

# Récupération du répertoire d'éxecution du script
rep_firewall=$(dirname $(readlink -f $0))

##réinitialisation des tables
iptables -P INPUT   ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT  ACCEPT
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -t nat -F POSTROUTING

####initialisation des variables
# interfaces
source "${rep_firewall}/config/interfaces"
# port routage
source "${rep_firewall}/config/ports_routage"

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
echo 65536 > /proc/sys/net/netfilter/nf_conntrack_max

##Pour permettre à une connexion déjà ouverte de recevoir du trafic

iptables -A INPUT  -i "${red_iface}"    -m state --state ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o "${red_iface}"    -j ACCEPT
iptables -A INPUT  -i "${green_iface}"  -j ACCEPT
iptables -A OUTPUT -o "${green_iface}"  -j ACCEPT
iptables -A INPUT  -i "${orange_iface}" -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT  -i "${orange_iface}" -d "${red_ip}" -j ACCEPT
iptables -A OUTPUT -o "${orange_iface}" -j ACCEPT


## Autoriser le trafic local
iptables -A INPUT  -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

## On autorise les ports necessaires a notre configuration serveur :
iptables -A INPUT  -i "${red_iface}"    -p tcp --dport 60022 -j ACCEPT

## On autorise les connexion au serveur dns
iptables -A OUTPUT -o "${red_iface}"    -p udp --dport 53  -j ACCEPT
iptables -A INPUT  -i "${red_iface}"    -p udp --dport 53  -j ACCEPT
iptables -A OUTPUT -o "${red_iface}"    -p tcp --dport 53  -j ACCEPT
iptables -A INPUT  -i "${red_iface}"    -p tcp --dport 53  -j ACCEPT

## On autorise les pings entrants
iptables -A INPUT -i "${red_iface}"    -p icmp -j ACCEPT
iptables -A INPUT -i "${orange_iface}" -p icmp -s "${orange_network}" -d "${orange_network}" -j ACCEPT
iptables -A INPUT -i "${green_iface}"  -p icmp -s "${green_network}"  -d "${green_network}"  -j ACCEPT
iptables -A INPUT -i "${green_iface}"  -p icmp -s "${green_network}"  -d "${orange_network}" -j ACCEPT

iptables -A OUTPUT -p icmp -j ACCEPT

## autorisation de forward red<-->orange
iptables -A FORWARD -o "${red_iface}"    -i "${orange_iface}" -j ACCEPT
iptables -A FORWARD -o "${orange_iface}" -i "${red_iface}"    -j ACCEPT
## autorisation de forward red<-->green
iptables -A FORWARD -o "${red_iface}"    -i "${green_iface}"  -j ACCEPT
iptables -A FORWARD -o "${green_iface}"  -i "${red_iface}"    -j ACCEPT
## autorisation de forward green<-->orange
iptables -A FORWARD -o "${green_iface}"  -i "${orange_iface}" -m state --state ESTABLISHED -j ACCEPT
iptables -A FORWARD -o "${orange_iface}" -i "${green_iface}"  -j ACCEPT


## Mise en place du masquerade
iptables -t nat -A POSTROUTING -o "${red_iface}" -s "${orange_network}" -j MASQUERADE
iptables -t nat -A POSTROUTING -o "${red_iface}" -s "${green_network}"  -j MASQUERADE

# Mise en place du routage de port
for i in "${!port_routage[@]}"
	do
	service_name=`echo "${port_routage[$i]}" | cut -d "|" -f1`
	proto=`echo "${port_routage[$i]}" | cut -d "|" -f2`
	red_port=`echo "${port_routage[$i]}" | cut -d "|" -f3`
	ip_destination=`echo "${port_routage[$i]}" | cut -d "|" -f4`
	port_destination=`echo "${port_routage[$i]}" | cut -d "|" -f5`
    echo "${service_name}"
    echo "iptables -t nat -A PREROUTING -i \"${red_iface}\" -p \"${proto}\" --dport \"${red_port}\" -j DNAT --to-destination \"${ip_destination}:${port_destination}\""
    iptables -t nat -A PREROUTING -i "${red_iface}" -p "${proto}" --dport "${red_port}" -j DNAT --to-destination "${ip_destination}:${port_destination}"
	done

## on bloque tout le reste
iptables -A INPUT -i "${red_iface}"    -j REJECT
iptables -A INPUT -i "${orange_iface}" -j REJECT

iptables -nvL
iptables -L -t nat
