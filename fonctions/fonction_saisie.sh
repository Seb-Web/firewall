function saisie()
{
    local __texte=$1
    local __variable=$2
    local __regex=$3

    verif="0"
    while [ "$verif" == "0" ]
        do
        echo -n -e "${__texte}"
        read __saisie
        if [[ "${__saisie}" =~ $__regex ]]
            then
            verif="1"
            else
            echo "Erreur de saisie !""!"
            fi
        done
        eval $__variable="'${__saisie}'"
}
