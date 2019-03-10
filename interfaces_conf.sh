#!/bin/bash
extention=".dev"
# Déclaration des variables
# déclaration de l'architecture firewall

declare -A zone_color=( ["red"]="\033[31m" ["green"]="\033[32m" ["orange"]="\033[33m" )
declare -A zone_inet=( ["red"]="dhcp" ["green"]="static" ["orange"]="static" )
declare -A zone_choix
declare -A iface_name
declare -A iface_mac
declare -A iface_address
declare -A iface_network
declare -A iface_netmask
declare -A iface_broadcast
declare -A iface_gateway
declare -A iface_dns
declare -A iface_model
declare -A iface_vendor


# Déclaration des fonction
function iface_dispo()
{
    echo -e "le système a détecté ${#iface_mac[@]} carte réseau"
    echo
    for (( i=1;i<$count; i++))
        do
        if [ "${iface_choix["${i}"]}" == "" ]
            then
            echo -e "#### Choix n° ${i}"
            echo -e "# ${iface_mac[${i}]}"
            echo -e "# ${iface_model[${i}]}"
            echo -e "# ${iface_vendor[${i}]}"
            echo -e "####"
            echo
        else
            echo -e "#### Choix n° ${i} ## ${zone_color[${iface_choix[${i}]}]}${iface_choix[${i}]}\033[0m ## ${iface_mac[${i}]} ## ${iface_network[${i}]}/${iface_netmask[${i}]} ## ${iface_address[${i}]}"
            echo
        fi
    done
}

function saisie()
{
    local __texte=$1
    local __variable=$2
    local __regex=$3

    verif="0"
    while [ "$verif" == "0" ]
        do
        echo -n -e "${__texte}"
        read __saisie
        if [[ "${__saisie}" =~ $__regex ]]
            then
            verif="1"
            else
            echo "Erreur de saisie !""!"
            fi
        done
        eval $__variable="'${__saisie}'"
}
# Récupération du répertoire d'éxecution du script
rep_firewall=$(dirname $(readlink -f $0))

