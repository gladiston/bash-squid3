#!/bin/bash
# Funcao : Enviar para log, modificações realizadas em arquivos do squid
#
#

function log() {
  msg="$1"
  [ $VERBOSE -gt 0 ] && echo -e "$msg"
  [ -f "$TMPFILE_BODY_MAIL" ] && echo -e "$msg" >>"$TMPFILE_BODY_MAIL"
}

#
# Inicio do script
#
VERBOSE=0
MAILTO="registros@vidy.com.br"
DATA_ATUAL=`date +%Y-%m-%d-%H:%M`
TMPFILE1=`mktemp /tmp/squid_diff1.XXXXXXXXXX` || exit 1
TMPFILE2=`mktemp /tmp/squid_diff2.XXXXXXXXXX` || exit 1
TMPFILE_BODY_MAIL=`mktemp /tmp/squid_diff_email.XXXXXXXXXX` || exit 1
FILE_ORI=$1
FILE_DST=$2

SUBJECT="Em $DATA_ATUAL foi modificado o arquivo $(basename $FILE_ORI)."
#
# Notificacao por email
#
touch "$TMPFILE_BODY_MAIL"
#echo "Modificações foram realizadas no arquivo $FILE_ORI.">>$TMPFILE_BODY_MAIL
#echo "As linhas abaixo relatarão as modificações realizadas:">>$TMPFILE_BODY_MAIL
#log "Arq.Temp #1:$TMPFILE1"
#log "Arq.Temp #1:$TMPFILE2"

# linhas em branco e comentários (#) serão ignorados
grep -v '^#' "$FILE_ORI"|grep -v '^joaoninguem' >$TMPFILE1
grep -v '^#' "$FILE_DST"|grep -v '^joaoninguem' >$TMPFILE2
sed '/^\s*$/d' $TMPFILE1
sed '/^\s*$/d' $TMPFILE2

#
# Analise linha a linha
#
log "Alistando remoções e acréscimos em $FILE_ORI:"
while read linha ; do
  #log "conferindo $linha em $TMPFILE1"
  existe=`cat "$TMPFILE2"|grep "^$linha"|wc -l`
  if [ $existe -eq 0 ] ; then
    SQUID_DATE=`date +%Y-%m-%d`
    SQUID_USER=`echo "$linha"|cut -d' ' -f1`
    if [[ "$FILE_ORI.$FILE_DST" == *usuarios_acesso_avulso* ]] ; then 
      /home/administrador/scripts/squid_relatorio.sh "$SQUID_DATE" "$SQUID_USER"
    fi  
    log "Remoção: $linha"
  fi
done < "$TMPFILE1"

while read linha ; do
  #log "conferindo $linha em $TMPFILE2"
  existe=`cat "$TMPFILE1"|grep "^$linha"|wc -l`
  if [ $existe -eq 0 ] ; then
    log "Acréscimo: $linha"
  fi
done < "$TMPFILE2"

# Enviando relatorio
/home/administrador/scripts/enviar_email_admin.sh "$MAILTO" "$SUBJECT" "$TMPFILE_BODY_MAIL"

[ -f "$TMPFILE1" ] && rm -f "$TMPFILE1"
[ -f "$TMPFILE2" ] && rm -f "$TMPFILE2"
[ -f "$TMPFILE_BODY_MAIL" ] && rm -f "$TMPFILE_BODY_MAIL"


exit 0;

