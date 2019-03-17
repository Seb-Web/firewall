function iface_vue()
{
    local __i
    echo -e "le système a détecté ${#iface_mac[@]} carte réseau"
    echo
    for (( __i=1; __i <= ${iface_count}; __i++ ))
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
            if [[ "${iface_zone[${__i}]}" =~ ^zone ]]
            then
                echo -e "#### Choix n° ${__i} ## \033[33m--${iface_zone[${__i}]}--\033[0m ## ${iface_mac[${__i}]} ## ${iface_network[${__i}]} ## ${iface_address[${__i}]}"
            elif [[ "${iface_zone[${__i}]}" =~ ^int ]]
            then
                echo -e "#### Choix n° ${__i} ## \033[31m--${iface_zone[${__i}]}--\033[0m ## ${iface_mac[${__i}]} ## ${iface_network[${__i}]} ## ${iface_address[${__i}]}"
            fi
        echo
        fi
    done
}
