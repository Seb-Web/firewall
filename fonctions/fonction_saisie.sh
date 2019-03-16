function saisie()
{
    # la fonction à besoin de 3 parametres d'entré "Texte a affiché" "Variable de sortie" "regex de test"
    # exemple: saisie "Confimez votre choix: " "var_conf" "^oui$"

    local __texte=$1
    local __variable=$2
    local __regex=$3
    local __verif="0"

    while [ "${__verif}" == "0" ]
    do
        echo -n -e "${__texte}"
        read __saisie
        if [[ "${__saisie}" =~ $__regex ]]
        then
            __verif="1"
        else
            echo "Erreur de saisie !""!"
        fi
    done
    eval $__variable="'${__saisie}'"
}
