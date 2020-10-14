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
#
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
  [ -f "$MYLOG" ] && echo -e "$1" >>"$MYLOG"
}

function do_encerra {
 # removendo arquivos temporarios
 do_cabecalho
 [ -f "$TMPFILE_IGNORADOS" ] && rm -f "$TMPFILE_IGNORADOS"
 [ -f "$TMPFILE_PARCIAL" ] && rm -f "$TMPFILE_PARCIAL"
 [ -f "$TMPFILE" ] && rm -f "$TMPFILE"
 [ -f "$TMPFILE_USU" ] && rm -f "$TMPFILE_USU"
 DATA_FIM=`date +%d-%m-%Y+%H:%M`
 if [ "$ENVIAR_EMAIL" -gt 0 ] ; then
   for LINHA in "${ANEXOS[@]}" ; do
      USU=$(echo "$LINHA"|cut -d "|" -f1)
      ARQUIVO=$(echo "$LINHA"|cut -d "|" -f2)
      MAILTO="<admin>"
      AVULSO=0
      if [ "$USU" = "" ] ; then
        SUBJECT="Relatório de acesso a internet em [$PERIODO]"
      else
        SUBJECT="Relatório de acesso a internet de [$USU] em [$PERIODO]"
	    fi
      COUNT=`grep ^$USU $SQUIDACL/usuarios_acesso_fixo.txt|wc -l|cut -d' ' -f1`
      [ $COUNT -eq 0 ] && COUNT=`grep ^$USU $SQUIDACL/usuarios_administradores.txt|wc -l|cut -d' ' -f1`
      [ $COUNT -eq 0 ] && AVULSO=1
      if [ $AVULSO -gt 0 ] ; then      
        MOTIVO=`cat "$SQUIDACL/usuarios_acesso_avulso.txt"|grep ^$USU`
        if [ -z "$MOTIVO" ] ; then
          MOTIVO="(objetivo foi removido antes da emissao desse relatorio)"
        else
          MOTIVO=`cat "$SQUIDACL/usuarios_acesso_avulso.txt"|grep ^$USU|cut -d '#' -f2`
        fi
        SUBJECT="Relatório de acesso avulso a internet de [$USU] em [$PERIODO] com objetivo de $MOTIVO"
      fi
      TEST_LINHA=$(/bin/grep "$USU " "$SQUIDACL/relatorio_emails.txt")
      TEST_USU=$(echo "$TEST_LINHA" |cut -d' ' -f1|tr -d ' ')
      TEST_EMAIL=$(echo "$TEST_LINHA" |cut -d' ' -f2|tr -d ' ')
      if [[ "$TEST_EMAIL" == *@* ]] ; then
        MAILTO="$TEST_EMAIL"
      fi	
      #echo "USUARIO=$TEST_USU->$TEST_EMAIL($MAILTO)"
      TMPFILE_BODY_MAIL=`mktemp /tmp/email-$USU.XXXXXXXXXX`           
      echo "$SUBJECT - enviando por email para [$MAILTO]"
      if [ "$MAILTO" = "" ] || [ "$MAILTO" = "<admin>" ] ; then
        echo "Era para o supervisor de [$USU] receber o relatório anexo, contudo este programa automatizado desconhece seu paradeiro.">>$TMPFILE_BODY_MAIL
        echo "Por gentileaza, altere o script [squid_relatorio.sh] para que as mensagens de [$USU] cheguem ao seu supervisor.">>$TMPFILE_BODY_MAIL    
      else
        echo "Voce [$MAILTO] esta recebendo o relatório de acesso à internet de [$USU]." >>$TMPFILE_BODY_MAIL
        if [ $AVULSO -gt 0 ] ; then
          echo "O colaborador [$USU] solicitou acesso avulso a internet para o período [$PERIODO] com o objetivo de $MOTIVO." >>$TMPFILE_BODY_MAIL
          echo "Confira se os acessos são coerentes com o objetivo." >>$TMPFILE_BODY_MAIL
          echo "Se não for, relembre-o das regras de conduta com respeito a acesso à internet." >>$TMPFILE_BODY_MAIL
        fi
        echo "Este sistema esta calibrado para que todos os acessos desse colaborador sejam redirecionados a voce.">>$TMPFILE_BODY_MAIL
        echo "Isso é feito de forma automatica e autonoma, contudo pode haver outros colaboradores cujos relatórios não estejam sendo enviados a voce ou o inverso, chegam relatorios de colaboradores que não estão sob sua gestão.">>$TMPFILE_BODY_MAIL
        echo "Qualquer que seja o caso, sempre contate o administrador da rede quando houverem erros.">>$TMPFILE_BODY_MAIL
      fi
      echo "O arquivo anexo está em formato de planilha .CSV e pode ser aberto com o LibreOffice (mais fácil) ou o Excel, em ambos os casos o formato CSV esta delimitado por TAB(tabulações) para simplificar a importação.">>$TMPFILE_BODY_MAIL
      echo "Uma cópia desse relatório é mantida no servidor e pode ser observado por diretores, gestores e administradores de rede.">>$TMPFILE_BODY_MAIL
      /home/administrador/scripts/enviar_email_admin.sh "$MAILTO" "$SUBJECT" "$TMPFILE_BODY_MAIL" "$ARQUIVO" 
    done
  fi
}

