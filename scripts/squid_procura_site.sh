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
echo "Digite o site ou IP que procura saber se está liberado ou não:"
read PESQUISAR
if [ -z $PESQUISAR ] ; then
  exit
fi

#
# Submete a pesquisa em varios arquivos diferentes
#
echo "Procurando $PESQUISA em nossas listas ACLs..."
unset LP
unset LA
LA=( "${LA[@]}" "$SQUIDACL/sites_certificados.txt" )
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

COUNT=0
for ARQUIVO in "${LA[@]}" ; do
  if [ -f "$ARQUIVO" ] ; then
    NOME_ARQ=$(basename $ARQUIVO)
    echo "=>$NOME_ARQ..."
    EXISTE_COUNT=`cat "$ARQUIVO"|grep $PESQUISAR|wc -l`
    if [ $EXISTE_COUNT -gt 0 ] ; then
      LP=( "${LP[@]}" "$NOME_ARQ|$EXISTE_COUNT" )
      COUNT=$[$COUNT +$EXISTE_COUNT]
      cat "$ARQUIVO"|grep $PESQUISAR|awk -F "\t" '{print "  "$1}'
    fi
  fi
done

#
# Se nao achou nada, entao sai do script
#
if [ $COUNT -eq 0 ] ; then
  echo "Qualquer ocorrência com [$PESQUISAR] está bloqueado pelo proxy."
  press_enter_to_continue;
  echo "script finalizado com sucesso."
  exit 0;
fi
#press_enter_to_continue;
echo " "
#
# Ou entao exibe onde as ocorrências foram feitas
#
echo "Foram encontradas $COUNT ocorrências com [$PESQUISAR]."
echo "Elas estão liberados pelas regras nos seguintes arquivos:"
for LINHA in "${LP[@]}" ; do
  #echo "echo \"$LINHA\"|cut -d'|' -f1"
  ARQ=`echo "$LINHA"|cut -d'|' -f1`
  EXISTE_COUNT=`echo "$LINHA"|cut -d'|' -f2`
  echo "$EXISTE_COUNT => $ARQ"
done

# encerando o programa
unset LP
unset LA
press_enter_to_continue;
echo -e "script finalizado com sucesso.\n"
exit 0; 
