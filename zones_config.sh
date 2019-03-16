#!/bin/bash

clear
# Récupération du répertoire d'éxecution du script en cour
rep_exec=$(dirname $(readlink -f $0))
rep_fonctions="${rep_exec}/fonctions"
# Chargement des fonctions
source "${rep_fonctions}/fonction_pause.sh"
source "${rep_fonctions}/fonction_saisie.sh"
source "${rep_fonctions}/fonction_iface_detect.sh"
source "${rep_fonctions}/fonction_iface_vue.sh"

# Chargement de l'entete
source "${rep_exec}/entetes/entete_zones_config"

# Déclaration des variables
# déclaration de l'architecture firewall

# extentioon sert à modifier l'extention des fichier créer pour un dev
extention=".dev"
#Code couleur associé a la zone
declare -A zone_color=( ["int01"]="\033[31m" ["zone01"]="\033[32m" ["zone02"]="\033[33m" )
#Inet associé a la zone
declare -A zone_inet=( ["int01"]="dhcp" ["zone01"]="static" ["zone02"]="static" )
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

# Récupération des informations sur les interfaces réseau detecté par le système
iface_detect "iface_mac" "iface_model" "iface_vendor"
echo "${#iface_mac[@]}"
iface_vue
zone_nb="10"
echo "##${zone_nb}##${iface_count}##"
while (( "${zone_nb}" > "$((${iface_count}-1))" ))
do
    saisie "Combien de zones voulez-vous configurer ? " "zone_nb" "^[1-9]$"
done
saisie "Quel est votre choix pour l'interface \033[31minternet\033[0m ? " 'zone_choix["int01"]' '^[^0][0-9]*$'
iface_zone[${zone_choix["int01"]}]="int01"
iface_vue
for (( i=1; i<=${zone_nb} ; i++ ))
do
    # on boucle sur la demande de choix, tant que l'on ne choisi pas une carte non configurer
    while [ true ]
    do
        saisie "Quel est votre choix pour la zone ${i} ? " 'zone_choix["zone0${i}"]' '^[^0][0-9]*$'
        if [ "${iface_zone["${zone_choix["zone0${i}"]}"]}" == "" ] 
        then
            iface_zone["${zone_choix["zone0${i}"]}"]="zone0${i}"
            iface_name["${zone_choix["zone0${i}"]}"]="zone0${i}"
            break
        else
            echo "Ce choix à déjà été parametré."
        fi
    done
    iface_vue
done
echo ${#zone_choix[@]}
echo ${!zone_choix[@]}
echo ${zone_choix[@]}
exit

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
            if [ "${couleur}" == "int01" ]
                then
                saisie 'dhcp ou static : ' 'iface_inet["${zone_choix[${couleur}]}"]' '^(dhcp|static)$'
                fi

            if [ "${iface_inet["${zone_choix[${couleur}]}"]}" == "static" ] || [ ! "${couleur}" == "int01" ]
                then
                iface_inet["${zone_choix[${couleur}]}"]="static"
                saisie 'réseau : ' 'iface_network["${zone_choix[${couleur}]}"]' '^(((2[0-5]{2})|(1{0,1}[0-9]{1,2}))\.){3}((2[0-5]{2})|(1{0,1}[0-9]{1,2}))$'
                saisie 'masque réseau : ' 'iface_netmask["${zone_choix[${couleur}]}"]' '^(((2[0-5]{2})|(1{0,1}[0-9]{1,2}))\.){3}((2[0-5]{2})|(1{0,1}[0-9]{1,2}))$'
                saisie 'adresse de broadcast : ' 'iface_broadcast["${zone_choix[${couleur}]}"]' '^(((2[0-5]{2})|(1{0,1}[0-9]{1,2}))\.){3}((2[0-5]{2})|(1{0,1}[0-9]{1,2}))$'
                saisie 'adresse : ' 'iface_address["${zone_choix[${couleur}]}"]' '^(((2[0-5]{2})|(1{0,1}[0-9]{1,2}))\.){3}((2[0-5]{2})|(1{0,1}[0-9]{1,2}))$' 
                if [ $couleur == "int01" ]
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
    saisie "Confirmer (NON/oui) ? " "confirm1" ".*"    
    done

###
#écriture de la Configuration des interface
#pour chaque interfaces configurées
for i in "${!iface_name[@]}"
    do
    #ecriture de la configuration de l'interface dans un fichier portant le nom de l'interface
    echo > "${rep_firewall}/config/etc/network/interfaces.d/${iface_name["${i}"]}"
    echo "auto ${iface_name["$i"]}" >> "${rep_firewall}/config/etc/network/interfaces.d/${iface_name["${i}"]}"
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
            if [ "${iface_zone["${i}"]}" == "int01" ]
                then
                #Si la zone est de type int01 et que le inet est static, on parametre la GATEWAY ainsi que le DNS
                echo "  gateway ${iface_gateway["${i}"]}" >> "${rep_firewall}/config/etc/network/interfaces.d/${iface_name["${i}"]}"
                echo "  dns-nameservers ${iface_dns["${i}"]}" >> "${rep_firewall}/config/etc/network/interfaces.d/${iface_name["${i}"]}"
                fi
        fi
    done

#redemarage du network
/etc/init.d/networking restart
#ipcalc -b `ip -4 -br addr show int01 | sed -E 's/ +/ /g' | cut -d" " -f3` | grep Network | sed -E "s/ +/ /g" | cut -d" " -f2
#route -n | grep -E "0.0.0.0 .+255.255.255.0.+[A-Z] "
#route -n | grep -v -E "0.0.0.0 .+0.0.0.0 .+" | grep "0.0.0.0"
#route -n | grep -v -E "(0.0.0.0 .+0.0.0.0 .+)|(^[aA-zZ])"
#ip -o addr | grep "inet " | sed -E "s/ +/ /g" | cut -d" " -f4
#ip -o addr | grep -E "int01 +inet " | sed -E "s/ +/ /g" | cut -d" " -f4

###
#écriture du fichier de configuration pour les zone du firewall
echo > "${rep_firewall}/config/zones_def${extention}"
for i in "${!iface_name[@]}"
    do
    echo "${iface_zone[${i}]}_iface=\"${iface_name[${i}]}\"" >> "${rep_firewall}/config/zones_def${extention}"
    echo "${iface_zone[${i}]}_address=\"${iface_address[${i}]}\"" >> "${rep_firewall}/config/zones_def${extention}"
    echo "${iface_zone[${i}]}_network=\"${iface_network[${i}]}/${iface_netmask[${i}]}\"" >> "${rep_firewall}/config/zones_def${extention}"
    done
exit

###
# écriture des règles d'attribution de nom pour les interfaces

#echo > "${rep_firewall}/config/udev/rules.d/75-firewall-persistant-net.rules${extention}"
for i in "${!iface_name[@]}"
    do 
    echo -e "SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", ATTR{address}==\"${iface_mac[${i}]}\", ATTR{dev_id}==\"0x0\", ATTR{type}==\"1\", NAME=\"${iface_name[${i}]}\"" >> "${rep_firewall}/config/udev/rules.d/75-firewall-persistant-net.rules${extention}"

    done
ln -sf "${rep_firewall}/config/udev/rules.d/75-firewall-persistant-net.rules${extention}" "/etc/udev/rules.d/75-firewall-persistant-net.rules${extention}"