function do_cabecalho {
  log "\n${t}Arquivo de entrada original : $SQUIDLOG."
  if [ "$SOMENTE_LOGIN" = "todos" ] ; then
    log "${t}Arquivo de saida squid : $LOGFILE_SQUID."
    log "${t}Arquivo de saida publico : $LOGFILE_TODOS."
    log "${t}Arquivo de saida almoço : $LOGFILE_ALMOCO."
  fi
  log "${t}Lista de ignorados : $TMPFILE_IGNORADOS."
  log "${t}Lista de acessos : $TMPFILE_PARCIAL."
  log "${t}Lista de usuários : $TMPFILE_USU."
  log "${t}Arq temporario : $TMPFILE."
  log "${t}Filtrando a data : $PERIODO."
  log "${t}Filtrando o login : $SOMENTE_LOGIN."
  log "${t}Pasta de Logs : $LOG_FOLDER."
  log "${t}Criando uma lista de sites nao-auditaveis."
}

#
# Inicio do Script
#
DATA_INICIO=`date +%d-%m-%Y+%H:%M`
PERIODO="$1"
SOMENTE_LOGIN="$2"
[ "$SOMENTE_LOGIN" = "" ] && SOMENTE_LOGIN="todos"
[ "$SOMENTE_LOGIN" = "TODOS" ] && SOMENTE_LOGIN="todos"
[ "$SOMENTE_LOGIN" = "ALL" ] && SOMENTE_LOGIN="todos"
[ "$SOMENTE_LOGIN" = "all" ] && SOMENTE_LOGIN="todos"
LOGFILE=""
LOGFILE_TODOS=""
LOGFILE_SQUID=""
SQUIDLOG="$3"
t="  "
tt="    "
if [ -f "$2" ] ; then
 SOMENTE_LOGIN="todos" 
 SQUIDLOG="$2"
fi

if [ -z "$SQUIDLOG" ] || [ "$SQUIDLOG" == "" ] ; then
  SQUIDLOG="/var/log/squid3/access.log"
  #SQUIDLOG="/tmp/access.log"
fi

if ! [ -f "$SQUIDLOG" ] ; then
  echo "Arquivo [$SQUIDLOG] não foi encontrado."
  exit 2;
fi

LOG_ANO=`date +%Y`
LOG_MES=`date +%m`
LOG_DIA=`date +%d`
LOG_HORA="`date +%H`h`date +%M`m`date +%S`s"
MYLOG="/var/log/squid3/relatorio-$LOG_ANO-$LOG_MES-$LOG_DIA-$LOG_HORA.txt"
if [ "$PERIODO" != "" ] ; then
  # A pasta de log terá a mesma nomenclatura da data, ie. yyyy-mm-dd.
  LOG_ANO=`echo "$PERIODO"|cut -d"-" -f1`
  LOG_MES=`echo "$PERIODO"|cut -d"-" -f2`
  LOG_DIA=`echo "$PERIODO"|cut -d"-" -f3`
fi

LOG_FOLDER="$LOGS/pub"
LOG_UNIXDATE=`date +%s`

# REMOVER_IGNORADOS
# =0 -> mantem no relatorio sites que poderiam ser ignorados
# >0 -> faz um recorte no relatório removendo sites que podem 
#       ser ignorados. Isso faz com que o relatório seja um 
#       bem mais lento para ser concluído.
REMOVER_IGNORADOS=1
[ "$SOMENTE_LOGIN" != "todos" ] && REMOVER_IGNORADOS=1

