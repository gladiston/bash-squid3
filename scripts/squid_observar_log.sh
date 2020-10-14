#!/bin/bash

# Variaveis importantes para este script
. /home/administrador/menu/mainmenu.var

# Funcoes importantes para este script
. /home/administrador/menu/mainmenu.functions

# trap ctrl-c and call ctrl_c() trap ctrl_c INT
trap ctrl_c INT
function ctrl_c() {
  echo "*** interrompido pelo usuario ***" ;
  [ -f "$TMPFILE" ] && rm -f "$TMPFILE"
  [ -f "$SHFILE" ] && rm -f "$SHFILE"
  exit 2;
}

SOMENTE_NEGADOS=0
[[ "$1" =~ "neg" ]] && SOMENTE_NEGADOS=1

clear;
echo "##################################################################"
echo "# Observando os acessos a internet                               #";
if [ $SOMENTE_NEGADOS -gt 0 ] ; then
  echo "# SOMENTE DE ACESSOS QUE FOREM NEGADOS                           #"
  echo "# Essa opção é util para descobrir que sites devem ser liberados #"
fi
echo "##################################################################"
echo "# Digite o nome do usuario que gostaria de filtrar, ou qualquer  #"
echo "# outra resposta, exibira todos os usuarios ate entao.           #"
echo "##################################################################"
read somente_usuario

#
# Iniciando a leitura
#
TMPFILE=`mktemp /tmp/squid-sites-publicos.XXXXXXXXXX` || exit 1
SHFILE=`mktemp /tmp/squid-observar.XXXXXXXXXX` || exit 1
cat "$SQUIDACL/sites_servico.txt" >$TMPFILE
#cat "$SQUIDACL/sites_diretos.txt" >>$TMPFILE
#cat "$SQUIDACL/sites_governo.txt" >>$TMPFILE
#cat "$SQUIDACL/sites_livres.txt" >>$TMPFILE

# remarcando o inicio de linha
sed -i -e 's/^/\^*/' $TMPFILE

cmd_tail="tail -f \"/var/log/squid3/access.log\""
cmd_grepfile="grep -v -w -f \"$TMPFILE\""
if [ $SOMENTE_NEGADOS -gt 0 ] ; then
  cmd_grepuser="grep -i \"$somente_usuario\"|grep \"TCP_DENIED\""
else
  cmd_grepuser="grep -i \"$somente_usuario\""
fi
cmd_squidlog="$SCRIPTS/squidlog.sh"
cmd="$cmd_tail|$cmd_squidlog"

echo "Os logs estarao sendo observados, apenas nao serao exibidos acessos considerados publicos."
echo "De um [Ctrl+C] para sair e retornar ao menu."
if ! [ -z "$somente_usuario" ] ; then
  echo "rastreando somente o usuario [$somente_usuario]"
  cmd="$cmd_tail|$cmd_squidlog|$cmd_grepuser"
fi
# debug
echo $cmd
# comando de rastreio
echo "#!/bin/bash" >$SHFILE
echo "$cmd" >>$SHFILE
bash $SHFILE
rm -f $TMPFILE
rm -f $SHFILE
