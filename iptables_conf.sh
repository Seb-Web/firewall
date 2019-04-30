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

iface_address[${zone_iface["wan1"]}]="`ip a show "${iface_name[${zone_iface["wan1"]}]}" | grep "inet " | sed -E "s/ +/ /g" | cut -d" " -f3 | cut -d"/" -f1`"
# port routage
source "${rep_config}/ports_routage.conf"

# acces externe
source "${rep_config}/acces_externe.conf"

## Autoriser le trafic local
iptables -A INPUT  -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

##### ne pas perdre la main pendant la phase de dev 
iptables -A INPUT  -i "${iface_name[${zone_iface["lan1"]}]}" -s 192.168.200.20 -j ACCEPT
iptables -A OUTPUT -o "${iface_name[${zone_iface["lan1"]}]}" -d 192.168.200.20 -j ACCEPT
##### /ne pas perdre la main pendant la phase de dev 

##Préréglage en mode fortress
iptables -P INPUT   DROP
iptables -P OUTPUT  DROP
iptables -P FORWARD DROP

## Réglages kernel
source "${rep_config}/kernel_net.conf"
sysctl -p

## anti DOS
iptables -A INPUT -m state --state INVALID -j DROP

## Blocage de l'icmp autre que pour la zone1
iptables -A INPUT -i int1 -p icmp -s 0.0.0.0/0 -j DROP

##Pour permettre à une connexion déjà ouverte de recevoir du trafic
echo "####"
for zone_name in "${!zone_iface[@]}"
do
    if [[ "${iface_name[${zone_iface[${zone_name}]}]}" =~ ^lan ]]
    then
        echo "iptables -A INPUT  -i "${iface_name[${zone_iface[${zone_name}]}]}" -j ACCEPT"
        iptables -A INPUT  -i "${iface_name[${zone_iface[${zone_name}]}]}" -j ACCEPT
        echo "iptables -A OUTPUT -o "${iface_name[${zone_iface[${zone_name}]}]}" -j ACCEPT"
        iptables -A OUTPUT -o "${iface_name[${zone_iface[${zone_name}]}]}" -j ACCEPT
    elif [[ "${iface_name[${zone_iface[${zone_name}]}]}" =~ ^wan ]]
    then
        echo "iptables -A INPUT  -i "${iface_name[${zone_iface[${zone_name}]}]}"  -m state --state ESTABLISHED,RELATED -j ACCEPT"
        iptables -A INPUT  -i "${iface_name[${zone_iface[${zone_name}]}]}"  -m state --state ESTABLISHED,RELATED -j ACCEPT
        echo "iptables -A OUTPUT -o "${iface_name[${zone_iface[${zone_name}]}]}"  -j ACCEPT"
        iptables -A OUTPUT -o "${iface_name[${zone_iface[${zone_name}]}]}"  -j ACCEPT
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
    echo "${param_nom} --> iptables -A INPUT  -i \"${iface_name[${zone_iface["wan1"]}]}\" -s \"${param_source}\" -p \"${param_proto}\" --dport \"${param_port}\" -j ACCEPT"
    iptables -A INPUT  -i "${iface_name[${zone_iface["wan1"]}]}" -s "${param_source}" -p "${param_proto}" --dport "${param_port}" -j ACCEPT
    done
echo "###############################################"
echo "########## AUTORISATION DES FORWARD ###########"
for zone_name in "${!zone_iface[@]}"
do
    if [[ "$zone_name" =~ ^lan ]]
    then
        echo "iptables -A FORWARD -i \"${iface_name[${zone_iface[${zone_name}]}]}\" -o \"${iface_name[${zone_iface["wan1"]}]}\" -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT"
        iptables -A FORWARD -i "${iface_name[${zone_iface[${zone_name}]}]}" -o "${iface_name[${zone_iface["wan1"]}]}" -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
        echo "iptables -A FORWARD -i \"${iface_name[${zone_iface["wan1"]}]}\"  -o \"${iface_name[${zone_iface[${zone_name}]}]}\" -m state --state ESTABLISHED,RELATED     -j ACCEPT"
        iptables -A FORWARD -i "${iface_name[${zone_iface["wan1"]}]}"  -o "${iface_name[${zone_iface[${zone_name}]}]}" -m state --state ESTABLISHED,RELATED     -j ACCEPT
    fi
done

for zone_name in "${!zone_iface[@]}"
do
    if [[ ! "$zone_name" =~ ^wan ]] && [ ! "$zone_name" == "lan1" ]
    then
        echo "iptables -A FORWARD -i \"${iface_name[${zone_iface["lan1"]}]}\" -o \"${iface_name[${zone_iface[${zone_name}]}]}\" -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT"
        iptables -A FORWARD -i "${iface_name[${zone_iface["lan1"]}]}" -o "${iface_name[${zone_iface[${zone_name}]}]}" -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
        echo "iptables -A FORWARD -i \"${iface_name[${zone_iface[${zone_name}]}]}\" -o \"${iface_name[${zone_iface["lan1"]}]}\" -m state --state ESTABLISHED,RELATED -j ACCEPT"
        iptables -A FORWARD -i "${iface_name[${zone_iface[${zone_name}]}]}" -o "${iface_name[${zone_iface["lan1"]}]}" -m state --state ESTABLISHED,RELATED -j ACCEPT
    fi
done

echo "###############################################"
echo
## Mise en place du masquerade
echo "######### MISE EN PLACE DU MASQUERADE #########"
echo "iptables -t nat -A POSTROUTING -o \"${iface_name[${zone_iface["wan1"]}]}\" -s \"${iface_network[${zone_iface["lan1"]}]}\" -j MASQUERADE"
iptables -t nat -A POSTROUTING -o "${iface_name[${zone_iface["wan1"]}]}" -s "${iface_network[${zone_iface["lan1"]}]}" -j MASQUERADE
echo "iptables -t nat -A POSTROUTING -o \"${iface_name[${zone_iface["wan1"]}]}\" -s \"${iface_network[${zone_iface["lan2"]}]}\" -j MASQUERADE"
iptables -t nat -A POSTROUTING -o "${iface_name[${zone_iface["wan1"]}]}" -s "${iface_network[${zone_iface["lan2"]}]}" -j MASQUERADE

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
    echo "iptables -t nat -A PREROUTING -d \"${iface_address[${zone_iface["wan1"]}]}\" -p \"${proto}\" --dport \"${int1_port}\" -j DNAT --to-destination \"${ip_destination}:${port_destination}\""
    iptables -t nat -A PREROUTING  -d "${iface_address[${zone_iface["wan1"]}]}" -p "${proto}" --dport "${int1_port}" -j DNAT --to-destination "${ip_destination}:${port_destination}"
    # On autorise le forward pour les ports ouverts
    echo "iptables -A FORWARD -i \"${iface_name[${zone_iface["wan1"]}]}\" -p \"${proto}\" --dport \"${int1_port}\" -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT"
    iptables -A FORWARD -i ${iface_name[${zone_iface["wan1"]}]} -p "${proto}" --dport "${int1_port}" -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
    done
echo "###############################################"
echo

## on bloque tout le reste
iptables -A INPUT -i "${iface_name[${zone_iface["wan1"]}]}" -j REJECT
iptables -A INPUT -i "${iface_name[${zone_iface["lan1"]}]}" -j REJECT

iptables -nvL --line-number
iptables -t nat -nvL --line-number
