#!/bin/bash

# Récupération du répertoire d'éxecution du script
rep_firewall=$(dirname $(readlink -f $0))

for iface in `ls /sys/class/net`
    do
        if [ -d "/sys/class/net/${iface}/device" ]
        then
            cat /sys/class/net/${iface}/address
            udevadm info "/sys/class/net/${iface}/device/driver"/* | grep -E "ID_MODEL_FROM_DATABASE|ID_VENDOR_FROM_DATABASE" | cut -d "=" -f2
            echo
        fi
    done
#echo -e "SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", ATTR{address}==\"aa:bb:cc:dd:ee:ff\", ATTR{dev_id}==\"0x0\", ATTR{type}==\"1\", KERNEL==\"eth*\", NAME=\"red\"" > config/udev
#echo -e "SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", ATTR{address}==\"aa:bb:cc:dd:ee:ff\", ATTR{dev_id}==\"0x0\", ATTR{type}==\"1\", KERNEL==\"eth*\", NAME=\"green\"" >> config/udev
#echo -e "SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", ATTR{address}==\"aa:bb:cc:dd:ee:ff\", ATTR{dev_id}==\"0x0\", ATTR{type}==\"1\", KERNEL==\"eth*\", NAME=\"orange\"" >> config/udev
