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
iface_vue
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
saisie "Quel est votre choix pour l'interface \033[31minternet\033[0m ? " 'iface_idx' "([1-9]|([1-9][0-9]))$"
iface_zone[${iface_idx}]="int1"
zone_iface["int1"]="${iface_idx}"
iface_name[${iface_idx}]="int1"

saisie 'dhcp ou static : ' "iface_inet[${iface_idx}]" '^(dhcp|static)$'
if [ "${iface_inet[${iface_idx}]}" == "static" ]
then
    saisie 'réseau : ' "iface_network["${zone_choix["int1"]}"]" "^${regex_match_address}/${regex_match_network}$"
    saisie 'adresse : ' "iface_address["${zone_choix["int1"]}"]" "^${regex_match_address}$" 
    saisie 'passerelle : ' "iface_gateway["${zone_choix["int1"]}"]" "^${regex_match_address}$"
    saisie 'DNS : ' "iface_dns["${zone_choix["int1"]}"]" "${regex_match_address}$"
fi


for (( zone_idx=1 ; zone_idx <= ${zone_nb} ; zone_idx++ ))
do
    # Aperçu du materiel reseau detecter
    clear
    iface_vue
    # on boucle sur la demande de choix, tant que l'on ne choisi pas une carte non configurer
    while [ true ]
    do
#        saisie "Quel est votre choix pour \033[33mla zone ${zone_idx}\033[0m ? " 'zone_choix["zone${iface_idx}"]' '^(!(0a-zA-Z)|[1-9]|([1][0]))$'
        saisie "Quel est votre choix pour \033[33mla zone ${zone_idx}\033[0m ? " 'iface_idx' '^(!(0a-zA-Z)|[1-9]|([1][0]))$'
        if [ "${iface_zone["${iface_idx}"]}" == "" ]
        then
            iface_zone["${iface_idx}"]="zone${zone_idx}"
            zone_iface["zone${zone_idx}"]="${iface_idx}"
            iface_name["${iface_idx}"]="zone${zone_idx}"
            iface_inet["${iface_idx}"]="static"
            saisie 'réseau : ' "iface_network["${iface_idx}"]" "^${regex_match_address}/${regex_match_network}$"
            saisie 'adresse : ' "iface_address["${iface_idx}"]" "^${regex_match_address}$"
            break
        else
            echo "Ce choix à déjà été parametré."
        fi
    done
done
clear
iface_vue
pause