# ENVIAR_EMAIL
# "1" -> Envia o relatório por email para os supervisores
ENVIAR_EMAIL=1
[ "$SOMENTE_LOGIN" = "todos" ] && ENVIAR_EMAIL=0


log "\nIniciando em $DATA_INICIO o relatorio de acesso...."
TMPFILE=`mktemp /tmp/squid_relatorio-lixo.XXXXXXXXXX` 
TMPFILE_USU=`mktemp /tmp/squid_lista-usuarios.XXXXXXXXXX` 
TMPFILE_IGNORADOS="/tmp/squid-lista-sites-ignorados-$LOG_ANO-$LOG_MES-$LOG_DIA.txt"
TMPFILE_PARCIAL="/tmp/squid_relatorio-parcial-$LOG_ANO-$LOG_MES-$LOG_DIA-$LOG_HORA.txt"
if [ "$PERIODO" != "" ] && [ "$SOMENTE_LOGIN" = "todos" ] ; then
  LOG_FOLDER="$LOGS/$LOG_ANO/$LOG_ANO-$LOG_MES/$LOG_ANO-$LOG_MES-$LOG_DIA"
  # Se a pasta contiver arquivos entao automaticamente a pasta de log
  # será desviada para outro local
  EXISTE=`find "$LOG_FOLDER" -type f|wc -l`
  if [ "$EXISTE" -gt 0 ] ; then
    LOG_FOLDER="$LOGS/pub/$PERIODO"
  fi
fi

LOGFILE_SQUID="$LOG_FOLDER/$LOG_ANO-$LOG_MES-$LOG_DIA-0squid.csv"
LOGFILE_ALMOCO="$LOG_FOLDER/$LOG_ANO-$LOG_MES-$LOG_DIA-1almoco.csv"
LOGFILE_TODOS="$LOG_FOLDER/$LOG_ANO-$LOG_MES-$LOG_DIA-2todos.csv"
log "${t}#1 Analizando a criação da pasta $LOG_FOLDER..."
if ! [ -f "$LOGFILE_TODOS" ] ; then
   log "${tt} Criando a pasta $LOG_FOLDER..."
   mkdir -p "$LOG_FOLDER"
fi

do_cabecalho


#
# Merge entre os arquivos de log
# Porém com a data já formatada em AAAA-MM-DD+HH:MM:SS.mmmm
# 
log "${t}#2 Inspecionando logs..."
[ -f "$TMPFILE_PARCIAL" ] && rm -f "$TMPFILE_PARCIAL"
LISTA_LOGS="$(find /var/log/squid3/access.log.*|sort -r)"
for ROTATELOG in $LISTA_LOGS ; do
  log "${tt}Adicionando o arquivo : $ROTATELOG"
  perl -MPOSIX -pe 's/\d+/strftime("%Y-%m-%d+%H:%M:%S",localtime($&))/e' "$ROTATELOG" >> "$TMPFILE_PARCIAL"
done 
perl -MPOSIX -pe 's/\d+/strftime("%Y-%m-%d+%H:%M:%S",localtime($&))/e' "$SQUIDLOG"  >> "$TMPFILE_PARCIAL"

LINHAS=$(wc -l "$TMPFILE_PARCIAL"|cut -d" " -f1)
log "${t}Quantidade de linhas para processar : $LINHAS"

#
# Mantendo apenas o período desejado
# 
log "${t}#3 Filtrando período..."
if [ "$PERIODO" != "" ] ; then
  log "${tt} Filtrando acessos livres e mantendo apenas os acessos da data $PERIODO"
  grep "$PERIODO" "$TMPFILE_PARCIAL" > "$TMPFILE"
  mv -f "$TMPFILE" "$TMPFILE_PARCIAL"
fi

#
# Removendo os acessos negados
#
log "${t}#4 Removendo os acessos que foram negados..."
sed -i '/DENIED/d' "$TMPFILE_PARCIAL"

