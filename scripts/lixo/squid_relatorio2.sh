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
  echo -e "$1" >>"$MYLOG"
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
      USU=$(echo "$LINHA"|cut -d '|' -f1|tr -d ' ')
      ARQUIVO=$(echo "$LINHA"|cut -d '|' -f2)
      MAILTO="<admin>"
      if [ "$USU" = "" ] ; then
        SUBJECT="Relatório de acesso a internet"
      else
        SUBJECT="Relatório de acesso a internet de [$USU]"
      fi

      # Informatica 
      [ "$USU" = "gladiston" ] && MAILTO="gladiston@vidy.com.br"
      [ "$USU" = "suporte" ] && MAILTO="suporte@vidy.com.br"
      [ "$USU" = "rudd" ] && MAILTO="rudd@vidy.com.br"

      #  Compras
      [ "$USU" = "adriana" ] && MAILTO="delmice@vidy.com.br"
      [ "$USU" = "helton" ] && MAILTO="delmice@vidy.com.br"
      [ "$USU" = "delmice" ] && MAILTO="delmice@vidy.com.br"

      # VENDAS / Equipamentos
      [ "$USU" = "andre" ] && MAILTO="sergio@vidy.com.br"
      [ "$USU" = "gonzalo" ] && MAILTO="sergio@vidy.com.br"

      [ "$USU" = "catorcamentos" ] && MAILTO="luiza@vidy.com.br"

      # PCP
      [ "$USU" = "carlosm" ] && MAILTO="carlosm@vidy.com.br"      
      [ "$USU" = "daniel" ] && MAILTO="carlosm@vidy.com.br"
      [ "$USU" = "michael" ] && MAILTO="carlosm@vidy.com.br"
      [ "$USU" = "deniseam" ] && MAILTO="carlosm@vidy.com.br"
      [ "$USU" = "convidado_pcp" ] && MAILTO="carlosm@vidy.com.br"
      [ "$USU" = "rogelio" ] && MAILTO="carlosm@vidy.com.br"

      # Custos
      [ "$USU" = "joaquim" ] && MAILTO="joaquim@vidy.com.br"
      
      # Vendas e Orcamentos
      [ "$USU" = "luiza" ] && MAILTO="luiza@vidy.com.br"
      [ "$USU" = "convidado_vendas" ] && MAILTO="luiza@vidy.com.br"
      [ "$USU" = "sueli" ] && MAILTO="luiza@vidy.com.br"
      [ "$USU" = "tania" ] && MAILTO="luiza@vidy.com.br"
      [ "$USU" = "ericabs" ] && MAILTO="luiza@vidy.com.br"
      [ "$USU" = "vanusa" ] && MAILTO="luiza@vidy.com.br"
      [ "$USU" = "tatiana" ] && MAILTO="luiza@vidy.com.br"
      [ "$USU" = "anapmc" ] && MAILTO="luiza@vidy.com.br"
      [ "$USU" = "convidado_vendas" ] && MAILTO="luiza@vidy.com.br"
      [ "$USU" = "ricardoc" ] && MAILTO="luiza@vidy.com.br"
      [ "$USU" = "paula" ] && MAILTO="luiza@vidy.com.br"
      [ "$USU" = "glauciasl" ] && MAILTO="luiza@vidy.com.br"

      # Contabilidade
      [ "$USU" = "ambrosina" ] && MAILTO="ambrosina@vidy.com.br"
      [ "$USU" = "convidado_ctb" ] && MAILTO="ambrosina@vidy.com.br"
      [ "$USU" = "admin_ctb" ] && MAILTO="ambrosina@vidy.com.br"
      [ "$USU" = "annag" ] && MAILTO="ambrosina@vidy.com.br"
      [ "$USU" = "fabio" ] && MAILTO="ambrosina@vidy.com.br"
      [ "$USU" = "patricia" ] && MAILTO="ambrosina@vidy.com.br"
      [ "$USU" = "sara" ] && MAILTO="ambrosina@vidy.com.br"
      
      # RH
      [ "$USU" = "ferreira" ] && MAILTO="ferreira@vidy.com.br"
      [ "$USU" = "convidado_rh" ] && MAILTO="ambrosina@vidy.com.br"
      [ "$USU" = "admin_rh" ] && MAILTO="ambrosina@vidy.com.br"
      [ "$USU" = "luana" ] && MAILTO="ferreira@vidy.com.br"
      [ "$USU" = "suellenrm" ] && MAILTO="ferreira@vidy.com.br"
      [ "$USU" = "cleudinea" ] && MAILTO="ferreira@vidy.com.br"
      [ "$USU" = "flavio" ] && MAILTO="ferreira@vidy.com.br"
	  [ "$USU" = "jaquelineas" ] && MAILTO="rh.admin@vidy.com.br"
	  [ "$USU" = "eliana" ] && MAILTO="rh.admin@vidy.com.br"
      
      # Financeiro     
      [ "$USU" = "edna" ] && MAILTO="edna@vidy.com.br"
      [ "$USU" = "convidado_financeiro" ] && MAILTO="edna@vidy.com.br"
      [ "$USU" = "alinecvr" ] && MAILTO="edna@vidy.com.br"

      # Producao 
      [ "$USU" = "perlino" ] && MAILTO="perlino@vidy.com.br"
      [ "$USU" = "joserubens" ] && MAILTO="perlino@vidy.com.br"
      [ "$USU" = "leonardor" ] && MAILTO="perlino@vidy.com.br"
      [ "$USU" = "valmir" ] && MAILTO="perlino@vidy.com.br"
      [ "$USU" = "felipe" ] && MAILTO="perlino@vidy.com.br"
      [ "$USU" = "jacinto" ] && MAILTO="perlino@vidy.com.br"

      # AssTec
	  [ "$USU" = "alexjcs" ] && MAILTO="perlino@vidy.com.br"
	  
	  # projetos
      [ "$USU" = "josecarlos" ] && MAILTO="josecarlos@vidy.com.br"
      [ "$USU" = "convidado_projetos" ] && MAILTO="josecarlos@vidy.com.br"
      [ "$USU" = "lucas" ] && MAILTO="josecarlos@vidy.com.br"
      [ "$USU" = "brunov" ] && MAILTO="josecarlos@vidy.com.br"
      [ "$USU" = "thiago" ] && MAILTO="josecarlos@vidy.com.br"
      [ "$USU" = "gustavo" ] && MAILTO="josecarlos@vidy.com.br"
      [ "$USU" = "cleberp" ] && MAILTO="josecarlos@vidy.com.br"

      #  Assistencia Tecnica
      [ "$USU" = "luciano" ] && MAILTO="perlino@vidy.com.br"
      [ "$USU" = "washington" ] && MAILTO="perlino@vidy.com.br"
      
      # Markting
      [ "$USU" = "julianos" ] && MAILTO="administrador@vidy.com.br"
      [ "$USU" = "marco" ] && MAILTO="administrador@vidy.com.br"

      # Almox
	  [ "$USU" = "brandon" ] && MAILTO="perlino@vidy.com.br"
	  [ "$USU" = "gustavos" ] && MAILTO="perlino@vidy.com.br"
      [ "$USU" = "rosario" ] && MAILTO="perlino@vidy.com.br"


      # Supervisao desconhecida
	  [ "$USU" = "rogelio" ] && MAILTO="carlosm@vidy.com.br"
      
      TMPFILE_BODY_MAIL=`mktemp /tmp/email-$USU.XXXXXXXXXX` || exit 1            
      echo "$SUBJECT - enviando por email para [$MAILTO]"
      if [ "$MAILTO" = "" ] || [ "$MAILTO" = "<admin>" ] ; then
        echo "Era para o supervisor de [$USU] receber o relatório anexo, contudo este programa automatizado desconhece seu paradeiro.">>$TMPFILE_BODY_MAIL
        echo "Por gentileaza, altere o script [squid_relatorio.sh] para que as mensagens de [$USU] cheguem ao seu supervisor.">>$TMPFILE_BODY_MAIL    
      else
        echo "Voce [$MAILTO] esta recebendo o relatório de acesso à internet de [$USU]." >$TMPFILE_BODY_MAIL
        echo "Este sistema esta calibrado para que todos os acessos desse colaborador sejam redirecionados a voce.">>$TMPFILE_BODY_MAIL
        echo "Isso é feito de forma automatica e autonoma, contudo pode haver outros colaboradores cujos relatórios não estejam sendo enviados a voce ou o inverso, chegam relatorios de colaboradores que não estão sob sua gestão.">>$TMPFILE_BODY_MAIL
        echo "Qualquer que seja o caso, sempre contate o administrador da rede quando houverem erros.">>$TMPFILE_BODY_MAIL
      fi
      echo "O arquivo anexo está em formato de planilha e pode ser aberto com o LibreOffice (mais fácil) ou o Excel, em ambos os casos o formato CSV esta delimitado por contra-barra(|) para simplificar a importação.">>$TMPFILE_BODY_MAIL
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
ENVIAR_EMAIL=0
[ "$SOMENTE_LOGIN" = "todos" ] && ENVIAR_EMAIL=1


