function iface_detect()
{
    # Cette fonction doit avoir 3 valeurs d'entrées identifiant les tableu a remplir
    # exemple iface_detect "iface_mac" "iface_model" "iface_vendor"
    # le resultat sera stocké dans les tableaux indexés iface_mac[@] iface_model[@] et iface_vendor[@]
    local __tab_mac=$1
    local __tab_model=$2
    local __tab_vendor=$3
    local __tmp
    # Cette methode permet de récupérer la MAC, LE MODEL et LE VENDOR
    count=1
    for iface in `ls /sys/class/net`
    do
        if [ -d "/sys/class/net/${iface}/device" ]
        then
            eval "${__tab_mac}[${count}]"="$(cat /sys/class/net/${iface}/address)"
            while read line
            do
                if [[ $line =~ ^"E: ID_MODEL_FROM_DATABASE" ]]
                then
                    __tmp=$(echo ${line} | grep -E "ID_MODEL_FROM_DATABASE" | cut -d"=" -f2)
                    eval ${__tab_model}[${count}]='"${__tmp}"'
                fi
                if [[ $line =~ ^"E: ID_VENDOR_FROM_DATABASE" ]]
                then
                    __tmp=$(echo ${line} | grep -E "ID_VENDOR_FROM_DATABASE" | cut -d"=" -f2)
                    eval ${__tab_vendor}[${count}]='"${__tmp}"'
                fi
            done < <(udevadm info "/sys/class/net/${iface}/device/driver"/*)
            count=$(($count+1))
        fi
    done
}
