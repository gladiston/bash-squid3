#!/bin/bash
# Funcao : Gera um relatorio com acessos suspeitos de login simultaneos, isto é,
#          estações que estão usando o mesma conta para navegar na internet.
#          Em teoria, cada colaborador acessa a internet apenas de seu computador,
#          assim, se a mesma conta estiver em uso em dois computadores diferentes
#          então trata-se de um jeito de fraudar o controle de acesso à internet.
#
# Parametros : (1) Data no formato AAAA-MM-DD (date +%Y-%m-%d)
# Eventual agendamento para 23:30hrs, acrescente ao crontab
# 45 23 * * *  /home/administrador/scripts/squid_relatorio_acessos_simultanos.sh `date \+\%Y-\%m-\%d`

# Variaveis importantes para este script
. /home/administrador/menu/mainmenu.var

# Funcoes importantes para este script
. /home/administrador/menu/mainmenu.functions

# Funcoes importantes para este script
. /home/administrador/fw-scripts/firewall.functions

#
# Inicio do Script
#

DATA_INICIO=`date +%d-%m-%Y+%H:%M`
PERIODO="$1"
t="  "
tt="    "
DEBUG_MODE=0  # Liga ou Desliga o modo debug
LOG_ANO=`date +%Y`
LOG_MES=`date +%m`
LOG_DIA=`date +%d`

if [ "$PERIODO" != "" ] ; then
  # A pasta de log terá a mesma nomenclatura da data, ie. yyyy-mm-dd.
  LOG_ANO=`echo "$PERIODO"|cut -d"-" -f1`
  LOG_MES=`echo "$PERIODO"|cut -d"-" -f2`
  LOG_DIA=`echo "$PERIODO"|cut -d"-" -f3`
fi

echo -e "\nIniciando em $DATA_INICIO o relatorio de acesso...."
CURRENT_DATE=`date +%Y-%m-%d`
LOG_FOLDER="$LOGS/$LOG_ANO/$LOG_ANO-$LOG_MES/$LOG_ANO-$LOG_MES-$LOG_DIA"
LOGFILE_SQUID="$LOG_FOLDER/$LOG_ANO-$LOG_MES-$LOG_DIA-0squid.csv"
LOG_OWNER="administrador"
TMPFILE=`mktemp /tmp/squid_relatorio_acessos_simultaneos-temp.XXXXXXXXXX` 
TMPFILE_USU=`mktemp /tmp/squid_relatorio_acessos_simultaneos-lista-usuarios.XXXXXXXXXX` 
TMPFILE_BODY_MAIL=`mktemp /tmp/squid_relatorio_acessos_simultaneos-email.XXXXXXXXXX`
MAILTO="suporte@vidy.com.br"
SUBJECT="Relatório de acessos simultaneos em [$PERIODO]"
if [ $DEBUG_MODE -gt 0 ] ; then
  # Pega o arquivo mais recente que existe no diretorio de logs arquivados
  LOGFILE_SQUID=$(find /home/administrador/logs -name *0squid.csv -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" ")
  LOG_FOLDER=$(dirname "$LOGFILE_SQUID") 
fi

echo -e "${t}Preparando relatorio de logins autenticados em maquinas diferentes..."
if ! [ -f "$LOGFILE_SQUID" ] ; then
  echo "Arquivo [$LOGFILE_SQUID] não foi encontrado."
  exit 2;
fi

LOGFILE_OUT="$LOG_FOLDER/$LOG_ANO-$LOG_MES-$LOG_DIA-3loginsduplicados.csv"
if [ $DEBUG_MODE -gt 0 ] ; then
  LOGFILE_OUT="/tmp/logins-simultaneos.csv" # debug
fi
[ -f "$LOGFILE_OUT" ] && rm -f "$LOGFILE_OUT"

