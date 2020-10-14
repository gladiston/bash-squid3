#!/bin/bash
# Funcao : Envia para algum email o relatorio de acesso de um colaborador.
#          Envia apenas relatórios gerados previamente, se existirem.
# Variaveis importantes para este script
. /home/administrador/menu/mainmenu.var

# Funcoes importantes para este script
. /home/administrador/scripts/functions.sh

# trap ctrl-c and call ctrl_c() trap ctrl_c INT
trap ctrl_c INT
function ctrl_c() {
  echo "*** interrompido pelo usuario ***" ;
  do_menu
  return;
}
function proxy_relatorio() {
  clear
  echo "Este relatório informa os acessos de um usuário num determinado período e os envia por email ao solicitante."
  echo "Segundo as normas internas, o relatório de acesso de um usuário só poderá ser enviado ao seu superior hierarquicamente."
  echo "O relatório será enviado por email."
  echo "--"
  echo -ne "Digite o login do usuário a ser pesquisado:"
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
  ANO=`echo $DATA_ATUAL|cut -d'-' -f1`
  MES=`echo $DATA_ATUAL|cut -d'-' -f2`
  DIA=`echo $DATA_ATUAL|cut -d'-' -f3`
  echo "Digite o email para onde será enviado o relatório"
  echo "(não é preciso digitar @vidy.com.br)"
  read MAILTO

  if [ -z $MAILTO ] ; then
    exit 0;
  fi
  
  if ! [[ "$MAILTO" == *@* ]] ; then
      MAILTO="$MAILTO@vidy.com.br"    
  fi
  
  LOGFILE="$LOGS/$ANO/$ANO-$MES/$DATA_ATUAL/$DATA_ATUAL-$LOGIN.csv"
  if ! [ -f "$LOGFILE" ] ; then 
    "$SCRIPTS/squid_relatorio.sh" "$DATA_ATUAL" "$LOGIN"
  fi

  if ! [ -f "$LOGFILE" ] ; then 
    echo "Nao encontrei os logs de acesso em:"
    echo "$LOGFILE"
    echo "As razões para isso podem ser:"
    echo "- Login ou o período estejam errados"
    echo "- O Login solicitado não teve acesso à internet neste dia"
    echo "- O gerador de relatório não funcionou neste dia."
    echo "Faça o acesso via $SFTP e acesse a pasta:"
    echo "$LOGS/$ANO/$ANO-$MES/$DATA_ATUAL"
    echo "e procure/baixe o arquivo de log que tem interesse."
    press_enter_to_continue;
    return 1
  fi  
  
  FILETMP=`mktemp /tmp/email.XXXXXXXXXX` 
  SUBJECT="Relatorio de acesso a internet de [$LOGIN] no período [$DATA_ATUAL]"
  echo "Voce esta recebendo um relatorio de acessos do login [$LOGIN] no período [$DATA_ATUAL] porque o mesmo foi solicitado à nós.">>$FILETMP
  echo "Analise com cuidado as informações e mantenha sigilo das informações.">>$FILETMP
  echo "Contate o administrador da rede quando houverem duvidas.">>$FILETMP
  /home/administrador/scripts/enviar_email_admin.sh "$MAILTO" "$SUBJECT" "$FILETMP" "$LOGFILE"
  [ -f "$FILETMP" ] && rm -f "$FILETMP"
  echo "Relatório enviado com sucesso para $MAILTO." 
  press_enter_to_continue
}

function do_menu()
{
  clear
  while :
  do
    clear
    echo "-------------------------------------------------"
    echo "   R E L A T O R I O S  -  A U D I T O R I A"
    echo "-------------------------------------------------"
    echo "1 - Editar destinarios de auditoria de internet"
    echo "2 - Observar  log de acessos do proxy-cache ao vivo"
    echo "3 - Observar negação de acesso do proxy-cache ao vivo"
    echo "4 - Observar  log de autenticacao do proxy-cache ao vivo"
    echo "5 - Relatorio do proxy-cache por usuário"
    echo "6 - Relatorio do proxy-cache por site"
    echo "7 - Procurar duplicações em sites liberados"
    echo "99- Sair"
    echo -n "Escolha uma opcao [1-99] :"
    read opcao
    case $opcao in
    1)editar "$SQUIDACL/relatorio_emails.txt";;
    2)"$SCRIPTS/squid_observar_log.sh";;
    3)"$SCRIPTS/squid_observar_log.sh" "negados";;
    4)tail -f /var/log/squid3/cache.log;;
    5)proxy_relatorio;;
    6)"$SCRIPTS/squid_relatorio_site.sh";;
    7)"$SCRIPTS/squid_procura_duplicacoes.sh";;
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

SFTP="SFTP://administrador@192.168.1.253/~administrador"
do_menu
# Fim do Programa
