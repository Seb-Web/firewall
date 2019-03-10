#!/bin/bash
extention=".dev"
# Déclaration des variables
# déclaration de l'architecture firewall

#Code couleur associé a la zone
declare -A zone_color=( ["red"]="\033[31m" ["green"]="\033[32m" ["orange"]="\033[33m" )
#Inet associé a la zone
declare -A zone_inet=( ["red"]="dhcp" ["green"]="static" ["orange"]="static" )
#Interface associé à la zone de firewall
declare -A zone_choix
#Nom de l'interface
declare -A iface_name
#Zone de firewall associer à l'interface
declare -A iface_zone
#MAC adresse de l'interface
declare -A iface_mac
#inet de l'interface
declare -A iface_inet
#Adresse de l'interface
declare -A iface_address
#Réseau de l'interface
declare -A iface_network
#Mask reseau de l'interface
declare -A iface_netmask
#Broadcast de l'interface
declare -A iface_broadcast
#Passerelle de l'interface
declare -A iface_gateway
#DNS de l'interface
declare -A iface_dns
#Model de l'interface
declare -A iface_model
#Vendeur de l'interface
declare -A iface_vendor


# Déclaration des fonction
function iface_dispo()
{
    echo -e "le système a détecté ${#iface_mac[@]} carte réseau"
    echo
    for (( i=1;i<$count; i++))
        do
        if [ "${iface_zone["${i}"]}" == "" ]
            then
            echo -e "#### Choix n° ${i}"
            echo -e "# ${iface_mac[${i}]}"
            echo -e "# ${iface_model[${i}]}"
            echo -e "# ${iface_vendor[${i}]}"
            echo -e "####"
            echo
        else
            echo -e "#### Choix n° ${i} ## ${zone_color[${iface_zone[${i}]}]}--${iface_zone[${i}]}--\033[0m ## ${iface_mac[${i}]} ## ${iface_network[${i}]}/${iface_netmask[${i}]} ## ${iface_address[${i}]}"
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
    unset iface_zone
    declare -A zone_choix
    declare -A iface_zone
    for couleur in "${!zone_color[@]}"
        do
        confirm2="non"
        while [ ! "${confirm2}" == "oui" ]
            do
            iface_dispo
            # on boucle sur la demande de choix, tant que l'on ne choisi pas une carte non configurer
            while [ true ]
                do            
                saisie "Quel est votre choix pour l'interface ${zone_color[${couleur}]}${couleur}\033[0m ? " 'zone_choix["${couleur}"]' '^[^0][0-9]*$'
                if [ "${iface_zone["${zone_choix["${couleur}"]}"]}" == "" ] 
                    then 
                    iface_zone["${zone_choix["${couleur}"]}"]=${couleur}
                    iface_name["${zone_choix["${couleur}"]}"]=${couleur}
                    break
                    else
                    echo "Ce choix à déjà été parametré."
                    fi
                done
            if [ "${couleur}" == "red" ]
                then
                saisie 'dhcp ou static : ' 'iface_inet["${zone_choix[${couleur}]}"]' '^(dhcp|static)$'
                fi

            if [ "${iface_inet["${zone_choix[${couleur}]}"]}" == "static" ] || [ ! "${couleur}" == "red" ]
                then
                iface_inet["${zone_choix[${couleur}]}"]="static"
                saisie 'réseau : ' 'iface_network["${zone_choix[${couleur}]}"]' '^(((2[0-5]{2})|(1{0,1}[0-9]{1,2}))\.){3}((2[0-5]{2})|(1{0,1}[0-9]{1,2}))$'
                saisie 'masque réseau : ' 'iface_netmask["${zone_choix[${couleur}]}"]' '^(((2[0-5]{2})|(1{0,1}[0-9]{1,2}))\.){3}((2[0-5]{2})|(1{0,1}[0-9]{1,2}))$'
                saisie 'adresse de broadcast : ' 'iface_broadcast["${zone_choix[${couleur}]}"]' '^(((2[0-5]{2})|(1{0,1}[0-9]{1,2}))\.){3}((2[0-5]{2})|(1{0,1}[0-9]{1,2}))$'
                saisie 'adresse : ' 'iface_address["${zone_choix[${couleur}]}"]' '^(((2[0-5]{2})|(1{0,1}[0-9]{1,2}))\.){3}((2[0-5]{2})|(1{0,1}[0-9]{1,2}))$' 
                if [ $couleur == "red" ]
                    then
                    saisie 'passerelle : ' 'iface_gateway["${zone_choix[${couleur}]}"]' '^(((2[0-5]{2})|(1{0,1}[0-9]{1,2}))\.){3}((2[0-5]{2})|(1{0,1}[0-9]{1,2}))$'
                    saisie 'DNS : ' 'iface_dns["${zone_choix[${couleur}]}"]' '^(((2[0-5]{2})|(1{0,1}[0-9]{1,2}))\.){3}((2[0-5]{2})|(1{0,1}[0-9]{1,2}))$'
                    fi
                fi
            echo
            echo -n "Confirmer (NON/oui) ? "
            read confirm2
            if [ ! "${confirm2}" == "oui" ]
                then
                unset iface_name["${zone_choix["${couleur}"]}"]
                unset iface_zone["${zone_choix["${couleur}"]}"]
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

#echo > "${rep_firewall}/config/udev/rules.d/75-firewall-persistant-net.rules${extention}"
for i in "${!iface_name[@]}"
    do 
    echo -e "SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", ATTR{address}==\"${iface_mac[${i}]}\", ATTR{dev_id}==\"0x0\", ATTR{type}==\"1\", KERNEL==\"eth*\", NAME=\"${iface_name[${i}]}\"" 
#>> "${rep_firewall}/config/udev/rules.d/75-firewall-persistant-net.rules${extention}"

    done
#ln -sf "${rep_firewall}/config/udev/rules.d/75-firewall-persistant-net.rules${extention}" "/etc/udev/rules.d/75-firewall-persistant-net.rules${extention}"

###
#écriture de la Configuration des interface
#pour chaque interfaces configurées
for i in "${!iface_name[@]}"
    do
    #ecriture de la configuration de l'interface dans un fichier portant le nom de l'interface
    echo > "${rep_firewall}/config/etc/network/interfaces.d/${iface_name["${i}"]}"
    echo "auto ${iface_name["$i"]}" #>> "${rep_firewall}/config/etc/network/interfaces.d/${iface_name["${i}"]}"
    if [ "${iface_inet["${i}"]}" == "dhcp" ]
        then
        #Si l'interface a été configuré en dhcp 
        echo "iface ${iface_name["${i}"]} inet dhcp" >> "${rep_firewall}/config/etc/network/interfaces.d/${iface_name["${i}"]}"
        elif [ "${iface_inet["${i}"]}" == "static" ]
            then
            #Si l'interface a été configuré en static
            echo "iface ${iface_name["${i}"]} inet static" >> "${rep_firewall}/config/etc/network/interfaces.d/${iface_name["${i}"]}"
            echo "  network ${iface_network["${i}"]}" >> "${rep_firewall}/config/etc/network/interfaces.d/${iface_name["${i}"]}"
            echo "  netmask ${iface_netmask["${i}"]}" >> "${rep_firewall}/config/etc/network/interfaces.d/${iface_name["${i}"]}"
            echo "  address ${iface_address["${i}"]}" >> "${rep_firewall}/config/etc/network/interfaces.d/${iface_name["${i}"]}"
            echo "  broadcast ${iface_broadcast["${i}"]}" >> "${rep_firewall}/config/etc/network/interfaces.d/${iface_name["${i}"]}"
            if [ "${iface_zone["${i}"]}" == "red" ]
                then
                #Si la zone est de type RED et que le inet est static, on parametre la GATEWAY ainsi que le DNS
                echo "  gateway ${iface_gateway["${i}"]}" >> "${rep_firewall}/config/etc/network/interfaces.d/${iface_name["${i}"]}"
                echo "  dns-nameservers ${iface_dns["${i}"]}" >> "${rep_firewall}/config/etc/network/interfaces.d/${iface_name["${i}"]}"
                fi
        fi
    done
