#!/bin/bash 

function do_menu()
{
  clear
  while :
  do
    clear
    echo "-------------------------------------------------------------"
    echo "   G E R E N C I A M E N T O   D E   U S U A R I O S"
    echo "-------------------------------------------------------------"
    echo "1 - Editar lista de usuarios administradores"
    echo "2 - Editar lista de usuarios com acesso fixo"
    echo "3 - Editar lista de usuarios com acesso avulso"
    echo "4 - Editar lista de usuarios com acesso bloqueado"
    echo "5 - Editar lista de usuarios com acesso governamental"
    echo "6 - Editar lista de usuarios sem restrição de sites"
    echo "7 - Editar destinarios de auditoria de internet"
    echo "8 - Testar acesso de um usuario a um site"
    echo "99- Sair"
    echo -n "Escolha uma opcao [1-99] :"
    read opcao
    case $opcao in
    1)proxy_users_conf "$SQUIDACL/usuarios_administradores.txt";;
    2)proxy_users_conf "$SQUIDACL/usuarios_acesso_fixo.txt";;
    3)proxy_users_conf "$SQUIDACL/usuarios_acesso_avulso.txt" "S";;
    4)proxy_conf "$SQUIDACL/usuarios_bloqueados.txt";;
    5)proxy_conf "$SQUIDACL/usuarios_governo.txt";;
    6)proxy_conf "$SQUIDACL/usuarios_sembloqueio.txt";;
    7)editar "$SQUIDACL/relatorio_emails.txt";;
    8)echo "Em desenvolvimento...";
      pause;;
    99)echo "Fim";
      exit 0;;
    *) echo "Opcao invalida !!!"; read;;
    esac
    service squid3 reload
  done
}

#
# Inicio do Programa
#

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
