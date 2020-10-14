#!/bin/bash
# Objetivo : Envia uma mensagem/anexo por email contendo informações
#            uteis.
# 
# Parametros :
# (1) Email do destinatario
# (2) Assunto
# (3) Arquivo contendo a mensagem que ficará no corpo do email
# (4) Arquivo a ser anexado (opcional)
#
function log() {
  msg="$1"
  [ $VERBOSE -gt 0 ] && echo -e "$msg"
  [ -f "/tmp/message" ] && echo -e "$msg" >>"/tmp/message"
}


#
# Inicio
#
VERBOSE=0
if ! [ -f "/usr/bin/mutt" ] ; then
  echo "Nao posso notificar por email por falta do arquivo : /usr/bin/mutt"
  exit 2;  
fi  
dt_agora="`date +%Y-%m-%d+%H:%M`"
MAILTO="$1"
COPYTO="registros@vidy.com.br"
log "criando mensagem /tmp/message"

if [ "$MAILTO" = "<admin>" ] ; then
  MAILTO="gladiston@vidy.com.br"
fi
SUBJECT="$2"
MAIL_TEXTFILE="$3"
ANEXO="$4"
if [ "$MAIL_TEXTFILE" = "" ] && [ -f "$SUBJECT" ] ; then
  MAIL_TEXTFILE="$2"
  SUBJECT=""
  ANEXO="$3"
fi

if [ "$SUBJECT" = "" ];  then
  SUBJECT="[$HOSTNAME] Tarefa administrativa executada"
else
  SUBJECT="[$HOSTNAME] $SUBJECT"
fi

echo "=> $SUBJECT" >/tmp/message
if [ ! -f "$MAIL_TEXTFILE" ] ; then
  log "----------------------------------------------------------------------------------"
  log "Esta mensagem foi enviada de nosso servidor $HOSTNAME em $dt_agora."
  log "Com o proposito de notifica-lo sobre a execução de alguma tarefa." 
  log "Observe a mensagem com cuidado, ele descreve sobre a falha ou sucesso de alguma tarefa executada no servidor [$HOSTNAME]." 
  log "Se esta msg estiver longe do seu entendimento, por favor contate o administrador da rede" 
  log "----------------------------------------------------------------------------------" 
fi
chmod 666 /tmp/message
#log "formalizando sintaxe com o comando mutt"
mutt_cmd=""
[ "$COPYTO" != "" ] && mutt_cmd="$mutt_cmd -c $COPYTO"
if [ -f "$MAIL_TEXTFILE" ] ; then
  cat "$MAIL_TEXTFILE" >>/tmp/message
fi
if [ -f "$ANEXO" ] ; then
  mutt_cmd="$mutt_cmd -a $ANEXO"
fi
#log "[exec] sudo mutt -s "$SUBJECT" $MAILTO $mutt_cmd </tmp/message"
# enviando e-mail
mutt -s "$SUBJECT" $MAILTO $mutt_cmd </tmp/message
RESULT_VALUE=$?
if [ $RESULT_VALUE -eq 0 ] ; then
   log "mensagem enviada."
else
   log "[$RESULT_VALUE] sudo $mutt_cmd </tmp/message"
   log "falha no envio da mensagem ($RESULT_VALUE) !"
fi
[ -f /tmp/message ] && rm -f /tmp/message
[ -f "$MAIL_TEXTFILE" ] && rm -f "$MAIL_TEXTFILE"
exit $RESULT_VALUE
