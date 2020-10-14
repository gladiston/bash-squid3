#!/bin/bash 
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

function proxy_relatorio() {
  clear
  echo "Todos os relatórios por usuário estarão guardados em :"
  echo "sftp://administrador@192.168.1.254/home/administrador/logs/pub"
  echo "Enquanto o primeiro relatório de uma determinada da estarão guardados em :"
  echo "sftp://administrador@192.168.1.254/home/administrador/logs/AAAA-MM"
  echo "Obs: O acesso é restrito ao administrador."
  echo "--"
  echo -ne "Digite o login :"
  read LOGIN
  if [ "$LOGIN" = "" ] ; then
    echo "Não foi identificado o login."
    press_enter_to_continue
    return 1
  fi
  echo -ne "Digite a data (AAAA-MM-DD) :"
  read DATA_ATUAL
  if [ "$DATA_ATUAL" = "" ] ; then
    echo "Voce nao digitou uma data, assim todas as datas contidas no proxy-cache serao processados."
    press_enter_to_continue
  fi

  "$SCRIPTS/squid_relatorio.sh" "$DATA_ATUAL" "$LOGIN"
  press_enter_to_continue
}

function do_reiniciar_squid_com_autenticacao() {
  squid_file="/etc/squid3/squid.conf"
  squid_line_to_remark="include /etc/squid3/squid.conf.rules.free"
  squid_line_to_unremark="include /etc/squid3/squid.conf.rules"
  exist_to_remark=`grep -i "^$squid_line_to_remark\$" "$squid_file"|wc -l`
  exist_to_unremark=`grep -i "^#$squid_line_to_unremark\$" "$squid_file"|wc -l`
  if [ "$exist_to_remark" -eq 0 ] && [ "$exist_to_unremark" -eq 0 ] ; then
     echo "O arquivo $squid_file nao possui as linhas de configuracao :"
     echo -e "\t$squid_line_to_remark"
     echo -e "\t$squid_line_to_unremark"
     echo "ou essa opção ja estava em execução."
     press_enter_to_continue
     return 1     
  fi

  sed -i "s|^#${squid_line_to_unremark}.*|${squid_line_to_unremark}|" $squid_file
  sed -i "s|^${squid_line_to_remark}.*|#${squid_line_to_remark}|" $squid_file

  sudo service squid3 restart
  erro=$?
  if [ $erro -gt 0 ] ; then
    echo "Ocorreu um erro($erro) ao reiniciar o servidor de proxy."
    #press_enter_to_continue
  fi

  press_enter_to_continue
}

function do_reiniciar_squid_sem_autenticacao() {
  squid_file="/etc/squid3/squid.conf"
  squid_line_to_remark="include /etc/squid3/squid.conf.rules"
  squid_line_to_unremark="include /etc/squid3/squid.conf.rules.free"
  exist_to_remark=`grep -i "^$squid_line_to_remark\$" "$squid_file"|wc -l`
  exist_to_unremark=`grep -i "^#$squid_line_to_unremark\$" "$squid_file"|wc -l`
  if [ "$exist_to_remark" -eq 0 ] && [ "$exist_to_unremark" -eq 0 ] ; then
     echo "O arquivo $squid_file nao possui as linhas de configuracao :"
     echo -e "\t$squid_line_to_remark"
     echo -e "\t$squid_line_to_unremark"
     echo "ou essa opção ja estava em execução."
     press_enter_to_continue
     return 1     
  fi

  sed -i "s|^${squid_line_to_remark}.*|#${squid_line_to_remark}|" $squid_file
  sed -i "s|^#${squid_line_to_unremark}.*|${squid_line_to_unremark}|" $squid_file


  sudo service squid3 restart
  erro=$?
  if [ $erro -gt 0 ] ; then
    echo "Ocorreu um erro($erro) ao reiniciar o servidor de proxy."
    #press_enter_to_continue
  fi

  press_enter_to_continue
}