#
# O relatorio está assim:
# 2015-03-11+15:42        192.168.1.132   delmice TCP_MISS/200    580     DIRECT/208.84.244.40    GET     application/json
# 
LINHAS=$(wc -l "$LOGFILE_SQUID"|cut -d" " -f1)
#
# Exibindo as variáveis atuais na tela
#
echo -e "${t}Filtrando a data: $PERIODO."
echo -e "${t}Pasta de Logs: $LOG_FOLDER."
echo -e "${t}Arquivo de entrada: $LOGFILE_SQUID."
echo -e "${t}Arquivo de saída: $LOGFILE_OUT."
echo -e "${t}Lista de usuários: $TMPFILE_USU."
echo -e "${t}Arq temporario: $TMPFILE."
echo -e "${t}Quantidade de linhas para processar : $LINHAS"
[ $DEBUG_MODE -eq 0 ] && echo -e "${t}Notificaçao por email: $MAILTO"

#
# Determinando os horario|ip|login ordem de usuario para o LOGFILE_OUT
#
awk -F " " '{print $1"\t"$2"\t"$3"\t"}' "$LOGFILE_SQUID"|sort -k3|uniq 2>&1 | tee "$LOGFILE_OUT"
sed -i '/\t\-/d' "$LOGFILE_OUT"

#
# Determinando os logins existentes para o TMPFILE_USU
#
awk -F "\t" '{print $3}' "$LOGFILE_SQUID"|sort|uniq 2>&1 | tee "$TMPFILE"
sed -i  '/^-/d' "$TMPFILE"
cat "$TMPFILE" |awk '{print length, $0}' | sort -n -r| cut -d " " -f2- 2>&1 | tee "$TMPFILE_USU"

# Detectando logins simultaneos
DATA_FIM=`date +%d-%m-%Y+%H:%M`
touch $TMPFILE_BODY_MAIL 
echo "Voce esta recebendo o relatório de acessos simultaneos à internet."   2>&1 | tee -a "$TMPFILE_BODY_MAIL"
echo "Isto é, usuários que foram detectados com a mesma autenticação em máquinas diferentes."  2>&1 | tee -a "$TMPFILE_BODY_MAIL"
echo "Não tome conclusões precipitadas, observe os horários e se eles coincidirem poderá significar que o colaborador em questão vazou sua senha."  2>&1 | tee -a "$TMPFILE_BODY_MAIL"
echo "Se constatar que a senha foi compartilhada entao bloqueie o login até que haja uma explicação convincente."  2>&1 | tee -a "$TMPFILE_BODY_MAIL"  
echo "."  2>&1 | tee -a "$TMPFILE_BODY_MAIL"
[ -f "$TMPFILE" ] && rm -f "$TMPFILE"
LAST_IP=""
LAST_USER=""
LAST_LINE=""
LAST_LINE_INC=""

