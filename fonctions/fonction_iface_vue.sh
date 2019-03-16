function iface_vue()
{
    local __i
    echo -e "le système a détecté ${#iface_mac[@]} carte réseau"
    echo
    for (( __i=1; __i<=${iface_count}; __i++ ))
        do
        if [ "${iface_zone["${__i}"]}" == "" ]
            then
            echo -e "#### Choix n° ${__i}"
            echo -e "# ${iface_mac[${__i}]}"
            echo -e "# ${iface_model[${__i}]}"
            echo -e "# ${iface_vendor[${__i}]}"
            echo -e "####"
            echo
        else
            echo -e "#### Choix n° ${__i} ## ${zone_color[${iface_zone[${__i}]}]}--${iface_zone[${__i}]}--\033[0m ## ${iface_mac[${__i}]} ## ${iface_network[${__i}]}/${iface_netmask[${__i}]} ## ${iface_address[${__i}]}"
            echo
        fi
    done
}
