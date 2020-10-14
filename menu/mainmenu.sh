#!/bin/bash
############################################
# Menu Principal deste Servidor            #
############################################

function do_menu() {
  clear
  while :
  do
    clear
    echo "-------------------------------------------------------------"
#    echo " M E N U    P R I N C I P A L : *** I N T R A N E T ***      "
    /usr/bin/landscape-sysinfo --sysinfo-plugins=Load,Disk,Memory,Temperature,Processes,LoggedInUsers
    echo "-------------------------------------------------------------"
#    echo "1 - Submenu para gerenciar navegacao/firewalll"
    echo "2 - Submenu para gerenciar proxy-cache (squid)"
    echo "3 - Submenu para gerenciar backup"
    echo "4 - Submenu para gerenciar usuarios externos"
    echo "5 - Submenu para gerenciar emails"
    echo "6 - Submenu para servicos e manutencoes gerais"
    echo "7 - Submenu para publicações SGQ/ISO91001"
    echo "98- Sair para shell"
    echo "99- Logout do Sistema"
    echo -n "Escolha uma opcao [1-99] :"
    read opcao
    case $opcao in
#    1) do_submenu "menu_firewall.sh";;
    2) do_submenu "menu_squid.sh";;
    3) do_submenu "menu_backup.sh";;
    4) do_submenu "menu_extranet.sh";;
    5) do_submenu "menu_mail.sh";;
    6) do_submenu "menu_services.sh";;
    7) do_submenu "menu_sgq.sh";;
    99)exit;;
    *) echo "Opcao invalida !!!"; read;;
    esac
  done
}

# Inicio do Programa

# Variaveis importantes para este script
. /home/administrador/menu/mainmenu.var
if [ $? -ne 0 ] ; then
  echo "Nao foi possivel importar o arquivo [/home/administrador/menu/mainmenu.var] !"
  exit 2;
fi

# Funcoes importantes para este script
. /home/administrador/scripts/functions.sh
if [ $? -ne 0 ] ; then
  echo "Nao foi possivel importar o arquivo [/home/administrador/scripts/functions.sh] !"
  exit 2;
fi

do_menu

# Fim do Programa