log "\nIniciando em $DATA_INICIO o relatorio de acesso...."
TMPFILE=`mktemp /tmp/squid_relatorio-lixo.XXXXXXXXXX` || exit 1
TMPFILE_USU=`mktemp /tmp/squid_lista-usuarios.XXXXXXXXXX` || exit 1
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
if ! [ -f "$LOGFILE_TODOS" ] ; then
   log "${t}Criando pasta $LOG_FOLDER..."
   mkdir -p "$LOG_FOLDER"
fi

do_cabecalho


#
# Merge entre os arquivos de log
# Porém com a data já formatada em AAAA-MM-DD+HH:MM:SS.mmmm
# 
[ -f "$TMPFILE_PARCIAL" ] && rm -f "$TMPFILE_PARCIAL"
LISTA_LOGS="$(find /var/log/squid3/access.log.*|sort -r)"
for ROTATELOG in $LISTA_LOGS ; do
  log "${t}Adicionando o arquivo : $ROTATELOG"
  perl -MPOSIX -pe 's/\d+/strftime("%Y-%m-%d+%H:%M:%S",localtime($&))/e' "$ROTATELOG" >> "$TMPFILE_PARCIAL"      
done 
perl -MPOSIX -pe 's/\d+/strftime("%Y-%m-%d+%H:%M:%S",localtime($&))/e' "$SQUIDLOG"  >> "$TMPFILE_PARCIAL" 

