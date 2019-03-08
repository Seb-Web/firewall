#!/bin/bash
extention=".dev"
# Déclaration des variables
# déclaration de l'architecture firewall
declare -A interface_couleur=( ["red"]="\033[31m" ["green"]="\033[32m" ["orange"]="\033[33m" )

declare -A interface_iface
declare -A interface_address
declare -A interface_network
declare -A interface_netmask
declare -A interface_gateway
declare -A interface_dns
declare -A interface_mac
declare -A interface_model
declare -A interface_vendor

# Déclaration des fonction
interface_dispo()
{
    echo -e "le système a détecté ${#interface_mac[@]} carte réseau"
    echo
    for (( i=1;i<$count; i++))
        do
        if [ "${interface_choix["${i}"]}" == "" ]
            then
            echo -e "#### Choix n° ${i}"
            echo -e "# ${interface_mac[${i}]}"
            echo -e "# ${interface_model[${i}]}"
            echo -e "# ${interface_vendor[${i}]}"
            echo -e "####"
            echo
        else
            echo -e "#### Choix n° ${i} ## ${interface_couleur[${interface_choix[${i}]}]}${interface_choix[${i}]}\033[0m ## ${interface_mac[${i}]} ## ${interface_network[${i}]}/${interface_netmask[${i}]} ## ${interface_address[${i}]}"
            echo
        fi
    done
}
# Récupération du répertoire d'éxecution du script
rep_firewall=$(dirname $(readlink -f $0))

# Récupération des informations sur les interfaces réseau detecté par le système
count=1
for iface in `ls /sys/class/net`
    do
    if [ -d "/sys/class/net/${iface}/device" ]
        then
        interface_mac[${count}]=`cat /sys/class/net/${iface}/address`
        while read line
            do
            if [[ $line =~ ^"E: ID_MODEL_FROM_DATABASE" ]]
                then
                interface_model[${count}]=`echo ${line} | grep -E "ID_MODEL_FROM_DATABASE" | cut -d "=" -f2`
                fi
            if [[ $line =~ ^"E: ID_VENDOR_FROM_DATABASE" ]]
                then
                interface_vendor[${count}]=`echo ${line} | grep -E "ID_VENDOR_FROM_DATABASE" | cut -d "=" -f2`
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
    unset interface_choix
    declare -A interface_choix

    for couleur in "${!interface_couleur[@]}"
        do
        confirm2="non"
        while [ ! "${confirm2}" == "oui" ]
            do
            interface_dispo
            echo -n -e "Quel est votre choix pour l'interface ${interface_couleur[${couleur}]}${couleur}\033[0m ? "
            read interface_choix["${couleur}"]
            interface_choix["${interface_choix["${couleur}"]}"]="${couleur}" 
            echo -n "réseau : "    
            read interface_network["${interface_choix["${couleur}"]}"]
            echo -n "masque réseau : "    
            read interface_netmask["${interface_choix["${couleur}"]}"]
            echo -n "adresse : "    
            read interface_address["${interface_choix["${couleur}"]}"]
            echo -n "passerelle : "
            read interface_gateway["${interface_choix["${couleur}"]}"]
            echo -n "DNS : "
            read interface_dns["${interface_choix["${couleur}"]}"]
            echo
            echo -n "Confirmer (NON/oui) ? "
            read confirm2
            if [ ! "${confirm2}" == "oui" ]
            then
                unset interface_choix["${interface_choix["${couleur}"]}"]
                unset interface_choix["${couleur}"]
            fi
            clear
            done
        done
    interface_dispo
    echo
    echo -n "Confirmer (NON/oui) ? "
    read confirm1
    done

# écriture des règles d'attribution de nom pour les interfaces
echo > "${rep_firewall}/config/udev/rules.d/75-firewall-persistant-net.rules${extention}"
for i in "${!interface_choix[@]}"
    do 
    echo -e "SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", ATTR{address}==\"${interface_mac[${interface_choix["$i"]}]}\", ATTR{dev_id}==\"0x0\", ATTR{type}==\"1\", KERNEL==\"eth*\", NAME=\"$i\"" >> "${rep_firewall}/config/udev/rules.d/75-firewall-persistant-net.rules${extention}"

    done
ln -sf "${rep_firewall}/config/udev/rules.d/75-firewall-persistant-net.rules${extention}" "/etc/udev/rules.d/75-firewall-persistant-net.rules${extention}"
