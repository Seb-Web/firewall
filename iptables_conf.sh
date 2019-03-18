#!/bin/bash

# Récupération du répertoire d'éxecution du script
rep_exec=$(dirname $(readlink -f $0))
rep_fonctions="${rep_exec}/fonctions"
rep_config="${rep_exec}/config"
# Chargement des fonctions
source "${rep_fonctions}/fonction_pause.sh"
clear
#Chargement de l'entete de présentation
source "${rep_exec}/entetes/entete_iptables_conf"
pause

## chargement des module
modprobe ip_conntrack_ftp
modprobe ip_nat_ftp
modprobe ip_conntrack_irc
modprobe ip_conntrack
modprobe iptable_nat
modprobe iptable_filter

##réinitialisation des tables
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -t nat -F POSTROUTING

####initialisation des variables

# interfaces
source "${rep_config}/zones_def.conf"
source "${rep_config}/zones_def.dev"
# port routage
source "${rep_config}/ports_routage.conf"
# acces externe
source "${rep_config}/acces_externe.conf"

## Autoriser le trafic local
iptables -A INPUT  -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
##### ne pas perdre la main pendant la phase de dev 
iptables -A INPUT  -i zone1 -s 192.168.200.0/24 -j ACCEPT
iptables -A OUTPUT -o zone1 -d 192.168.200.0/24 -j ACCEPT
##### /ne pas perdre la main pendant la phase de dev 

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

## Blocage de l'icmp autre que pour la zone1
#iptables -A INPUT -p icmp ! -s {$zone1_network} -j DROP

##Pour permettre à une connexion déjà ouverte de recevoir du trafic
echo "####"
for iface_idx in "${!iface_name[@]}"
do
    if [[ "${iface_name[${iface_idx}]}" =~ ^zone ]]
    then
        echo "iptables -A INPUT  -i "${iface_name[${iface_idx}]}" -j ACCEPT"
        iptables -A INPUT  -i "${iface_name[${iface_idx}]}" -j ACCEPT
        echo "iptables -A OUTPUT -o "${iface_name[${iface_idx}]}" -j ACCEPT"
        iptables -A OUTPUT -o "${iface_name[${iface_idx}]}" -j ACCEPT
    elif [[ "${iface_name[${iface_idx}]}" =~ ^int ]]
    then
        echo "iptables -A INPUT  -i "${iface_name[${iface_idx}]}"  -m state --state ESTABLISHED,RELATED -j ACCEPT"
        iptables -A INPUT  -i "${iface_name[${iface_idx}]}"  -m state --state ESTABLISHED,RELATED -j ACCEPT
        echo "iptables -A OUTPUT -o "${iface_name[${iface_idx}]}"  -j ACCEPT"
        iptables -A OUTPUT -o "${iface_name[${iface_idx}]}"  -j ACCEPT
    fi
done

## On autorise les ports necessaires a notre configuration serveur :
echo "######## PARAMATRAGE DES ACCES EXTERNE ########"
echo "###############################################"
for params in "${!acces_externe[@]}"
    do
    param_source=`echo "${acces_externe[${params}]}" | cut -d"|" -f4`
    param_port=`echo "${acces_externe[${params}]}" | cut -d"|" -f3`
    param_proto=`echo "${acces_externe[${params}]}" | cut -d"|" -f2`
    param_nom=`echo "${acces_externe[${params}]}" | cut -d"|" -f1`
    echo "${param_nom} --> iptables -A INPUT  -i \"${int1_iface}\" -s \"${param_source}\" -p \"${param_proto}\" --dport \"${param_port}\" -j ACCEPT"
    iptables -A INPUT  -i "${iface_name[${zone_iface["int1"]}]}" -s "${param_source}" -p "${param_proto}" --dport "${param_port}" -j ACCEPT
    done
echo "###############################################"
echo "########## AUTORISATION DES FORWARD ###########"
for zone_name in "${!zone_iface[@]}"
do
    if [[ "$zone_name" =~ ^zone ]]
    then
        echo "iptables -A FORWARD -i \"${zone_name}\" -o \"int1\"  -j ACCEPT"
        iptables -A FORWARD -i ${zone_name} -o int1  -j ACCEPT
        echo "iptables -A FORWARD -i \"int1\"  -o \"${zone_name}\" -m state --state NEW,ESTABLISHED,RELATED     -j ACCEPT"
        iptables -A FORWARD -i int1  -o ${zone_name} -m state --state NEW,ESTABLISHED,RELATED     -j ACCEPT
    fi

done
## autorisation de forward int<-->zone1 pour les liens établies, cette zone est une zone de travail
#iptables -A FORWARD -i "${zone1_iface}" -o "${int1_iface}"  -j ACCEPT
#iptables -A FORWARD -i "${int1_iface}"  -o "${zone1_iface}" -m state --state NEW,ESTABLISHED,RELATED     -j ACCEPT

## autorisation de forward int<-->zone2 pour les liens établies, cette zone est une dmz
#iptables -A FORWARD -i "${zone2_iface}" -o "${int1_iface}"  -j ACCEPT
#iptables -A FORWARD -i "${int1_iface}"  -o "${zone2_iface}" -m state --state NEW,ESTABLISHED,RELATED     -j ACCEPT


## autorisation de forward zone1-->zone2, pour les liens établies
# tout ce qui vient de la zone1 en direction de la zone2 est accepter
iptables -A FORWARD -i "${zone1_iface}" -o "${zone2_iface}" -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -i "${zone2_iface}" -o "${zone1_iface}" -m state --state ESTABLISHED,RELATED -j ACCEPT
echo "###############################################"
echo
## Mise en place du masquerade
# a l'exeption de tout ce qui est a destination de l'ip internet
# ce qui permet un rebouclage sur les service interne avec un DNS externe
echo "######### MISE EN PLACE DU MASQUERADE #########"
iptables -t nat -A POSTROUTING -o "${int1_iface}" -s "${zone1_network}" -j MASQUERADE
iptables -t nat -A POSTROUTING -o "${int1_iface}" -s "${zone2_network}" -j MASQUERADE
echo "###############################################"
echo
# Mise en place du routage de port
echo "############ MISE EN PLACE DU DNAT ############"
for i in "${!port_routage[@]}"
    do
    service_name=`echo "${port_routage[$i]}" | cut -d "|" -f1`
    proto=`echo "${port_routage[$i]}" | cut -d "|" -f2`
    int1_port=`echo "${port_routage[$i]}" | cut -d "|" -f3`
    ip_destination=`echo "${port_routage[$i]}" | cut -d "|" -f4`
    port_destination=`echo "${port_routage[$i]}" | cut -d "|" -f5`
    echo "${service_name}"
    echo "iptables -t nat -A PREROUTING -i \"${int1_iface}\" -p \"${proto}\" --dport \"${int1_port}\" -j DNAT --to-destination \"${ip_destination}:${port_destination}\""
#       echo "iptables -t nat -A PREROUTING -d \"${int1_address}\" -p \"${proto}\" --dport \"${int1_port}\" -j DNAT --to-destination \"${ip_destination}:${port_destination}\""
    iptables -t nat -A PREROUTING  -i "${int1_iface}" -p "${proto}" --dport "${int1_port}" -j DNAT --to-destination "${ip_destination}:${port_destination}"
    done
echo "###############################################"
echo

## on bloque tout le reste
iptables -A INPUT -i "${int1_iface}"  -j REJECT
iptables -A INPUT -i "${zone2_iface}" -j REJECT

iptables -nvL --line-number
iptables -t nat -nvL --line-number