function interfaces_config()
{
###
#écriture de la Configuration des interface
#pour chaque interfaces configurées
for iface_idx in "${!iface_name[@]}"
do
    #ecriture de la configuration de l'interface dans un fichier portant le nom de l'interface
    echo > "${rep_config}/etc/network/interfaces.d/${iface_name["${iface_idx}"]}"
    echo "auto ${iface_name["${iface_idx}"]}" >> "${rep_config}/etc/network/interfaces.d/${iface_name["${iface_idx}"]}"
    if [ "${iface_inet["${iface_idx}"]}" == "dhcp" ]
    then
        #Si l'interface a été configuré en dhcp 
        echo "iface ${iface_name["${iface_idx}"]} inet dhcp" >> "${rep_config}/etc/network/interfaces.d/${iface_name["${iface_idx}"]}"
    elif [ "${iface_inet["${iface_idx}"]}" == "static" ]
    then
        #Si l'interface a été configuré en static
        echo "iface ${iface_name["${iface_idx}"]} inet static" >> "${rep_config}/etc/network/interfaces.d/${iface_name["${iface_idx}"]}"
        echo "  network ${iface_network["${iface_idx}"]}" >> "${rep_config}/etc/network/interfaces.d/${iface_name["${iface_idx}"]}"
        echo "  address ${iface_address["${iface_idx}"]}" >> "${rep_config}/etc/network/interfaces.d/${iface_name["${iface_idx}"]}"
        if [ "${iface_zone["${iface_idx}"]}" == "int1" ]
        then
           #Si la zone est de type int1 et que le inet est static, on parametre la GATEWAY ainsi que le DNS
           echo "  gateway ${iface_gateway["${iface_idx}"]}" >> "${rep_config}/etc/network/interfaces.d/${iface_name["${iface_idx}"]}"
           echo "  dns-nameservers ${iface_dns["${iface_idx}"]}" >> "${rep_config}/etc/network/interfaces.d/${iface_name["${iface_idx}"]}"
        fi
    fi
done

#redemarage du network
/etc/init.d/networking restart
}
function zones_def_config()
{
###
#écriture du fichier de configuration pour les zone du firewall
####deprecated
#echo > "${rep_config}/zones_def${extention}"
#for iface_idx in "${!iface_name[@]}"
#    do
#    echo "${iface_zone[${iface_idx}]}_iface=\"${iface_name[${iface_idx}]}\"" >> "${rep_config}/zones_def${extention}"
#    echo "${iface_zone[${iface_idx}]}_address=\"${iface_address[${iface_idx}]}\"" >> "${rep_config}/zones_def${extention}"
#    echo "${iface_zone[${iface_idx}]}_network=\"${iface_network[${iface_idx}]}/${iface_netmask[${iface_idx}]}\"" >> "${rep_config}/zones_def${extention}"
#    done
####/deprecated
echo > "${rep_config}/zones_def${extention}"
echo "declare -A iface_name" >> "${rep_config}/zones_def${extention}"
echo "declare -A iface_mac" >> "${rep_config}/zones_def${extention}"
echo "declare -A iface_zone" >> "${rep_config}/zones_def${extention}"
echo "declare -A iface_inet" >> "${rep_config}/zones_def${extention}"
echo "declare -A iface_network" >> "${rep_config}/zones_def${extention}"
echo "declare -A iface_address" >> "${rep_config}/zones_def${extention}"
echo "declare -A zone_iface" >> "${rep_config}/zones_def${extention}"
for iface_idx in "${!iface_name[@]}"
do
    echo "iface_name[${iface_idx}]=\"${iface_name[${iface_idx}]}\"" >> "${rep_config}/zones_def${extention}"
    echo "iface_mac[${iface_idx}]=\"${iface_mac[${iface_idx}]}\"" >> "${rep_config}/zones_def${extention}"
    echo "iface_zone[${iface_idx}]=\"${iface_zone[${iface_idx}]}\"" >> "${rep_config}/zones_def${extention}"
    echo "iface_inet[${iface_idx}]=\"${iface_inet[${iface_idx}]}\"" >> "${rep_config}/zones_def${extention}"
    echo "iface_network[${iface_idx}]=\"${iface_network[${iface_idx}]}\"" >> "${rep_config}/zones_def${extention}"
    echo "iface_address[${iface_idx}]=\"${iface_address[${iface_idx}]}\"" >> "${rep_config}/zones_def${extention}"
done
for iface_idx in "${!iface_zone[@]}" 
do
    echo "zone_iface[\"${iface_zone[${iface_idx}]}\"]=\"${iface_idx}\"" >> "${rep_config}/zones_def${extention}"
done

}
function udev_config()
{
###
# écriture des règles d'attribution de nom pour les interfaces

#echo > "${rep_config}/udev/rules.d/75-firewall-persistant-net.rules${extention}"
for i in "${!iface_name[@]}"
    do 
    echo -e "SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", ATTR{address}==\"${iface_mac[${iface_idx}]}\", ATTR{dev_id}==\"0x0\", ATTR{type}==\"1\", NAME=\"${iface_name[${iface_idx}]}\"" >> "${rep_config}/udev/rules.d/75-firewall-persistant-net.rules${extention}"

    done
ln -sf "${rep_config}/udev/rules.d/75-firewall-persistant-net.rules${extention}" "/etc/udev/rules.d/75-firewall-persistant-net.rules${extention}"
}

zones_def_config
