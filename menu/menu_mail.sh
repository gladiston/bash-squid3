#!/bin/bash 

function mail_editar() {
  arquivo="$1"
  if editar "$arquivo" ; then 
      echo "O arquivo :"
      echo -e "\t$arquivo"
      echo "foi alterado, recomendo reiniciar o servidor de email."
      echo "Reiniciar o servidor de email ?"
      read CONFIRMA
      if [ "$CONFIRMA" = "SIM" ] || [ "$CONFIRMA" = "sim" ] || [ "$CONFIRMA" = "S" ] || [ "$CONFIRMA" = "s" ] ; then
         service postfix restart
      fi
  fi

}

function restart() {
  echo "Reiniciar o servidor de email ?"
  read CONFIRMA
  if [ "$CONFIRMA" = "SIM" ] || [ "$CONFIRMA" = "sim" ] || [ "$CONFIRMA" = "S" ] || [ "$CONFIRMA" = "s" ] ; then
     service postfix restart
  fi
}

function do_menu()
{
  clear
  while :
  do
    clear
    echo "-------------------------------------------------------------"
    echo "                      E M A I L S"
    echo "-------------------------------------------------------------"
    echo "1 - Observar a fila de mensagens"
    echo "2 - Reenviar todas as mensagens na fila"
    echo "3 - Testar a capacidade de envio de email deste host"
    echo "19- Observar o log de erros"
    echo "20- Observar o log de mensagens"
    echo "94- Apagar todas as mensagens que foram adiadas (deferred)"
    echo "95- Apagar todas as mensagens na fila"
    echo "96- Editar postfix-config main.cf"
    echo "97- Editar postfix-config master.cf"
    echo "98- Reiniciar o postfix"
    echo "99- Sair"
    echo -n "Escolha uma opcao [1-99] :"
    read opcao
    case $opcao in
    1)mailq |less;;
    2)postfix flush;;
    3)"$SCRIPTS/testar_email.sh"
       press_enter_to_continue;;
    19)pesquisar_arquivo "/var/log/mail.err";;
    20)pesquisar_arquivo "/var/log/mail.log";;
    94)postsuper -d ALL deferred;;
    95)postsuper -d ALL;;
    96)mail_editar "/etc/postfix/main.cf";;
    97)mail_editar "/etc/postfix/master.cf";;
    98)restart;;  
    99)echo "Fim";
      exit 0;;
    *) echo "Opcao invalida !!!"; read;;
    esac
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
