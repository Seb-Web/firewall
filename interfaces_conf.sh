#!/bin/bash

# Récupération du répertoire d'éxecution du script
rep_firewall=$(dirname $(readlink -f $0))

# Récupération des informations sur les interfaces réseau detecté par le système
declare -A interface_iface
declare -A interface_mac
declare -A interface_model
declare -A interface_vendor
declare -A interface_choix
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

# restitution des informations en vue d'un traitement utilisateur
echo -e "le système a détecté ${#interface_mac[@]} carte réseau"

for (( i=1;i<$count; i++))
    do
    echo -e "#### Choix n° ${i}"
    echo -e "# ${interface_mac[${i}]}"
    echo -e "# ${interface_model[${i}]}"
    echo -e "# ${interface_vendor[${i}]}"
    echo -e "####"
    echo
    done

# Parametrage des cartes réseaux
confirmation="non"
while [ ! "${confirmation}" == "oui" ]
    do
    echo -n -e "Quel est votre choix pour l'interface \033[31mRED\033[0m ? "
    read interface_choix["red"]
    echo -n -e "Quel est votre choix pour l'interface \033[32mGREEN\033[0m ? "
    read interface_choix["green"]
    echo -n -e "Quel est votre choix pour l'interface \033[33mORANGE\033[0m ? "
    read interface_choix["orange"]
    echo
    echo -e "\033[31mRED    = ${interface_mac[${interface_choix["red"]}]}\033[0m"
    echo -e "\033[32mGREEN  = ${interface_mac[${interface_choix["green"]}]}\033[0m"
    echo -e "\033[33mORANGE = ${interface_mac[${interface_choix["orange"]}]}\033[0m"
    echo
    echo -n "Confirmer (NON/oui) ? "
    read confirmation
    done

# écriture des règles d'attribution de nom pour les interfaces
echo > "${rep_firewall}/config/udev/rules.d/75-firewall-persistant-net.rules"
for i in "${!interface_choix[@]}"
    do 
    echo -e "SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", ATTR{address}==\"${interface_mac[${interface_choix["$i"]}]}\", ATTR{dev_id}==\"0x0\", ATTR{type}==\"1\", KERNEL==\"eth*\", NAME=\"$i\"" >> "${rep_firewall}/config/udev/rules.d/75-firewall-persistant-net.rules"

    done
ln -sf "${rep_firewall}/config/udev/rules.d/75-firewall-persistant-net.rules" "/etc/udev/rules.d/75-firewall-persistant-net.rules"