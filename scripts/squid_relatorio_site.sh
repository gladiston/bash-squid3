#!/bin/bash
# Funcao : Gera um relatorio em $LOG/fulano-DD-MM-AAAA com todos os seus acessos
#          a internet nesta data. Excluindo-se do relatório sites considerados
#          de livre acesso. 
#
# Parametros : (1) Data no formato AAAA-MM-DD (date +%Y-%m-%d)
#              (2) LOGIN
#                   Filtra apenas o login solicitado, ignorando os demais.
#                   Se ao invés do LOGIN for passado o nome de um arquivo entao
#                   assumirá-o como parametro3
#              (3) Nome do arquivo de log do squid, se nao for informado então assumirá
#                  /var/log/squid3/access.log
# Usos : antes de expirar o acesso de um usuario avulso, gerar um relatorio e
#        envia-lo para seu supervisor, assim seu supervidor fica sabendo a 
#        respeito do acesso de seus colaboradores e procura corrigir excessos 
#
# Para pegar ips diferentes com o mesmo login num log de usuario :
# cat 2011-10-21-marco.txt |cut -d" " -f4|sort -n| uniq
# Eventual agendamento para 23:30hrs, acrescente ao crontab
# 30 23 * * *  /home/administrador/scripts/squid_relatorio.sh $(date +%Y-%m-%d) 
# Variaveis importantes para este script
. /home/administrador/menu/mainmenu.var

# Funcoes importantes para este script
. /home/administrador/menu/mainmenu.functions

# Funcoes importantes para este script
. /home/administrador/fw-scripts/firewall.functions

# trap ctrl-c and call ctrl_c() trap ctrl_c INT
trap ctrl_c INT
function ctrl_c() {
  echo "*** interrompido pelo usuario ***" ;
  do_encerra
  exit 2;
}

function log() {
  echo -e "$1"
  #[ -f "$MYLOG" ] && echo -e "$1" >>"$MYLOG"
}

#
# Inicio do Script
#
echo -n "Digite o site a ser pesquisado:"
read PESQUISA_SITE
if [ -z $PESQUISA_SITE ] ; then
  exit 0;
fi

echo "Digite o email para onde será enviado o relatório"
echo "(não é preciso digitar @vidy.com.br)"
read MAILTO
if [ -z $MAILTO ] ; then
  exit 0;
fi

if ! [[ "$MAILTO" == *@* ]] ; then
    MAILTO="$MAILTO@vidy.com.br"    
fi

REMOVER_NEGADOS=1
echo -n "Devo remover os sites negados ? ([S]/N)"
read POSSO_REMOVER_NEGADOS
if [[ "$POSSO_REMOVER_NEGADOS" == *n* ]] || [[ "$POSSO_REMOVER_NEGADOS" == *N* ]]  ; then
  REMOVER_NEGADOS=0   
fi

REMOVER_ALMOCO=1
echo -n "Devo remover os acessos no horario de almoço ? ([S]/N)"
read POSSO_REMOVER_ALMOCO
if [[ "$POSSO_REMOVER_ALMOCO" == *n* ]] || [[ "$POSSO_REMOVER_ALMOCO" == *N* ]]  ; then
  REMOVER_ALMOCO=0  
fi

TMPFILE1=`mktemp /tmp/sites-pesquisa.XXXXXXXXXX`
TMPFILE2=`mktemp /tmp/sites-pesquisa.XXXXXXXXXX`
LOGFILE=`mktemp /tmp/sites-pesquisa-log.XXXXXXXXXX` 
SQUIDLOG='/var/log/squid3/access.log'

#
# Merge entre os arquivos de log
# Porém com a data já formatada em AAAA-MM-DD+HH:MM:SS.mmmm
# 
log "${t}#1 Inspecionando logs..."
[ -f "$TMPFILE1" ] && rm -f "$TMPFILE1"
LISTA_LOGS="$(find /var/log/squid3/access.log.*|sort -r)"
for ROTATELOG in $LISTA_LOGS ; do
  log "${tt}Adicionando o arquivo : $ROTATELOG"
  perl -MPOSIX -pe 's/\d+/strftime("%Y-%m-%d+%H:%M:%S",localtime($&))/e' "$ROTATELOG" >> "$TMPFILE1"
done 
perl -MPOSIX -pe 's/\d+/strftime("%Y-%m-%d+%H:%M:%S",localtime($&))/e' "$SQUIDLOG"  >> "$TMPFILE1"