#
# Alguns usuarios não podem ser auditados
#
log "${t}#5 Removendo logins que não devem ser auditados."
[ -f "$TMPFILE_USU" ] && rm -f "$TMPFILE_USU"
echo " pierre ">>"$TMPFILE_USU"
echo " sergio ">>"$TMPFILE_USU"
#echo " gladiston ">>"$TMPFILE_USU"
#echo " suporte ">>"$TMPFILE_USU" 
grep -v -f "$TMPFILE_USU" "$TMPFILE_PARCIAL" >"$TMPFILE"
cp -f "$TMPFILE_USU" /home/administrador/usuarios.csv
#
# Gera o relatorio em formato csv 
# DATA1;SIZE2;IP3;TCP_MISS4;DOWNLOAD_SIZE5;CONNECT/GET/POST6;URL7;USUARIO8;DIRECT9/MIME10
# 2014-10-22+07:26:32.434    851 192.168.1.103 TCP_MISS/200 39717 GET http://www.decolar.com/shop/flights/results/roundtrip/SAO/RVD/2014-10-28/2014-10-29/1/0/0 deniseam DIRECT/38.99.237.22 text/html

log "${t}#6 Formatando em .csv de usuário..."
# O formato novo ficará:
# DATA1;IP3;USUARIO8;TCP_MISS4;DOWNLOAD_SIZE5;DIRECT9;CONNECT/GET/POST6;MIME10;URL7
awk -F " " '{print $1"\t"$3"\t"$8"\t"$4"\t"$5"\t"$9"\t"$6"\t"$10"\t"$7"\t"}' "$TMPFILE" >"$TMPFILE_PARCIAL"

# Agora o formato CSV fica assim
#  2014-10-22+07:26        192.168.1.103   deniseam        TCP_MISS/200    39717   DIRECT/38.99.237.22   GET     text/html       http://www.decolar.com/shop/flights/results/roundtrip/SAO/RVD/2014-10-28/2014-10-29/1/0/0

log "${t}#7 Eliminando coluna extra .nnn"
awk '$0=substr($0,1,16)substr($0,24,length($0))' "$TMPFILE_PARCIAL" >"$TMPFILE"

# Eliminando duplicacoes 
log "${t}#8 Eliminando linhas duplicadas"
uniq "$TMPFILE" > "$TMPFILE_PARCIAL" 

# Eliminando http:// e https://
#log "${t}#9 Eliminando o texto http:// e https://"
#sed -i -e 's/https:\/\///g' "$TMPFILE_PARCIAL"
#sed -i -e 's/http:\/\///g' "$TMPFILE_PARCIAL"

# Debug
#cp "$TMPFILE_PARCIAL" /home/administrador/teste.csv
#exit

#
# Até aqui temos nos logs todos os acessos com exceção dos logins
# que nao podem ser auditados. Entao aqui temos o arquivo
# $LOGFILE_SQUID ponto
log "${t}#9 Analizando a criação do arquivo $LOGFILE_SQUID."
if [ "$SOMENTE_LOGIN" = "todos" ] ; then
  log "${tt}#9 Criando o arquivo $LOGFILE_SQUID."
  cp -f "$TMPFILE_PARCIAL" "$LOGFILE_SQUID"
fi

