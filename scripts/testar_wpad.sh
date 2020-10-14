#!/bin/bash
# Funcao: testar uma mascara de rede

# Variaveis importantes para este script
. /home/administrador/menu/mainmenu.var
if [ $? -ne 0 ] ; then
  echo "Nao foi possivel importar o arquivo [/home/administrador/menu/mainmenu.var] !"
  exit 2;
fi

# Funcoes importantes para este script
. /home/administrador/scripts/functions.sh
if [ $? -ne 0 ] ; then
  echo "Nao foi possivel importar o arquivo [/home/administrador/scripts/functions.sh] !"
  exit 2;
fi

# Funcoes importantes para este script
. /home/administrador/fw-scripts/firewall.functions
if [ $? -ne 0 ] ; then
  echo "Nao foi possivel importar o arquivo [/home/administrador/fw-scripts/firewall.functions] !"
  exit 2;
fi

# Pegando o ip do proxy
PROXY_IP=$(ifconfig $PROXY_IFACE|grep 'inet end.:'|cut -d':' -f2|xargs|cut -d' ' -f1)
FILE_TEMP="/tmp/testar-velocidade-$PROXY_IP.log"

if valid_ip $PROXY_IP ; then
  echo "Proxy: $PROXY_IP"
else
  echo "Nenhum proxy no arquivo /home/administrador/menu/mainmenu.var"
  exit 2
fi

# wpad
if [ -f "$1" ] ; then
  WPAD_FILE="$1"
  echo "Localização do wpad.dat:"
  echo "$WPAD_FILE"
else
  echo "Localização do wpad.dat"
  echo "Pressione ENTER para assumir o local padrao:"
  echo "/var/www/html/wpad.dat"
  read WPAD_FILE
  [ "$WPAD_FILE" = "" ] && WPAD_FILE="/var/www/html/wpad.dat"
fi

# client ip
echo "Digite o IP da estação de trabalho:"
echo "Pressione ENTER para assumir o IP padrao:"
echo "192.168.1.100"
read WPAD_CLIENT
[ "$WPAD_CLIENT" = "" ] && WPAD_CLIENT="192.168.1.100"

# host
echo "Digite o nome do host da estação de trabalho:"
echo "Pressione ENTER para nao usá-lo, pois atualmente nosso script não faz uso de nome de host."
read WPAD_HOST


# url
echo "URL para testar com o IP $WPAD_CLIENT:"
echo "Pressione ENTER para assumir o site padrao:"
echo "www.uol.com.br"
read WPAD_URL
[ "$WPAD_URL" = "" ] && WPAD_URL="www.uol.com.br"

CMD="/usr/bin/pactester -p $WPAD_FILE -c $WPAD_CLIENT"
if grep -q '^http' <<<$mask; then
  echo "http:// presente na URL"
else
  echo "Adicionando http:// na URL digitada."
   WPAD_URL="http://$WPAD_URL"
fi
CMD="$CMD -u $WPAD_URL"

if [ "$WPAD_HOST" != "" ] ; then
  CMD="$CMD -h $WPAD_HOST"
fi

# Sintaxe completa
echo "Executando:"
echo "$CMD"
echo "Resultado:"
RESULTADO=$($CMD)
PROXY=0
DIRETO=0
CAN_TEST_PROXY=0
[[ "$RESULTADO" =~ "$PROXY_IP" ]] && PROXY=1
[[ "$RESULTADO" =~ "DIRECT" ]] && DIRETO=1

echo "+--------------------------------------------------------------------------------+"
echo "|      Testando o acesso exterior a internet com as seguintes configuracoes      |"
echo "+--------------------------------------------------------------------------------+"
echo "Proxy: $PROXY_IP"
echo "Arquivo de autoconfiguração: $WPAD_FILE"
echo "Url para teste: $WPAD_URL"
echo "IP da estação de trabalho: $WPAD_CLIENT"
if [ "$WPAD_HOST" != "" ] ; then
  echo "Host da estação de trabalho(opcional): $WPAD_HOST"
fi
echo "+--------------------------------------------------------------------------------+"
if [ $PROXY -eq 0 ] && [ $DIRETO -eq 0 ] ; then
  echo "Erro na programação, por isso o acesso será somente via [gateway] ou [negado]."
fi

if [ $PROXY -eq 0 ] && [ $DIRETO -gt 0 ] ; then
  echo "Acesso apenas via [gateway]."
fi

if [ $PROXY -gt 0 ] && [ $DIRETO -eq 0 ] ; then
  echo "Acesso apenas via [proxy]."
  CAN_TEST_PROXY=1
fi

if [ $PROXY -gt 0 ] && [ $DIRETO -gt 0 ] ; then
  echo "Acesso sera via [proxy] e quando este falhar entao o acesso será via [gateway]."
  CAN_TEST_PROXY=1
fi

if [ $CAN_TEST_PROXY -gt 0 ] ; then
  #echo -ne "Debug:\n/home/administrador/scripts/squid_testa_site.sh -site:$WPAD_URL -user:$PROXY_TEST_USER -password:$PROXY_TEST_PASS \n"
  /home/administrador/scripts/squid_testa_site.sh -site:$WPAD_URL -user:$PROXY_TEST_USER -password:$PROXY_TEST_PASS 
fi
echo "+--------------------------------------------------------------------------------+"

# Fim do script
exit 0;