# Remover do log algumas maquinas que geralmente terão acessos simultaneos
# como o servidor de terminal, os acessos do suporte em outras maquinas, etc..
# de auditar acessos de usuarios com acesso suspeito, mas nao sao
# devem ser mantidos porque nao sao seus acessos pessoais
sed -i '/eldorado.vidy.local/d' "$LOGFILE_OUT"
sed -i '/vmfinanceiro-01.vidy.local/d' "$LOGFILE_OUT"
sed -i '/backup-/d' "$LOGFILE_OUT"
sed -i '/sup.vidy.local/d' "$LOGFILE_OUT"
while read CURRENT_LINE ; do
  CURRENT_TIME=$(echo $CURRENT_LINE|cut -d' ' -f1) 
  CURRENT_TIME="${CURRENT_TIME##*( )}"                                          # Trim  
  CURRENT_IP=$(echo $CURRENT_LINE|cut -d' ' -f2)
  CURRENT_IP="${CURRENT_IP##*( )}"                                          # Trim  
  CURRENT_USER=$(echo $CURRENT_LINE|cut -d' ' -f3)
  CURRENT_USER="${CURRENT_USER##*( )}"                                          # Trim  
  CURRENT_HOSTNAME=$(dig -x $CURRENT_IP  +noall +answer|tail -n 1|cut -f4)
  CURRENT_HOSTNAME="${CURRENT_HOSTNAME##*( )}" # Trim
  echo -e "$CURRENT_TIME\t$CURRENT_IP\t$CURRENT_HOSTNAME\t$CURRENT_USER"
  [[ $CURRENT_HOSTNAME =~ ";;" ]] && CURRENT_HOSTNAME=""
  [ "$CURRENT_IP" == "" ] && LAST_IP="$CURRENT_IP"
  [ "$CURRENT_USER" == "" ] && LAST_USER="$CURRENT_USER"
  #[ "$LAST_LINE" == "" ] && LAST_LINE="$CURRENT_LINE"
  if [ "$CURRENT_HOSTNAME" != "" ] ; then
    if [ "$CURRENT_USER" == "$LAST_USER" ] ; then
       if [ "$CURRENT_IP" != "$LAST_IP" ] ; then
        if [ "$CURRENT_LINE" != "$LAST_LINE_INC" ] ; then
          LAST_TIME=$(echo $LAST_LINE|cut -d' ' -f1)  
          LAST_IP=$(echo $LAST_LINE|cut -d' ' -f2)
          LAST_USER=$(echo $LAST_LINE|cut -d' ' -f3)
          LAST_HOSTNAME=$(dig -x $LAST_IP  +noall +answer|tail -n 1|cut -f4)
          echo -e "$LAST_TIME\t$LAST_IP\t$LAST_HOSTNAME\t$LAST_USER"  2>&1 | tee -a "$TMPFILE_BODY_MAIL"
          echo -e "$CURRENT_TIME\t$CURRENT_IP\t$CURRENT_HOSTNAME\t$CURRENT_USER"  2>&1 | tee -a "$TMPFILE_BODY_MAIL"
          echo "$CURRENT_USER"  2>&1 | tee -a "$TMPFILE"
          LAST_LINE_INC="$CURRENT_LINE"
        fi  
      fi
    fi
    LAST_IP="$CURRENT_IP"
    LAST_USER="$CURRENT_USER"
    [ "$CURRENT_LINE" != "$LAST_LINE" ] && LAST_LINE="$CURRENT_LINE"
  fi
done < "$LOGFILE_OUT"

COUNT=$(cat "$TMPFILE"|uniq|wc -l|cut -d' ' -f1)
if [ $COUNT -gt 0 ] ; then
  echo "."  2>&1 | tee -a "$TMPFILE_BODY_MAIL"
  echo "Segue abaixo a lista de logins que foram avaliados no período $PERIODO:"  2>&1 | tee -a "$TMPFILE_BODY_MAIL"
  cat "$TMPFILE_USU"   2>&1 | tee -a "$TMPFILE_BODY_MAIL"
  cp -f "$TMPFILE_BODY_MAIL" "$LOGFILE_OUT"
  [ $DEBUG_MODE -eq 0 ] && /home/administrador/scripts/enviar_email_admin.sh "$MAILTO" "$SUBJECT" "$TMPFILE_BODY_MAIL"
else
  echo "."  2>&1 | tee -a "$TMPFILE_BODY_MAIL"
  echo "Nao houveram logins simultaneos no período $PERIODO"   2>&1 | tee -a "$TMPFILE_BODY_MAIL"
  cp -f "$TMPFILE_BODY_MAIL" "$LOGFILE_OUT"
  [ $DEBUG_MODE -eq 0 ] && /home/administrador/scripts/enviar_email_admin.sh "$MAILTO" "$SUBJECT" "$TMPFILE_BODY_MAIL"
fi
if [ $DEBUG_MODE -gt 0 ] ; then
   cat "$TMPFILE_BODY_MAIL" # debug
fi
[ -f "$LOGFILE_OUT" ] && chown $LOG_OWNER "$LOGFILE_OUT"
[ -f "$TMPFILE_BODY_MAIL" ] && rm -f "$TMPFILE_BODY_MAIL"
[ -f "$TMPFILE" ] && rm -f "$TMPFILE"
[ -f "$TMPFILE_USU" ] && rm -f "$TMPFILE_USU"

# encerando o programa
echo -e "${t}Logins simultaneos identificados : $COUNT"
echo -e "Relatório encerrado em $DATA_FIM"

exit 0; 

