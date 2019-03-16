#!/bin/bash

clear
# Récupération du répertoire d'éxecution du script en cour
rep_exec=$(dirname $(readlink -f $0))
rep_fonctions="${rep_exec}/fonctions"
rep_config="${rep_exec}/config"
# Chargement des fonctions
source "${rep_fonctions}/fonction_pause.sh"
source "${rep_fonctions}/fonction_saisie.sh"
source "${rep_fonctions}/fonction_iface_detect.sh"
source "${rep_fonctions}/fonction_iface_vue.sh"

# Chargement de l'entete
source "${rep_exec}/entetes/entete_zones_config"

# Chargement des variable
source "${rep_config}/vars.conf"

pause

# Récupération des informations sur les interfaces réseau detecté par le système
iface_detect 'iface_mac' 'iface_model' 'iface_vendor'

# On fixe le nombre de zone max au nombre d'interface trouvé moins celle de l'internet
zone_max=$((iface_count-1))
#initialisation de la variable de saisie avec le nombre d'interface ce qui correspont à < zone max +1 >
zone_nb=${iface_count}

while (( "${zone_nb}" > "${zone_max}" ))
do
    saisie "Combien de zones voulez-vous configurer ? " "zone_nb" "^(!(0a-zA-Z)|[1-9]|([1-9][0-9]))$"
    if (( ${zone_nb} > ${zone_max} ))
    then
        echo -e '\033[31m!!! '"Il n'y a pas assez d'interface"' !!!\033[0m'
    fi
done
# Aperçu du materiel reseau detecter
clear
iface_vue
saisie "Quel est votre choix pour l'interface \033[31minternet\033[0m ? " 'zone_choix["int01"]' "([1-9]|([1-9][0-9]))$"
iface_zone[${zone_choix["int01"]}]="int01"
saisie 'dhcp ou static : ' 'iface_inet["${zone_choix["int01"]}"]' '^(dhcp|static)$'
if [ "${iface_inet["${zone_choix["int01"]}"]}" == "static" ]
then
    saisie 'réseau : ' "iface_network["${zone_choix["int01"]}"]" "^${regex_match_address}/${regex_match_network}$"
    saisie 'adresse : ' "iface_address["${zone_choix["int01"]}"]" "^${regex_match_address}$" 
    saisie 'passerelle : ' "iface_gateway["${zone_choix["int01"]}"]" "^${regex_match_address}$"
    saisie 'DNS : ' "iface_dns["${zone_choix["int01"]}"]" "${regex_match_address}$"
fi

for (( i=1 ; i <= ${zone_nb} ; i++ ))
do
    # Aperçu du materiel reseau detecter
    clear
echo "###${i}"
    iface_vue
    # on boucle sur la demande de choix, tant que l'on ne choisi pas une carte non configurer
    while [ true ]
    do
        saisie "Quel est votre choix pour \033[33mla zone ${i}\033[0m ? " 'zone_choix["zone${i}"]' '^(!(0a-zA-Z)|[1-9]|([1][0]))$'
        if [ "${iface_zone["${zone_choix["zone${i}"]}"]}" == "" ] 
        then
            iface_zone["${zone_choix["zone${i}"]}"]="zone${i}"
            iface_name["${zone_choix["zone${i}"]}"]="zone${i}"
            iface_inet["${zone_choix["zone${i}"]}"]="static"
            saisie 'réseau : ' "iface_network["${zone_choix["zone${i}"]}"]" "^${regex_match_address}/${regex_match_network}$"
            saisie 'adresse : ' "iface_address["${zone_choix["zone${i}"]}"]" "^${regex_match_address}$" 
            break
        else
            echo "Ce choix à déjà été parametré."
        fi
    done
done
clear
iface_vue
pause
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