#
# Preparando uma lista de sites que porque são sempre livres 
# não precisam ser auditados.
#
log "${t}#10 Analizando arquivo de sites para serem ignorados."
#[ -f "$TMPFILE_IGNORADOS" ] && rm -f "$TMPFILE_IGNORADOS"
if ! [ -f "$TMPFILE_IGNORADOS" ] ; then
  log "${tt} Preparando arquivo de sites para serem ignorados."
  [ -f "$SQUIDACL/sites_google.txt" ] && cat "$SQUIDACL/sites_google.txt" >>$TMPFILE_IGNORADOS
  [ -f "$SQUIDACL/sites_diretos.tx" ] && cat "$SQUIDACL/sites_diretos.txt" >>$TMPFILE_IGNORADOS
  [ -f "$SQUIDACL/sites_governo.txt" ] && cat "$SQUIDACL/sites_governo.txt" >>$TMPFILE_IGNORADOS
  [ -f "$SQUIDACL/sites_livres.txt" ] && cat "$SQUIDACL/sites_livres.txt" >>$TMPFILE_IGNORADOS
  [ -f "$SQUIDACL/sites_suporte.txt" ] && cat "$SQUIDACL/sites_suporte.txt" >>$TMPFILE_IGNORADOS

  # Criando uma lista em memoria dos sites que devem ser ignorados
  echo "# Lista de sites a serem ignorados" >"$TMPFILE"
  while read URL ; do
    SITE=`convert_url2site "$URL"`
    echo $SITE >>"$TMPFILE"
  done < "$TMPFILE_IGNORADOS"     
  mv -f "$TMPFILE" "$TMPFILE_IGNORADOS"

  # removendo IPs da lista
  grep -v -e "^[0-9]*[0-9]*[0-9][.][0-9]*[0-9]*[0-9][.][0-9]*[0-9]*[0-9]" "$TMPFILE_IGNORADOS" >"$TMPFILE"
  mv -f "$TMPFILE" "$TMPFILE_IGNORADOS"

  # removendo tipos de download
  unset ignorar_mime
  ignorar_mime=( "${ignorar_mime[@]}" "image/gif" )
  ignorar_mime=( "${ignorar_mime[@]}" "image/x-icon" )
  ignorar_mime=( "${ignorar_mime[@]}" "application/x-shockwave-flash" )
  ignorar_mime=( "${ignorar_mime[@]}" "text/javascript" )
  ignorar_mime=( "${ignorar_mime[@]}" "application/vnd.google.safebrowsing-chunk" )
  ignorar_mime=( "${ignorar_mime[@]}" "image/png" )
  ignorar_mime=( "${ignorar_mime[@]}" "application/ocsp-response" )
  ignorar_mime=( "${ignorar_mime[@]}" "application/javascript" )
  ignorar_mime=( "${ignorar_mime[@]}" "application/x-javascript" )
  ignorar_mime=( "${ignorar_mime[@]}" "image/jpg" )
  ignorar_mime=( "${ignorar_mime[@]}" "application/json" )
  ignorar_mime=( "${ignorar_mime[@]}" "application/xml" )
  #ignorar_mime=( "${ignorar_mime[@]}" "xxxxxx" )
  #ignorar_mime=( "${ignorar_mime[@]}" "xxxxxx" )
  # realizando o backup dos volumes alistados acima
  log "${tt} Removendo do log alguns tipos mimes..."
  for mime in "${ignorar_mime[@]}" ; do
    #log "${t}${t}$mime"
    echo "$mime" >>"$TMPFILE_IGNORADOS"
  done

  # ordenando as linhas
  log "${tt} Colocando em ordem alfabetica de sites nao auditados."
  cp -f "$TMPFILE_IGNORADOS" "$TMPFILE" 
  sort "$TMPFILE" > "$TMPFILE_IGNORADOS"

  # removendo duplicacoes
  log "${tt} Removendo possiveis duplicacoes de sites nao auditados."
  cp -f "$TMPFILE_IGNORADOS" "$TMPFILE" 
  uniq "$TMPFILE" > "$TMPFILE_IGNORADOS" 

  # removendo linhas vazias
  log "${tt} Removendo linhas vazias do arquivo de sites nao auditados."
  cp -f "$TMPFILE_IGNORADOS" "$TMPFILE" 
  grep -v -e "^$" "$TMPFILE" >"$TMPFILE_IGNORADOS"
  
  # removendo linhas comentadas
  log "${tt} Removendo linhas de comentários."
  sed '/^\#/d' "$TMPFILE_IGNORADOS" > "$TMPFILE"
  mv -f "$TMPFILE" "$TMPFILE_IGNORADOS"
fi
IGNORADOS=$(wc -l "$TMPFILE_IGNORADOS"|cut -d" " -f1)
log "${t}#11 Quantidade de sites livres (não auditáveis) : $IGNORADOS"
# 
# O horario do almoço não precisa ser auditado, no entanto, ele é
# salvo a parte em $LOGFILE_ALMOCO e depois é removido dos demais
# relatórios.
#
log "${t}#12 Analizando se precisa salvar o log do horario de almoço em local diferente..."
if [ "$SOMENTE_LOGIN" = "todos" ] ; then
  log "${t}Criando o arquivo $LOGFILE_ALMOCO"
  grep "+12" "$TMPFILE_PARCIAL" >"$LOGFILE_ALMOCO"
fi

#
# Remove do log acessos que estão sempre liberados 
#
log "${t}#13 Analizando a remoção de sites que devem ser ignorados..."
if [ "$REMOVER_IGNORADOS" -gt 0 ] ; then
  log "${tt} Removendo do log do squid acessos a serem ignorados (demorado)..."
  grep -v -f "$TMPFILE_IGNORADOS" "$TMPFILE_PARCIAL" >"$TMPFILE"
  mv -f "$TMPFILE" "$TMPFILE_PARCIAL"
fi

# 
# O horario do almoço não precisa ser auditado, no entanto, ele é
# salvo a parte em $LOGFILE_ALMOCO e depois é removido dos demais
# relatórios.
#
log "${t}#14 Removendo do log os acessos no horario de almoço..."
sed -i '/+12:/d' "$TMPFILE_PARCIAL"

