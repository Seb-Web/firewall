function iface_detect()
{
    # Cette fonction doit avoir 3 parametres d'entrées identifiant les tableu a remplir
    # exemple iface_detect "iface_mac" "iface_model" "iface_vendor"
    # le resultat sera stocké dans les tableaux indexés iface_mac[@] iface_model[@] et iface_vendor[@]
    local __tab_mac=$1
    local __tab_model=$2
    local __tab_vendor=$3
    local __tmp
    local __count=0
    # Cette methode permet de récupérer la MAC, LE MODEL et LE VENDOR

    for iface in `ls /sys/class/net`
    do
        if [ -d "/sys/class/net/${iface}/device" ]
        then
            __count=$((${__count}+1))
            eval "${__tab_mac}[${__count}]"="$(cat /sys/class/net/${iface}/address)"
            while read line
            do
                if [[ $line =~ ^"E: ID_MODEL_FROM_DATABASE" ]]
                then
                    __tmp=$(echo ${line} | grep -E "ID_MODEL_FROM_DATABASE" | cut -d"=" -f2)
                    eval ${__tab_model}[${__count}]='"${__tmp}"'
                fi
                if [[ $line =~ ^"E: ID_VENDOR_FROM_DATABASE" ]]
                then
                    __tmp=$(echo ${line} | grep -E "ID_VENDOR_FROM_DATABASE" | cut -d"=" -f2)
                    eval ${__tab_vendor}[${__count}]='"${__tmp}"'
                fi
            done < <(udevadm info "/sys/class/net/${iface}/device/driver"/*)
        fi
    done
    eval "iface_count"="'${__count}'"
}