LINHAS=$(wc -l "$TMPFILE_PARCIAL"|cut -d" " -f1)
log "${t}Quantidade de linhas para processar : $LINHAS"

#
# Mantendo apenas o período desejado
# 
if [ "$PERIODO" != "" ] ; then
  log "${t}Filtrando acessos livres e mantendo apenas os acessos da data $PERIODO"
  grep "$PERIODO" "$TMPFILE_PARCIAL" > "$TMPFILE"
  mv -f "$TMPFILE" "$TMPFILE_PARCIAL"
fi

#
# Alguns usuarios não podem ser auditados
#
log "${t}Removendo do log do squid alguns logins que não devem ser auditados."
[ -f "$TMPFILE_USU" ] && rm -f "$TMPFILE_USU"
echo " pierre ">>"$TMPFILE_USU"
echo " sergio ">>"$TMPFILE_USU"
echo " gladiston ">>"$TMPFILE_USU"
echo " suporte ">>"$TMPFILE_USU" 
grep -v -f "$TMPFILE_USU" "$TMPFILE_PARCIAL" >"$TMPFILE"

#
# Gera o relatorio em formato csv 
#
log "${t}Formatando em .csv"
awk -F " " '{print $1"|"$2"|"$3"|"$4"|"$5"|"$6"|"$7"|"$8"|"$9"|"$10"|"$11"|"$12"|"$13"|"$14"|"$15"|"}' "$TMPFILE" >"$TMPFILE_PARCIAL"

#
# Até aqui temos nos logs todos os acessos com exceção dos logins
# que nao podem ser auditados. Entao aqui temos o arquivo
# $LOGFILE_SQUID ponto
if [ "$SOMENTE_LOGIN" = "todos" ] ; then
  log "${t}Criando o arquivo $LOGFILE_SQUID."
  cp -f "$TMPFILE_PARCIAL" "$LOGFILE_SQUID"
fi

#
# Preparando uma lista de sites que porque são sempre livres 
# não precisam ser auditados.
#
log "${t}Preparando arquivo de sites para serem ignorados."
#[ -f "$TMPFILE_IGNORADOS" ] && rm -f "$TMPFILE_IGNORADOS"
if ! [ -f "$TMPFILE_IGNORADOS" ] ; then
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
  log "${t}Removendo do log alguns tipos mimes..."
  for mime in "${ignorar_mime[@]}" ; do
    #log "${t}${t}$mime"
    echo "$mime" >>"$TMPFILE_IGNORADOS"
  done

  # ordenando as linhas
  log "${t}Colocando em ordem alfabetica de sites nao auditados."
  cp -f "$TMPFILE_IGNORADOS" "$TMPFILE" 
  sort "$TMPFILE" > "$TMPFILE_IGNORADOS"

  # removendo duplicacoes
  log "${t}Removendo possiveis duplicacoes de sites nao auditados."
  cp -f "$TMPFILE_IGNORADOS" "$TMPFILE" 
  uniq "$TMPFILE" > "$TMPFILE_IGNORADOS" 

  # removendo linhas vazias
  log "${t}Removendo linhas vazias do arquivo de sites nao auditados."
  cp -f "$TMPFILE_IGNORADOS" "$TMPFILE" 
  grep -v -e "^$" "$TMPFILE" >"$TMPFILE_IGNORADOS"
  
  # removendo linhas comentadas
  sed '/^\#/d' "$TMPFILE_IGNORADOS" > "$TMPFILE"
  mv -f "$TMPFILE" "$TMPFILE_IGNORADOS"
