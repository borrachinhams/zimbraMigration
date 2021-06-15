#!/bin/bash
#
#==========================================================
# DESCRIPTION
# Script for migrating boxes between accounts.
# Developed for use on Zimbra Email Server
#================================================== =========
# USE
# Run the script and follow the instructions given by it.
#==========================================================
# Borrachinha, 13/05/2019
#


#==============================================
#Colors
Nc='\033[0m'              # No Color
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Cyan='\033[0;36m'         # Cyan
#==============================================

function PrintUsage() {
   echo -e "Help Usage:\n"
   echo -e "${Yellow}-i${Nc} Interative option"
   echo -e "${Yellow}-l${Nc} List option. \n\tYou need inform list with emails ${Green}from${Nc} --> ${Green}to${Nc}"
   exit 1
}

function interativo(){
        #From --> To
        echo -e "Enter e-mails\n \
                 Ex: xpto@mydomain.com"
        echo -e "From: \c"
        read de

        echo -e "To: \c"
        read para

        echo -e "\nMigração:\nDe: ${Green}${de}${Nc}\nPara: ${Yellow}${para}${Nc}"
        echo -e "${Red}Enter para continuar${Nc}"; read xpto
        migra ${de} ${para}
}


function migra(){
        de=${1}
        para=${2}

        nome=$(echo ${de} | awk -F'@' {'print $1'})

        echo "Migration ${de} --> ${para}"
        #Iniciando backup
        echo "Start Backup"
        /opt/zimbra/bin/zmmailbox -z -m ${de} getRestURL "//?fmt=tgz" > /tmp/${nome}.tgz

        #Iniciando restauração
        #/opt/zimbra/bin/zmmailbox -t 0 -z -m ${para} postRestURL "//?fmt=tgz&resolve=reset" /tmp/${nome}.tgz
        echo "Start Import"
        /opt/zimbra/bin/zmmailbox -t 0 -z -m ${para} postRestURL "//?fmt=tgz&resolve=skip" /tmp/${nome}.tgz

        #Removendo caixa
        rm -f /tmp/${nome}.tgz

        # Iniciando Redirecionamento
        /opt/zimbra/bin/zmprov ma $de zimbraFeatureMailForwardingEnabled TRUE
        /opt/zimbra/bin/zmprov ma $de zimbraPrefMailForwardingAddress ${para}
        #/opt/zimbra/bin/zmprov ma $de zimbraAccountStatus closed
        /opt/zimbra/bin/zmprov ma $de zimbraAccountStatus lockout
}


while getopts "l:i" OPTION; do
   case ${OPTION} in
     h) PrintUsage
        ;;
     l) DO_LISTA=1
        ARG_LISTA=$OPTARG
        ;;
     i) DO_INTERATIVO=1
        ARG_INTERATIVO=$OPTARG
        ;;
   esac
done

shift $((OPTIND-1))

#Variaveis vazias
if [ -z "$DO_LISTA" ] && [ -z "$DO_INTERATIVO" ] ; then
   PrintUsage
fi

if [[ ${DO_INTERATIVO} == 1 ]]; then
    interativo    
else
    cat ${ARG_LISTA} | while read de para; do  
    migra ${de} ${para}
done
fi
