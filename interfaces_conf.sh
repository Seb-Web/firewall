#!/bin/bash

# Récupération du répertoire d'éxecution du script
rep_firewall=$(dirname $(readlink -f $0))

# Récupération des informations sur les interfaces réseau detecté par le système
declare -A interface_mac
declare -A interface_info
for iface in `ls /sys/class/net`
    do
        if [ -d "/sys/class/net/${iface}/device" ]
        then
            interface_mac[${iface}]=`cat /sys/class/net/${iface}/address`
            interface_info[${iface}]=`udevadm info "/sys/class/net/${iface}/device/driver"/* | grep -E "ID_MODEL_FROM_DATABASE|ID_VENDOR_FROM_DATABASE" | cut -d "=" -f2`
        fi
    done

# restitution des informations en vue d'un traitement utilisateur
echo -e "le systme a détecté ${#interface_mac[@]} carte réseau"

for i in "${!interface_mac[@]}"
    do
        echo -e "${interface_mac[${i}]}"
        echo -e "${interface_info[${i}]}"
        echo
    done
#echo -e "SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", ATTR{address}==\"aa:bb:cc:dd:ee:ff\", ATTR{dev_id}==\"0x0\", ATTR{type}==\"1\", KERNEL==\"eth*\", NAME=\"red\"" > config/udev
#echo -e "SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", ATTR{address}==\"aa:bb:cc:dd:ee:ff\", ATTR{dev_id}==\"0x0\", ATTR{type}==\"1\", KERNEL==\"eth*\", NAME=\"green\"" >> config/udev
#echo -e "SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", ATTR{address}==\"aa:bb:cc:dd:ee:ff\", ATTR{dev_id}==\"0x0\", ATTR{type}==\"1\", KERNEL==\"eth*\", NAME=\"orange\"" >> config/udev
