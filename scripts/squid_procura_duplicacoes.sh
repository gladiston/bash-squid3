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
. /home/administrador/scripts/functions.sh

# trap ctrl-c and call ctrl_c() trap ctrl_c INT
trap ctrl_c INT
function ctrl_c() {
  echo "*** interrompido pelo usuario ***" ;
  do_encerra
  exit 2;
}

#
# Inicio
#
echo "Relatorio de duplicacoes em arquivos de sites liberados do squid"
echo "Digite o email para onde será enviado o relatório"
echo "(não é preciso digitar @vidy.com.br)"
read MAILTO

if [ -z $MAILTO ] ; then
  exit 0;
fi
if ! [[ "$MAILTO" == *@* ]] ; then
    MAILTO="$MAILTO@vidy.com.br"    
fi



#
# Juntando arquivos diferentes
#
unset LP
unset LA
LA=( "${LA[@]}" "$SQUIDACL/sites_bancos.txt" )
LA=( "${LA[@]}" "$SQUIDACL/sites_cert.txt" )
LA=( "${LA[@]}" "$SQUIDACL/sites_diretos.txt" )
LA=( "${LA[@]}" "$SQUIDACL/sites_download.txt" )
LA=( "${LA[@]}" "$SQUIDACL/sites_exclusivo_almoco.txt" )
LA=( "${LA[@]}" "$SQUIDACL/sites_financeiro.txt" )
LA=( "${LA[@]}" "$SQUIDACL/sites_google.txt" )
LA=( "${LA[@]}" "$SQUIDACL/sites_governo.txt" )
LA=( "${LA[@]}" "$SQUIDACL/sites_livres.txt" )
LA=( "${LA[@]}" "$SQUIDACL/sites_suporte.txt" )
COUNT=0
#TMPFILE=`mktemp /tmp/sites-check-dup.XXXXXXXXXX` 
TMPFILE1="/tmp/sites-check-dup-1.csv"
TMPFILE2="/tmp/sites-check-dup-2.csv"
[ -f "$TMPFILE1" ] && rm -f "$TMPFILE1"
touch "$TMPFILE1"
for ARQUIVO in "${LA[@]}" ; do
  if [ -f "$ARQUIVO" ] ; then
    NOME_ARQ=$(basename $ARQUIVO)
    cat "$ARQUIVO"|grep -v "^#"|awk -v col2="$NOME_ARQ" -F " " '{print $1";"col2}' >>"$TMPFILE1"
  fi
done
sort -k1 -t';' -n "$TMPFILE1" >"$TMPFILE2"

#
# Varre linha a linha e procura ocorrencias mais do que 1
#
[ -f "$TMPFILE1" ] && rm -f "$TMPFILE1"
touch "$TMPFILE1"
while read LINHA ; do
  URL=`echo "$LINHA"|cut -d';' -f1`
  COUNT=`cat "$TMPFILE2"|grep "$URL"|wc -l`
  if [ $COUNT -gt 1 ] ; then
    COUNT=`cat "$TMPFILE1"|grep "$URL"|wc -l`
    if [ $COUNT -eq 0 ] ; then    
      cat "$TMPFILE2"|grep "$URL"|uniq|awk -v col2="$NOME_ARQ" -F ";" '{print $1"\t"$2}' >>"$TMPFILE1"
    fi
  fi
done < "$TMPFILE2"

#echo "cat \"$TMPFILE1\""

# encerando o programa
[ -f "$TMPFILE2" ] && rm -f "$TMPFILE2"
echo "Enviando relatorio para $MAILTO"
echo "Voce esta recebendo um relatorio de sites e/ou URLs duplicados em nosso sistema squid.">>$TMPFILE2
echo "Analise com cuidado as informacoes e remova as duplicacoes quando necessário.">>$TMPFILE2
echo "Contate o administrador da rede quando houverem duvidas.">>$TMPFILE2
SUBJECT="Relatorio de sites duplicados"
/home/administrador/scripts/enviar_email_admin.sh "$MAILTO" "$SUBJECT" "$TMPFILE2" "$TMPFILE1"
echo "script finalizado com sucesso."
[ -f "$TMPFILE1" ] && rm -f "$TMPFILE1"
[ -f "$TMPFILE2" ] && rm -f "$TMPFILE2"
exit 0; 
