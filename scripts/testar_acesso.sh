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

#
# Inicio
#
TESTAR_SITE=""
TRY_USER=""
TRY_PASSWORD=""
for CURRENT_PARAM in "$@" ; do
  CURRENT_PARAM="${CURRENT_PARAM##*( )}"                                          # Trim
  #echo "Debug: $CURRENT_PARAM"
  if [[ "$CURRENT_PARAM" =~ "-site:" ]] ; then 
    TESTAR_SITE=$(eval echo "$CURRENT_PARAM"|cut -d':' -f2)
    #echo "Param -site detectado."
  fi
  if [[ "$CURRENT_PARAM" =~ "-user:" ]] ; then 
    TRY_USER=$(eval echo "$CURRENT_PARAM"|cut -d':' -f2)
    #echo "Param -user detectado."
  fi 
  if [[ "$CURRENT_PARAM" =~ "-password:" ]] ; then 
    TRY_PASSWORD=$(eval echo "$CURRENT_PARAM"|cut -d':' -f2)
    #echo "Param -password detectado."    
  fi    
done

if [ "$TESTAR_SITE" == "" ] ; then
  echo "Digite o site que procura saber se está liberado ou não:"
  echo "Pressione ENTER para assumir o site padrao:"
  echo "www.uol.com.br"
  read TESTAR_SITE
  if [ -z $TESTAR_SITE ] || [ "$TESTAR_SITE" == "" ]; then
     TESTAR_SITE="www.uol.com.br"
  fi
fi


#
# Primeiro testa como usuario comum se o site esta liberado ou nao
#
#PROXY_TEST_USER="proxy_internet"
#PROXY_TEST_PASS="vidy55anos"
#PROXY_TEST_DOMAIN=VIDY
#PROXY_IFACE=eth0
#PROXY_PORT=3128
FILE_TMP="/tmp/testa-acesso-site-$TESTAR_SITE-como-$PROXY_TEST_USER"
TESTAR_SITE="${TESTAR_SITE##*( )}"
if grep -q '^http' <<<$mask; then
  echo "http:// presente na URL"
else
  echo "Adicionando http:// na URL $TESTAR_SITE."
   TESTAR_SITE="http://$TESTAR_SITE"
fi
[ -f "$FILE_TMP" ] && rm -f "$FILE_TMP"
PROXY_IP=$(ifconfig $PROXY_IFACE|grep 'inet end.:'|cut -d':' -f2|xargs|cut -d' ' -f1)
if [ "$TRY_USER" == "" ] ; then
  echo "Digite o login de acesso (vazio assumirá [$PROXY_TEST_USER]):"
  read TRY_USER
  if [ "$TRY_USER" == "" ] ; then
     TRY_USER="$PROXY_TEST_USER"
     TRY_PASSWORD="$PROXY_TEST_PASS"
  fi
fi

if [ "$TRY_PASSWORD" == "" ] ; then
  echo "Digite a senha do login $TRY_USER:"
  read TRY_PASSWORD
fi
TRY_USER="${TRY_USER##*( )}" 
TRY_PASSWORD="${TRY_PASSWORD##*( )}" 

#echo "http_proxy=\"http://$TRY_USER:$TRY_PASSWORD@$PROXY_IP:$PROXY_PORT\""
http_proxy="http://$TRY_USER:$TRY_PASSWORD@$PROXY_IP:$PROXY_PORT"
export http_proxy
echo "+--------------------------------------------------------------------------------+"
echo "|      Testando o acesso via proxy a internet com as seguintes configuracoes      |"
echo "+--------------------------------------------------------------------------------+"
echo "Proxy: $PROXY_IP"
echo "Usuário: $TRY_USER"
echo "Senha: *****"
echo "Url para teste: $TESTAR_SITE"
/usr/bin/curl -I "$TESTAR_SITE"  
echo "Se não houver nenhuma linha indicativa de erro então é porque o acesso foi concedido a $TRY_USER."
echo "Alguns erros comuns:"
echo "Proxy Authentication Required: O login/senha de $TRY_USER não estava correta."
echo "Forbidden: Acesso proibido."

# encerando o programa
echo "Pressione [ENTER] para prosseguir..."
read espera
[ -f "$FILE_TMP" ] && rm -f "$FILE_TMP"

exit 0; 