# Récupération des informations sur les interfaces réseau detecté par le système
count=1
for iface in `ls /sys/class/net`
    do
    if [ -d "/sys/class/net/${iface}/device" ]
        then
        iface_mac[${count}]=`cat /sys/class/net/${iface}/address`
        while read line
            do
            if [[ $line =~ ^"E: ID_MODEL_FROM_DATABASE" ]]
                then
                iface_model[${count}]=`echo ${line} | grep -E "ID_MODEL_FROM_DATABASE" | cut -d "=" -f2`
                fi
            if [[ $line =~ ^"E: ID_VENDOR_FROM_DATABASE" ]]
                then
                iface_vendor[${count}]=`echo ${line} | grep -E "ID_VENDOR_FROM_DATABASE" | cut -d "=" -f2`
                fi
            done < <(udevadm info "/sys/class/net/${iface}/device/driver"/*)
        count=$(($count+1))
        fi
    done

# Paramétrage des cartes réseaux
confirm1="non"
while [ ! "${confirm1}" == "oui" ]
    do
    clear
    unset zone_choix
    declare -A zone_choix

    for couleur in "${!zone_color[@]}"
        do
        confirm2="non"
        while [ ! "${confirm2}" == "oui" ]
            do
            iface_dispo
            # on boucle sur la demande de choix, tant que l'on ne choisi pas une carte non configurer
            while [ true ]
                do            
                saisie "Quel est votre choix pour l'interface ${zone_color[${couleur}]}${couleur}\033[0m ? " 'zone_choix["${couleur}"]' '^[0-9]+'
                if [ ! "${zone_choix["${couleur}"]}" == "" ] 
                    then 
                    break
                    else
                    echo "Ce choix à déjà été parametré."
                    fi
                done
            if [ $couleur == "red" ]
                then
                saisie 'dhcp ou static : ' 'iface_inet["${zone_choix[${couleur}]}"]' '^(dhcp|static)$'
                fi

            if [ "${iface_inet[${zone_choix[${couleur}]}]}" == "static" ]
                then
                saisie 'réseau : ' 'iface_network["${zone_choix[${couleur}]}"]}"]' '^(((2[0-5]{2})|(1{0,1}[0-9]{1,2}))\.){3}((2[0-5]{2})|(1{0,1}[0-9]{1,2}))$'
                saisie 'masque réseau : ' 'iface_netmask["${zone_choix[${couleur}]}"]' '^(((2[0-5]{2})|(1{0,1}[0-9]{1,2}))\.){3}((2[0-5]{2})|(1{0,1}[0-9]{1,2}))$'
                saisie 'adresse de broadcast : ' 'iface_broadcast["${zone_choix[${couleur}]}"]' '^(((2[0-5]{2})|(1{0,1}[0-9]{1,2}))\.){3}((2[0-5]{2})|(1{0,1}[0-9]{1,2}))$'
                saisie 'adresse : ' 'iface_address["${zone_choix[${couleur}]}"]' '^(((2[0-5]{2})|(1{0,1}[0-9]{1,2}))\.){3}((2[0-5]{2})|(1{0,1}[0-9]{1,2}))$' 
                if [ $couleur == "red" ]
                    then
                    saisie 'passerelle : ' 'iface_gateway["${zone_choix[${couleur}]}"]' '^(((2[0-5]{2})|(1{0,1}[0-9]{1,2}))\.){3}((2[0-5]{2})|(1{0,1}[0-9]{1,2}))$'
                    saisie 'DNS : ' 'iface_dns["${zone_choix[${couleur}]}"]}"]' '^(((2[0-5]{2})|(1{0,1}[0-9]{1,2}))\.){3}((2[0-5]{2})|(1{0,1}[0-9]{1,2}))$'
                    fi
                fi
            echo
            echo -n "Confirmer (NON/oui) ? "
            read confirm2
            if [ ! "${confirm2}" == "oui" ]
            then
                unset zone_choix["${couleur}"]
            fi
            clear
            done
        done
    iface_dispo
    echo
    echo -n "Confirmer (NON/oui) ? "
    read confirm1
    done
###
# écriture des règles d'attribution de nom pour les interfaces

echo > "${rep_firewall}/config/udev/rules.d/75-firewall-persistant-net.rules${extention}"
for i in "${!iface_zone_choix[@]}"
    do 
    echo -e "SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", ATTR{address}==\"${iface_mac[${iface_zone_choix["$i"]}]}\", ATTR{dev_id}==\"0x0\", ATTR{type}==\"1\", KERNEL==\"eth*\", NAME=\"$i\"" >> "${rep_firewall}/config/udev/rules.d/75-firewall-persistant-net.rules${extention}"

    done
ln -sf "${rep_firewall}/config/udev/rules.d/75-firewall-persistant-net.rules${extention}" "/etc/udev/rules.d/75-firewall-persistant-net.rules${extention}"

##
# ecriture de la Configuration des interface
for zone in "${!zone_choix[@]}"
    do
    echo > "${rep_firewall}/config/etc/network/interfaces.d/${zone}"
    echo "auto ${zone}" >> "${rep_firewall}/config/etc/network/interfaces.d/${zone}"
    if [ "${iface_inet["${zone_choix[${zone}"]}]}" == "dhcp" ]
        then
        echo "iface ${zone} inet dhcp" >> "${rep_firewall}/config/etc/network/interfaces.d/${zone}"
        else
        echo "iface ${zone} inet static" >> "${rep_firewall}/config/etc/network/interfaces.d/${zone}"
        echo "  network ${iface_network["${zone_choix["${zone}"]}"]}" >> "${rep_firewall}/config/etc/network/interfaces.d/${zone}"
        echo "  netmask ${iface_netmask["${zone_choix["${zone}"]}"]}" >> "${rep_firewall}/config/etc/network/interfaces.d/${zone}"
        echo "  address ${iface_address["${zone_choix["${zone}"]}"]}" >> "${rep_firewall}/config/etc/network/interfaces.d/${zone}"
        echo "  broadcast ${iface_broadcast["${zone_choix["${zone}"]}"]}" >> "${rep_firewall}/config/etc/network/interfaces.d/${zone}"
        if [ "${zone}" == "red" ]
            then
            echo "  gateway ${iface_gateway["${zone_choix["${zone}"]}"]}" >> "${rep_firewall}/config/etc/network/interfaces.d/${zone}"
            echo "  dns-nameservers ${iface_dns["${zone_choix["${zone}"]}"]}" >> "${rep_firewall}/config/etc/network/interfaces.d/${zone}"
            fi
        fi
    done
