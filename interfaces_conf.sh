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
declare -A iface_gateway
declare -A iface_dns
declare -A iface_mac
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
            echo -e "#### Choix n° ${i} ## ${iface_color[${iface_choix[${i}]}]}${iface_choix[${i}]}\033[0m ## ${iface_mac[${i}]} ## ${iface_network[${i}]}/${iface_netmask[${i}]} ## ${iface_address[${i}]}"
            echo
        fi
    done
}

function saisie()
{
    local __in1=$1
    local __in2=$2

    verif="0"

    while [ "$verif" == "0" ]
        do
        echo -n -e "${__in1}"
        read clavier
        if [ "$clavier" == "" ]
            then
            echo "Erreur de saisie !""!"
            else
            verif="1"
            fi
        done
        eval $__in2="'$clavier'"
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
    unset iface_choix
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
                saisie "Quel est votre choix pour l'interface ${iface_color[${couleur}]}${couleur}\033[0m ? " 'iface_choix["${couleur}"]'
                if [ "${iface_choix["${iface_choix["${couleur}"]}"]}" == "" ] 
                    then 
                    iface_choix["${iface_choix["${couleur}"]}"]="${couleur}"
                    break
                    else
                    echo "Ce choix à déjà été parametré."
                    fi
                done
            if [ $couleur == "red" ]
                then
                    while [ true ]
                    do
                        saisie 'dhcp ou static : ' 'iface_inet["${couleur}"]'
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
                saisie 'réseau : ' 'iface_network["${iface_choix["${couleur}"]}"]'
                saisie 'masque réseau : ' 'iface_netmask["${iface_choix["${couleur}"]}"]'
                saisie 'adresse : ' 'iface_address["${iface_choix["${couleur}"]}"]'
                saisie 'passerelle : ' 'iface_gateway["${iface_choix["${couleur}"]}"]'
                saisie 'DNS : ' 'iface_dns["${iface_choix["${couleur}"]}"]'
                fi
            echo
            echo -n "Confirmer (NON/oui) ? "
            read confirm2
            if [ ! "${confirm2}" == "oui" ]
            then
                unset iface_choix["${iface_choix["${couleur}"]}"]
                unset iface_choix["${couleur}"]
            fi
            clear
            done
        done
    iface_dispo
    echo
    echo -n "Confirmer (NON/oui) ? "
    read confirm1
    done

# écriture des règles d'attribution de nom pour les interfaces
echo > "${rep_firewall}/config/udev/rules.d/75-firewall-persistant-net.rules${extention}"
for i in "${!iface_choix[@]}"
    do 
    echo -e "SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", ATTR{address}==\"${iface_mac[${iface_choix["$i"]}]}\", ATTR{dev_id}==\"0x0\", ATTR{type}==\"1\", KERNEL==\"eth*\", NAME=\"$i\"" >> "${rep_firewall}/config/udev/rules.d/75-firewall-persistant-net.rules${extention}"

    done
ln -sf "${rep_firewall}/config/udev/rules.d/75-firewall-persistant-net.rules${extention}" "/etc/udev/rules.d/75-firewall-persistant-net.rules${extention}"