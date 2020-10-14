#!/bin/bash
# Funcao : Limpa os acessos avulsos do dia corrente
#
# Agende para 23:59hrs, acrescente ao crontab
# 59 23 * * *  /home/administrador/scripts/squid_limpar_usuarios_avulso.sh


# Variaveis importantes para este script
. /home/administrador/menu/mainmenu.var

# Funcoes importantes para este script
. /home/administrador/menu/mainmenu.functions

# Funcoes importantes para este script
. /home/administrador/fw-scripts/firewall.functions

function semremarks() {
  PARAMLINHA="$1"
  PARAMLINHA=${PARAMLINHA%% }
  PARAMLINHA=${PARAMLINHA## }
  #if [ `echo $PARAMLINHA|grep ^#|wc -l` -gt 0 ] ; then 
  #  echo "" 
  #  return
  #fi
  RESULT_VALUE=$(echo $PARAMLINHA|cut -d "#" -f1)
  echo "$RESULT_VALUE"
}

#
# Inicio do script
#

MAILTO="registros@vidy.com.br"
SUBJECT="lista de acesso dos usuarios avulsos foi eliminada."
TMPFILE_BODY_MAIL=`mktemp /tmp/email-$USU.XXXXXXXXXX`
DATA_ATUAL=`date +%Y-%m-%d`
FILE_AVULSOS="$SQUIDACL/usuarios_acesso_avulso.txt"
CREATE_REPORT=0
#
# Notificacao por email
#
if [ $CREATE_REPORT -gt 0 ] ; then
  echo "Os acessos de usuários avulsos foram eliminados.">$TMPFILE_BODY_MAIL
  echo "Atualmente estavam alistados como avulsos, os seguintes usuarios:">>$TMPFILE_BODY_MAIL
  cat "$FILE_AVULSOS" |grep -v "#">>$TMPFILE_BODY_MAIL

  #
  # Eliminando o acesso dos avulsos
  #
  echo -e "\tGerando relatorio de acesso à internet avulsos:"
  while read linha_ori ; do
    aprovado=1
    linha=`echo $linha_ori|grep -v '^#'`    
    USUARIO=`echo $linha|grep -v '^#'|cut -d '#' -f1|tr -d ' '`
    MOTIVO=`echo $linha|grep -v '^#'|cut -d '#' -f2`
    #echo "Linha ori: $linha_ori"
    #echo "Linha lida: $linha"
    if [ ! -z "$linha" ] ; then
      #echo "Param #1: $USUARIO"
      #echo "Param #2: $MOTIVO"
      if  [ $aprovado -gt 0 ] && [ $USUARIO = "joaoninguem" ] ; then
        echo "Erro de sintaxe: usuario joaoninguem nao e real."
        aprovado=0
      fi
      if  [ $aprovado -gt 0 ] && [ $USUARIO = $MOTIVO ] ; then
        echo "Erro de sintaxe: os dois parametros sao iguais."
        aprovado=0
      fi
      if [ $aprovado -gt 0 ] && [ -z "$USUARIO" ] ; then
        echo "Erro de sintaxe: não foi fornecido o usuario."
        aprovado=0
      fi
      if [ $aprovado -gt 0 ] && [ -z "$MOTIVO" ] ; then 
        echo "Erro de sintaxe: nao foi fornecido o motivo."  
        aprovado=0
      fi
      if [ $aprovado -eq 1 ] ; then
        echo -e "\t$SCRIPTS/squid_relatorio.sh \"$DATA_ATUAL\" \"$USUARIO\" "
        "$SCRIPTS/squid_relatorio.sh" "$DATA_ATUAL" "$USUARIO"
      fi
    fi

  done < "$FILE_AVULSOS"
fi

echo "\tLimpando o arquivo $FILE_AVULSOS"
[ -f "$FILE_AVULSOS" ] && rm -f "$FILE_AVULSOS"
cat > "$FILE_AVULSOS" <<END
# Este arquivo relaciona os logins que terao acesso total a internet
# de forma temporaria, eles possuem a mesmas limitacoes dos usuarios
# com acesso total (/etc/squid3/acl/usuarios_acesso_total.txt),
# a diferenca e' que os logins relacionados possuem
# prazo de validade ate as 23:59hrs.
# As 00:00hrs de cada dia este arquivo sera limpo,
# tornando necessario registrar logins avulsos novamente.
# Assim conseguimos permitir a um usuario da rede um acesso momentaneo
# a internet.
# Nao remova o "joaoninguem" da lista, pois ele e' necessario para servir
# este arquivo nunca fique em branco e produzir erros no log do
# de exemplo de como devem ser adicionados outros usuarios.
joaoninguem  # motivo do acesso
END

/home/administrador/scripts/enviar_email_admin.sh "$MAILTO" "$SUBJECT" "$TMPFILE_BODY_MAIL"

[ -f "$TMPFILE_BODY_MAIL" ] && rm -f "$TMPFILE_BODY_MAIL" 

echo "reiniciando com reload, o proxy-cache"
service squid3 reload

exit 0;
