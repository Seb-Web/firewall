function iface_vue()
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
