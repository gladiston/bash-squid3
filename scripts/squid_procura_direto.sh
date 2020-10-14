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
echo "Digite o site que pretende acessar:"
echo "Use o formato de URL: http://www.receita.fazenda.gov.br"
read URL
if [ -z $URL ] ; then
  exit
fi

echo "Digite o IP da estação que fará o acesso:"
echo "Se vazio, o IP da estacao nao sera conferido."
read IP


echo "O tipo de acesso pelo autoconfigurador de proxy será:"
if [ -z $IP ] ; then
  pactester -p /var/www/html/wpad.dat -u $URL
else
  pactester -p /var/www/html/wpad.dat -u $URL -h $IP
fi
press_enter_to_continue;
echo -e "script finalizado com sucesso.\n"
exit 0; 
