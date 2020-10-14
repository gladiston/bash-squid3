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
html_file=/var/www/html/sites_liberados.html
i=0
#
# Submete a pesquisa em varios arquivos diferentes
#
echo "Gerando arquivo HTML em $html_file..."
unset LP
unset LA
LA=( "${LA[@]}"  )
LA=( "${LA[@]}" "$SQUIDACL/sites_diretos_ip.txt" )
LA=( "${LA[@]}" "$SQUIDACL/sites_diretos.txt" )
LA=( "${LA[@]}" "$SQUIDACL/sites_download.txt" )
LA=( "${LA[@]}" "$SQUIDACL/sites_exclusivo_almoco.txt" )
LA=( "${LA[@]}" "$SQUIDACL/sites_financeiro.txt" )
LA=( "${LA[@]}" "$SQUIDACL/sites_google.txt" )
LA=( "${LA[@]}" "$SQUIDACL/sites_governo.txt" )
LA=( "${LA[@]}" "$SQUIDACL/sites_livres.txt" )
LA=( "${LA[@]}" "$SQUIDACL/sites_livres_regex.txt" )
LA=( "${LA[@]}" "$SQUIDACL/sites_suporte.txt" )

#
# Cabecalho HTML
#
current_timestamp=$(date +"%Y-%m-%d %T")
echo '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">'>$html_file
echo '<html lang="pt-br"><head>'>>$html_file
echo '<meta content="text/html; charset=UTF-8" http-equiv="content-type">'>>$html_file
echo '<title>Lista de sites com livre acesso</title>'>>$html_file
echo '<meta http-equiv="content-type" content="text/html; charset=utf-8">'>>$html_file
echo '<style type="text/css"></style>'>>$html_file
echo '</head>'>>$html_file
echo '<body>'>>$html_file
echo '<center><h3>Lista de sites livres</h3></center>'>>$html_file
echo "<small><center>Publicado em: $current_timestamp</center></small>">>$html_file

ARQUIVO="$SQUIDACL/sites_certificados.txt"
for ARQUIVO in "${LA[@]}" ; do
  if [ -f "$ARQUIVO" ] ; then
    echo '<table style="text-align: left; width: 100%; background-color: rgb(239, 237, 237);" border="0" cellpadding="2" cellspacing="0">'>>$html_file
    echo '<tbody>'>>$html_file
    echo '<tr>'>>$html_file
    echo '<td style="vertical-align: middle; text-align: center; width: 100%; ">'>>$html_file
    echo "<h3>$ARQUIVO</h3>" >>$html_file
    echo '</td>'>>$html_file
    echo '</tr>'>>$html_file
    while IFS= read -r line
    do
      echo '<tr>'>>$html_file
      if [ $((i%2)) -eq 0 ] ; then
        echo '<td style="vertical-align: middle; text-align: left; width: 100%; background-color: rgb(211, 211, 211);">'>>$html_file
      else
        echo '<td style="vertical-align: middle; text-align: left; width: 100%; ">'>>$html_file
      fi         
      if [ "$line" != "" ] ; then
        if [ ${line:0:1} != "#" ] ; then
          i=$((i+1))
          echo "<b>$i.</b> ">>$html_file
        fi
      fi
      echo "$line<br>">>$html_file
      echo '</td>'>>$html_file
      echo '</tr>'>>$html_file
    done < "$ARQUIVO"
    echo '</tbody>'>>$html_file
    echo '</table>'>>$html_file
  fi
done

#
# Finalizando HTML
#
echo '</body>'>>$html_file
echo '</html>'>>$html_file


# encerando o programa
unset LP
unset LA
echo -e "Arquivo HTML pronto.\n"
echo -e "script finalizado com sucesso.\n"
exit 0; 
