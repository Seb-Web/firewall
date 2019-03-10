#!/bin/bash
extention=".dev"
# Déclaration des variables
# déclaration de l'architecture firewall

declare -A iface_name
declare -A iface_color=( ["red"]="\033[31m" ["green"]="\033[32m" ["orange"]="\033[33m" )
declare -A iface_inet=( ["red"]="dhcp" ["green"]="static" ["orange"]="static" )
declare -A iface_address
declare -A iface_network
declare -A iface_netmask
declare -A iface_broadcast
declare -A iface_gateway
declare -A iface_dns
declare -A iface_mac
declare -A iface_model
declare -A iface_vendor
declare -A iface_zone
declare -A iface_choix


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
            echo -e "#### Choix n° ${i} ## ${iface_color[${iface_choix[${i}]}]}${iface_choix[${i}]}\033[0m ## ${iface_mac[${i}]} ## ${iface_network[${i}]}/${iface_netmask[${i}]} ## ${iface_address[${i}]}"
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
    unset iface_zone
    unset iface_choix
    declare -A iface_zone
    declare -A iface_choix

    for couleur in "${!iface_color[@]}"
        do
        confirm2="non"
        while [ ! "${confirm2}" == "oui" ]
            do
            iface_dispo
            # on boucle sur la demande de choix, tant que l'on ne choisi pas une carte non configurer
            while [ true ]
                do            
                saisie "Quel est votre choix pour l'interface ${iface_color[${couleur}]}${couleur}\033[0m ? " 'iface_zone["${couleur}"]' '^[0-9]+'
                if [ "${iface_choix["${iface_zone["${couleur}"]}"]}" == "" ] 
                    then 
                    iface_choix["${iface_zone["${couleur}"]}"]="${couleur}"
                    break
                    else
                    echo "Ce choix à déjà été parametré."
                    fi
                done
            if [ $couleur == "red" ]
                then
                    while [ true ]
                    do
                        saisie 'dhcp ou static : ' 'iface_inet["${couleur}"]' '^(dhcp|static)$'
                        if [ "${iface_inet["${couleur}"]}" == "static" ]
                            then 
                            iface_inet["${couleur}"]="static"
                            break
                            elif [ "${iface_inet["${couleur}"]}" == "dhcp" ]
                            then 
                            iface_inet["${couleur}"]="dhcp"
                            break
                            fi
                        echo "erreur de saisie !""!"
                    done
                fi
            if [ "${iface_inet[${couleur}]}" == "static" ]
                then
                saisie 'réseau : ' 'iface_network["${iface_zone["${couleur}"]}"]' '^(((2[0-5]{2})|(1{0,1}[0-9]{1,2}))\.){3}((2[0-5]{2})|(1{0,1}[0-9]{1,2}))$'
                saisie 'masque réseau : ' 'iface_netmask["${iface_zone["${couleur}"]}"]' '^(((2[0-5]{2})|(1{0,1}[0-9]{1,2}))\.){3}((2[0-5]{2})|(1{0,1}[0-9]{1,2}))$'
                saisie 'adresse de broadcast : ' 'iface_broadcast["${iface_zone["${couleur}"]}"]' '^(((2[0-5]{2})|(1{0,1}[0-9]{1,2}))\.){3}((2[0-5]{2})|(1{0,1}[0-9]{1,2}))$'
                saisie 'adresse : ' 'iface_address["${iface_zone["${couleur}"]}"]' '^(((2[0-5]{2})|(1{0,1}[0-9]{1,2}))\.){3}((2[0-5]{2})|(1{0,1}[0-9]{1,2}))$' 
                if [ $couleur == "red" ]
                    then
                    saisie 'passerelle : ' 'iface_gateway["${iface_zone["${couleur}"]}"]' '^(((2[0-5]{2})|(1{0,1}[0-9]{1,2}))\.){3}((2[0-5]{2})|(1{0,1}[0-9]{1,2}))$'
                    saisie 'DNS : ' 'iface_dns["${iface_zone["${couleur}"]}"]' '^(((2[0-5]{2})|(1{0,1}[0-9]{1,2}))\.){3}((2[0-5]{2})|(1{0,1}[0-9]{1,2}))$'
                    fi
                fi
            echo
            echo -n "Confirmer (NON/oui) ? "
            read confirm2
            if [ ! "${confirm2}" == "oui" ]
            then
                unset iface_choix["${iface_zone["${couleur}"]}"]
                unset iface_zone["${couleur}"]
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
for zone in "${!iface_zone[@]}"
    do
    echo > "${rep_firewall}/config/etc/network/interfaces.d/${zone}"
    echo "auto ${zone}" >> "${rep_firewall}/config/etc/network/interfaces.d/${zone}"
    if [ "${iface_inet["${iface_choix[${iface_zone["${zone}"]}]}"]}" == "dhcp" ]
        then
        echo "iface ${zone} inet dhcp" >> "${rep_firewall}/config/etc/network/interfaces.d/${zone}"
        else
        echo "iface ${zone} inet static" >> "${rep_firewall}/config/etc/network/interfaces.d/${zone}"
        echo "  network ${iface_network["${iface_zone["${zone}"]}"]}" >> "${rep_firewall}/config/etc/network/interfaces.d/${zone}"
        echo "  netmask ${iface_netmask["${iface_zone["${zone}"]}"]}" >> "${rep_firewall}/config/etc/network/interfaces.d/${zone}"
        echo "  address ${iface_address["${iface_zone["${zone}"]}"]}" >> "${rep_firewall}/config/etc/network/interfaces.d/${zone}"
        echo "  broadcast ${iface_broadcast["${iface_zone["${zone}"]}"]}" >> "${rep_firewall}/config/etc/network/interfaces.d/${zone}"
        if [ "${zone}" == "red" ]
            then
            echo "  gateway ${iface_gateway["${iface_zone["${zone}"]}"]}" >> "${rep_firewall}/config/etc/network/interfaces.d/${zone}"
            echo "  dns-nameservers ${iface_dns["${iface_zone["${zone}"]}"]}" >> "${rep_firewall}/config/etc/network/interfaces.d/${zone}"
            fi
        fi
    done