scramble() {
    # $1: string to scramble
    # return in variable scramble_ret
    local a=$1 i
    scramble=
    while((${#a})); do
        ((i=RANDOM%${#a}))
        scramble+=${a:i:1}
        a=${a::i}${a:i+1}
    done
}

function restart_squid()
{
  service squid3 stop

  if ! [ -f /var/log/squid3/access.log ] ; then
    touch /var/log/squid3/access.log
    chown proxy.proxy /var/log/squid3/access.log
  fi

  squid3 -z
  erro=$?
  if [ $erro -eq 0 ] ; then
     service squid3 start
     erro=$?
  fi

  if [ $erro -gt 0 ] ; then
    echo "Ocorreu um erro($erro) ao reiniciar o servidor de proxy."
    press_enter_to_continue
  fi
}

function testar_autenticacao()
{
  PROXY_USERNAME=""
  PROXY_PASS="" 
  echo " "
  echo "Teste de autenticação automatica(NTLM) e manual(LDAP) no proxy"
  echo "--------------------------------------------------------------"
  echo -n "Digite o login de autenticação: "
  read PROXY_USERNAME
  if [ -z $PROXY_USERNAME ] || [ "$PROXY_USERNAME" == "" ] ; then
    PROXY_USERNAME="proxy_internet"    
    PROXY_PASS="vidy55anos"
  fi
  if [ "$PROXY_PASS" == "" ] ; then
    echo -n "Digite a senha para [$PROXY_USERNAME]: "
    read -s PROXY_PASS
  fi

  HIDDEN_PASS="${PROXY_PASS:0:1}***${PROXY_PASS:4:1}***${PROXY_PASS: -1}"
#  scramble "$PROXY_PASS"
#  HIDDEN_PASS=$scramble

  SECRET_FILE=$(mktemp /tmp/test_auth-XXXXXXX)
  echo "$PROXY_PASS">$SECRET_FILE

  TESTE_NTLM=$(echo "$PROXY_PASS"|/usr/bin/ntlm_auth --username=$PROXY_USERNAME --domain=vidy.local|grep "NT_STATUS")

  TESTE_LDAP=$(echo "$PROXY_USERNAME $PROXY_PASS"|/usr/lib/squid3/basic_ldap_auth -R -b "dc=VIDY,dc=local" -D $PROXY_USERNAME@VIDY.local -W $SECRET_FILE -f sAMAccountName=%s -h VIDY.local)

  echo " "
  echo "Resultado de comunicação com os servidores de autenticação"
  echo "----------------------------------------------------------"
  echo -e "Logon de autenticacao:\t\t $PROXY_USERNAME"
  echo -e "      Senha utilizada:\t\t $HIDDEN_PASS"
  echo -e "     Comunicacao NTLM:\t\t $TESTE_NTLM"
  echo -e "     Comunicacao LDAP:\t\t $TESTE_LDAP"
  echo " "
#  echo "Citação da palavra ERR significa falha."
#  echo "Citação da palavra OK significa que passou no teste."

  press_enter_to_continue
  [ -f "$SECRET_FILE" ] && rm -f "$SECRET_FILE"

}


function do_menu()
{
  clear
  while :
  do
    clear
    echo "-------------------------------------------------------------"
    echo "               M E N U  P A R A  I N T E R N E T             "
    echo "-------------------------------------------------------------"
    echo "1 - Submenu para gerenciamento de usuarios"
    echo "2 - Submenu para gerenciamento de sites"
    echo "3 - Editar configuracao de Controle de banda"
    echo "4 - Editar configuracao de DNSs usandos pelo proxy-cache"
    echo "5 - Logs e Relatorios"
    echo "6 - Recarregar ajuste de configuração do proxy-cache"
    echo "7 - Editar lista dontlog"
    echo "15- Liberar o acesso a internet somente pelo GW"
    echo "16- Liberar o acesso a internet pelo proxy+GW"
    echo "17- Testar o acesso a internet a partir de uma estação de trabalho"
    echo "18- Testar a autenticação automatica(NTLM) e manual(LDAP) no proxy"
    echo "94- Testar a velocidade de internet"
    echo "95- Testar os DNSs usados pelo proxy-cache"
    echo "96- Reiniciar o servidor de proxy-cache"
    echo "97- Reiniciar o proxy-cache squid com autenticação obrigatoria*"
    echo "98- Reiniciar o proxy-cache squid sem necessitar autenticacao*"
    echo "99- Sair"
    echo -n "Escolha uma opcao [1-99] :"
    read opcao
    case $opcao in
    1)do_submenu "menu_squid_usuarios.sh";;
    2)do_submenu "menu_squid_sites.sh";;
    3)proxy_conf "/etc/squid3/squid.conf.controle-de-banda";;
    4)proxy_conf "/etc/squid3/squid.conf.dns";;
    5)do_submenu "menu_squid_relatorios.sh";;
    6)service squid3 reload;;
    7)proxy_conf "/etc/squid3/acl/dontlog.txt";;
    15)$SCRIPTS/wpad-create.sh /var/www/html/wpad.dat no-proxy;
      press_enter_to_continue;;
    16)$SCRIPTS/wpad-create.sh /var/www/html/wpad.dat;
      press_enter_to_continue;;
    17)$SCRIPTS/testar_wpad.sh;
       press_enter_to_continue;;
    18)testar_autenticacao;;
    94)$SCRIPTS/speedtest-cli;
       press_enter_to_continue;;    
    95)clear;
       "$SCRIPTS/testar_dns_squid.sh";
	   press_enter_to_continue;;
    96)restart_squid;;      
    97)do_reiniciar_squid_com_autenticacao;;
    98)do_reiniciar_squid_sem_autenticacao;;
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