# Gera o relatorio em formato csv 
# DATA1;SIZE2;IP3;TCP_MISS4;DOWNLOAD_SIZE5;CONNECT/GET/POST6;URL7;USUARIO8;DIRECT9/MIME10
# 2014-10-22+07:26:32.434    851 192.168.1.103 TCP_MISS/200 39717 GET http://www.decolar.com/shop/flights/results/roundtrip/SAO/RVD/2014-10-28/2014-10-29/1/0/0 deniseam DIRECT/38.99.237.22 text/html

log "Formatando em .csv de usuário..."
# O formato novo ficará:
# DATA1;IP3;USUARIO8;TCP_MISS4;DOWNLOAD_SIZE5;DIRECT9;CONNECT/GET/POST6;MIME10;URL7
awk -F " " '{print $1"\t"$3"\t"$8"\t"$4"\t"$5"\t"$9"\t"$6"\t"$10"\t"$7"\t"}' "$TMPFILE1" >"$TMPFILE2"

log "Eliminando coluna extra .nnn"
awk '$0=substr($0,1,16)substr($0,24,length($0))' "$TMPFILE2" >"$LOGFILE"

# Agora o formato CSV fica assim
#  2014-10-22+07:26        192.168.1.103   deniseam        TCP_DENIED/407    39717   DIRECT/38.99.237.22   GET     text/html       http://www.decolar.com/shop/flights/results/roundtrip/SAO/RVD/2014-10-28/2014-10-29/1/0/0

# Filtrando apenas o site desejado
log "Filtrando apenas o site $PESQUISA_SITE..."
cat "$LOGFILE"|grep "$PESQUISA_SITE">"$TMPFILE1"
mv -f "$TMPFILE1" "$LOGFILE"

LINHAS=$(wc -l "$LOGFILE"|cut -d" " -f1)
log "Quantidade de linhas para processar : $LINHAS"


#
# Removendo os acessos negados
#
if [ $REMOVER_NEGADOS -gt 0 ] ; then
  log "Removendo os acessos que foram negados..."
  sed -i '/DENIED/d' "$LOGFILE"
fi

#
# Alguns usuarios não podem ser auditados
#
log "Removendo logins que não devem ser auditados."
TMPFILE_USU=`mktemp`
[ -f "$TMPFILE_USU" ] && rm -f "$TMPFILE_USU"
echo " pierre ">>"$TMPFILE_USU"
echo " sergio ">>"$TMPFILE_USU"
#echo " gladiston ">>"$TMPFILE_USU"
#echo " suporte ">>"$TMPFILE_USU" 
grep -v -f "$TMPFILE_USU" "$LOGFILE" >"$TMPFILE1"
[ -f "$TMPFILE_USU" ] && rm -f "$TMPFILE_USU"

# Eliminando duplicacoes 
log "Eliminando linhas duplicadas"
uniq "$TMPFILE1" > "$LOGFILE" 

# 
# O horario do almoço não precisa ser auditado, no entanto, ele é
# salvo a parte em $LOGFILE_ALMOCO e depois é removido dos demais
# relatórios.
#
if [ $REMOVER_ALMOCO -gt 0 ] ; then
  log "${t}#14 Removendo do log os acessos no horario de almoço..."
  sed -i '/+12:/d' "$LOGFILE"
fi

#
# Se os arquivos de log estao vazios entao encerra o script
#
log "Contabilizando acessos..."
LINHAS=$(wc -l "$LOGFILE"|cut -d" " -f1)
log "\tQuantidade de linhas pós-processamento : $LINHAS"
if [ "$LINHAS" -eq 0 ] ; then
  log "\tNao houve atividade segundo os logs do squid."
  log "Encerrado o script."
  exit 0;
fi

# encerando o programa
[ -f "$TMPFILE2" ] && rm -f "$TMPFILE2"
echo "Voce esta recebendo um relatorio de acessos ao site $PESQUISA_SITE.">>$TMPFILE2
echo "Analise com cuidado as informações, lembre-se de que o acesso a essas informações é restrita.">>$TMPFILE2
echo "Contate o administrador da rede quando houverem duvidas.">>$TMPFILE2
SUBJECT="Relatorio de acessos ao site $PESQUISA_SITE"
/home/administrador/scripts/enviar_email_admin.sh "$MAILTO" "$SUBJECT" "$TMPFILE2" "$LOGFILE"
[ -f "$TMPFILE1" ] && rm -f "$TMPFILE1"
[ -f "$TMPFILE2" ] && rm -f "$TMPFILE2"
[ -f "$TMPFILE2" ] && rm -f "$LOGFILE"
echo "Enviando relatorio para $MAILTO com sucesso."

exit 0; 