fi
IGNORADOS=$(wc -l "$TMPFILE_IGNORADOS"|cut -d" " -f1)
log "${t}Quantidade de sites livres (não auditáveis) : $IGNORADOS"
# 
# O horario do almoço não precisa ser auditado, no entanto, ele é
# salvo a parte em $LOGFILE_ALMOCO e depois é removido dos demais
# relatórios.
#
if [ "$SOMENTE_LOGIN" = "todos" ] ; then
  log "${t}Criando o arquivo $LOGFILE_ALMOCO"
  grep "+12" "$TMPFILE_PARCIAL" >"$LOGFILE_ALMOCO"
fi

#
# Remove do log acessos que estão sempre liberados 
#
if [ "$REMOVER_IGNORADOS" -gt 0 ] ; then
  log "${t}Removendo do log do squid acessos a serem ignorados (demorado)"
  grep -v -f "$TMPFILE_IGNORADOS" "$TMPFILE_PARCIAL" >"$TMPFILE"
  mv -f "$TMPFILE" "$TMPFILE_PARCIAL"
fi

# 
# O horario do almoço não precisa ser auditado, no entanto, ele é
# salvo a parte em $LOGFILE_ALMOCO e depois é removido dos demais
# relatórios.
#
grep -v "+12:" "$TMPFILE_PARCIAL" >"$TMPFILE"
mv -f "$TMPFILE" "$TMPFILE_PARCIAL"

#
# Se os arquivos de log estao vazios entao encerra o script
#
LINHAS=$(wc -l "$TMPFILE_PARCIAL"|cut -d" " -f1)
log "${t}Quantidade de linhas pós-processamento : $LINHAS"
if [ "$LINHAS" -eq 0 ] ; then
  log "${t}Nao houve atividade segundo os logs do squid."
  do_encerra
  exit 0;
fi

#
# Até aqui temos nos logs todos os acessos com exceção dos logins
# que nao podem ser auditados e acessos que são livres. 
# Entao aqui temos o arquivo $LOGFILE_TODOS pronto.
#
if [ "$SOMENTE_LOGIN" = "todos" ] ; then 
  log "${t}Criando o arquivo $LOGFILE_TODOS"
  cp -f "$TMPFILE_PARCIAL" "$LOGFILE_TODOS"
else
  # Se estiver que filtrar um LOGIN especifico entao
  # executamos um procedimento onde cortamos qualquer outro login
  # que nao seja o mencionado 
  log "${t}Mantendo no log apenas os acessos do usuário $SOMENTE_LOGIN"
  grep "|$SOMENTE_LOGIN|" "$TMPFILE_PARCIAL" >"$TMPFILE"
  mv -f "$TMPFILE" "$TMPFILE_PARCIAL"
fi

#
# Determinando os usuarios existentes no log
# $TMPFILE_IGNORADOS será usado para conter uma lista de caracteres
# que se ocorrem no LOGIN do usuario, não é um  LOGIN, é apenas uma linha 
# mal formatada no squid
#
log "${t}Determinando os usuários presentes no relatório"
awk -F "|" '{print $8}' "$TMPFILE_PARCIAL"|sort|uniq >"$TMPFILE"
grep -v '\-' "$TMPFILE" >"$TMPFILE_USU"
grep -v '\=' "$TMPFILE_USU" >"$TMPFILE"
grep -v '\;' "$TMPFILE" >"$TMPFILE_USU"
grep -v '\.' "$TMPFILE_USU" >"$TMPFILE"
grep -v '\?' "$TMPFILE" >"$TMPFILE_USU"

# Preparando os anexos que poderão ser enviados por email
unset ANEXOS
while read USUARIO ; do
  if [ "$USUARIO" != "-" ] ; then
    LOGFILE="$LOG_FOLDER/$LOG_ANO-$LOG_MES-$LOG_DIA-$USUARIO.csv"
    log "${t}Separando e distribuindo lista de acesso do usuario [$USUARIO]."
    awk -F "|" '{print $1"|"$3"|"$4"|"$5"|"$7"|"$8"|"$7"|"$8"|"}' "$TMPFILE_PARCIAL" | grep "|$USUARIO|"  >"$LOGFILE"
    #awk -F "|" '{print "$1|$3|$5|$7|$8|$7|$8|"}' "$TMPFILE_PARCIAL" | grep "|$USUARIO|"  >"$LOGFILE"
    ANEXOS=( "${ANEXOS[@]}" "$USUARIO|$LOGFILE" )
  fi
done < "$TMPFILE_USU"
 
# encerando o programa
do_encerra

exit 0; 