#
# Se os arquivos de log estao vazios entao encerra o script
#
log "${t}#15 Contabilizando acessos..."
LINHAS=$(wc -l "$TMPFILE_PARCIAL"|cut -d" " -f1)
log "${t}Quantidade de linhas pós-processamento : $LINHAS"
if [ "$LINHAS" -eq 0 ] ; then
  log "${tt} Nao houve atividade segundo os logs do squid."
  log "${t}#99 Encerrado o script."
  do_encerra
  exit 0;
fi

#
# Até aqui temos nos logs todos os acessos com exceção dos logins
# que nao podem ser auditados e acessos que são livres. 
# Entao aqui temos o arquivo $LOGFILE_TODOS pronto.
#
log "${t}#16 Analizando filtro de login para todos ou login especifico..."
if [ "$SOMENTE_LOGIN" = "todos" ] ; then 
  log "${tt} Criando o arquivo $LOGFILE_TODOS"
  cp -f "$TMPFILE_PARCIAL" "$LOGFILE_TODOS"
else
  # Se estiver que filtrar um LOGIN especifico entao
  # executamos um procedimento onde cortamos qualquer outro login
  # que nao seja o mencionado 
  log "${tt} Mantendo no log apenas os acessos do usuário $SOMENTE_LOGIN"
  grep -P "\t$SOMENTE_LOGIN\t" "$TMPFILE_PARCIAL" >"$TMPFILE"
  mv -f "$TMPFILE" "$TMPFILE_PARCIAL"
fi

# Debug
#cp "$TMPFILE_PARCIAL" /home/administrador/teste.csv
#exit


#
# Determinando os usuarios existentes no log
# $TMPFILE_IGNORADOS será usado para conter uma lista de caracteres
# que se ocorrem no LOGIN do usuario, não é um  LOGIN, é apenas uma linha 
# mal formatada no squid
#
log "${t}#17 Determinando os usuários presentes no relatório"
awk -F "\t" '{print $3}' "$TMPFILE_PARCIAL"|sort|uniq >"$TMPFILE"
sed -i '/\-/d' "$TMPFILE"
sed -i '/\=/d' "$TMPFILE"
sed -i '/\;/d' "$TMPFILE"
sed -i '/\./d' "$TMPFILE"
sed -i '/\?/d' "$TMPFILE"
mv -f "$TMPFILE" "$TMPFILE_USU"
#grep -v '\-' "$TMPFILE" >"$TMPFILE_USU"
#grep -v '\=' "$TMPFILE_USU" >"$TMPFILE"
#grep -v '\;' "$TMPFILE" >"$TMPFILE_USU"
#grep -v '\.' "$TMPFILE_USU" >"$TMPFILE"
#grep -v '\?' "$TMPFILE" >"$TMPFILE_USU"

# Preparando os anexos que poderão ser enviados por email
log "${t}#18 Preparando os anexos que poderão ser enviados por email"
unset ANEXOS
while read USUARIO ; do
  if [ "$USUARIO" != "-" ] ; then
    LOGFILE="$LOG_FOLDER/$LOG_ANO-$LOG_MES-$LOG_DIA-$USUARIO.csv"
    log "${tt} Separando e distribuindo lista de acesso do usuario [$USUARIO]."
    # O formato csv atual é :
    # DATA1;IP2;USUARIO3;TCP_MISS4;DOWNLOAD_SIZE5;DIRECT6;CONNECT/GET/POST7;MIME8;URL9
    # Deverá ficar:
    # 2014-10-28+16:27	192.168.1.109	washington	GET	image/webp	http://mlb-d1-p.mlstatic.com/18776-MLB20160161163_092014-S.webp	
    awk -F "\t" '{print $1"\t"$2"\t"$3"\t"$7"\t"$8"\t"$9"\t"}' "$TMPFILE_PARCIAL" | grep -P "\t$USUARIO\t"  >"$LOGFILE"
    COUNT=`wc -l "$LOGFILE" |cut -d' ' -f1`
    if [ $COUNT -gt 0 ] ; then
      ANEXOS=( "${ANEXOS[@]}" "$USUARIO|$LOGFILE" )
    else
      log "${tt} $USUARIO nao tem logs para serem enviados por email"
    fi
  fi
done < "$TMPFILE_USU"

# encerando o programa
log "${t}#99 Encerrado o script."
do_encerra

exit 0; 
