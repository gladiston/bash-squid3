#!/bin/bash
# Funcao: gerar um arquivo wpad.dat mais ou menos assim:
#function FindProxyForURL(url, host) {
#  /* LISTA DOS ENDERECOS POR URL QUE NAO PODEM USAR PROXY-CACHE */
#
#  if (isPlainHostName(host))            { return "DIRECT"; }
#  if (dnsDomainIs(host, "vidy.local"))  { return "DIRECT"; }
#  if (shExpMatch(host, "10.*"))         { return "DIRECT"; }
#  if (shExpMatch(host, "192.16.*"))     { return "DIRECT"; }
#  if (shExpMatch(host, "192.168.*"))    { return "DIRECT"; }
#
#  // Capturando o IP da estacao
#  ip_source=myIpAddress();
#
#  // Servidores internos
#  if (ip_source=="192.168.1.2")         { return "DIRECT"; }
#  if (ip_source=="192.168.1.3")         { return "DIRECT"; }
#  if (ip_source=="192.168.1.6")         { return "DIRECT"; }
#  if (ip_source=="192.168.1.7")         { return "DIRECT"; }
#  if (ip_source=="192.168.1.10")        { return "DIRECT"; }
#  if (ip_source=="192.168.1.13")        { return "DIRECT"; }
#  if (ip_source=="192.168.1.14")        { return "DIRECT"; }
#  if (ip_source=="192.168.1.252")       { return "DIRECT"; }
#  if (ip_source=="192.168.1.253")       { return "DIRECT"; }
#
#  // Destinos IP/Mask
#  //if (isInNet(host, "8.8.0.0", "255.255.0.0")) { return "DIRECT"; }
#  if (isInNet(host, "8.8.0.0", "16")) { return "DIRECT"; }
#
#  // Estacoes com proxy transparente
#
#  /* RESTANTE USA O PROXY DE NAVEGACAO, SE ESTE FALHAR ENTÃO DIRETO */
#  return "PROXY 192.168.1.252:3128; DIRECT" ;
#  return "DIRECT";
#}

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

#
# Funcoes internas
#
function wpad() {
 echo "$1"
 ! [ -f "$FILE_WPAD" ] && touch "$FILE_WPAD"

 echo "$1" >>"$FILE_WPAD"
}


#
# Inicio do programa
#
FILE_WPAD=""
FILE_TMP="/tmp/wpad.dat.1"
FILE_IP_DIRECT="$SQUIDACL/sites_diretos_ip.txt"
FILE_DIRECT="$SQUIDACL/sites_diretos.txt"
FILE_IP_TRANSP="$SQUIDACL/ip_liberado.txt"
NO_PROXY=0

# Conferindo parametros na linha de comando
# A especificacao de onde gerar o wpad é obrigatorio
if [ "$1" != "" ] ; then
  [[ "$1" =~ "no-proxy" ]] && NO_PROXY=1
fi

if [ "$2" != "" ] ; then
  [[ "$2" =~ "no-proxy" ]] && NO_PROXY=1
fi

if [ "$1" != "" ] ; then
  [ -f "$1" ] && FILE_WPAD="$1"
  [ -d "`dirname "$1"`" ] && FILE_WPAD="$1"
fi
if [ "$FILE_WPAD" == "" ] ; then
  [ -f "$2" ] && FILE_WPAD="$2"
  [ -d "`dirname "$2"`" ] && FILE_WPAD="$2"
fi

if [ "$FILE_WPAD" == "" ] ; then
  echo ""
  echo "Erro de sintaxe:"
  echo "wpad-create /caminho/para/criar/wpad.dat [no-proxy]"
  echo "* no-proxy: cria um wpad para usar somente acesso direto. Isso serve para ocasioes onde o proxy foi desalibitado ou esta em manutencao."
  exit 2;
fi

# Pegando o ip do proxy
PROXY_IP=$(ifconfig $PROXY_IFACE|grep 'inet end.:'|cut -d':' -f2|xargs|cut -d' ' -f1)

# Pegando o dominio
DOMAIN=$(cat /etc/resolv.conf|grep domain|cut -d' ' -f2|xargs)

# Elimina o wpad antigo se existir
[ -f "$FILE_WPAD" ] && mv -f "$FILE_WPAD" "$FILE_WPAD.old"

touch $FILE_TMP

# criando cabecalho
wpad "function FindProxyForURL(url, host) {"
if [ $NO_PROXY -gt 0 ] ; then
  wpad "  /* FOI HABILITADA A OPCAO DE NAO USAR PROXY */"
  wpad "  /* ENTAO TODOS IRAO ACESSAR DIRETAMENTE VIA GATEWAY */"
  wpad "  return \"DIRECT\";"
  wpad "}"
  exit 0;
fi

# WPAD para uso com proxy
wpad "  /* LISTA DOS ENDERECOS POR URL QUE NAO PODEM USAR PROXY-CACHE */"
wpad ""
wpad "  if (isPlainHostName(host))            { return \"DIRECT\"; }"
wpad "  if (dnsDomainIs(host, \"$DOMAIN\"))  { return \"DIRECT\"; }"
wpad "  if (shExpMatch(host, \"10.*\"))         { return \"DIRECT\"; }"
wpad "  if (shExpMatch(host, \"172.16.*\"))     { return \"DIRECT\"; }"
wpad "  if (shExpMatch(host, \"192.168.*\"))    { return \"DIRECT\"; }"
wpad ""
wpad "  /* Capturando o IP da estacao */"
wpad "  ip_source=myIpAddress();"
wpad "  /* Nossos servidores internos */"
wpad "  if (ip_source==\"$PROXY_IP\") { return \"DIRECT\"; }"
cat /etc/hosts|cut -d' ' -f1|grep -v 127.|grep -v "::"|grep -v "$PROXY_IP" >$FILE_TMP
while read LINHA ; do
  PARAM=`semremarks "$LINHA"`
  PARAM=`expr "$PARAM" |xargs`
  IP=`expr "$PARAM" |cut -d "/" -f1`
  if valid_ip $IP; then
    wpad "  if (ip_source==\"$IP\") { return \"DIRECT\"; }"
  fi
done < "$FILE_TMP"

wpad "  // Estacoes com IP transparente"
while read LINHA ; do
  PARAM=`semremarks "$LINHA"`
  PARAM=`expr "$PARAM" |xargs`
  IP=`expr "$PARAM" |cut -d "/" -f1`
  if valid_ip $IP; then
    wpad "  if (ip_source==\"$IP\") { return \"DIRECT\"; }"
  fi
done < "$FILE_IP_TRANSP"

wpad "  // Destinos diretos por IP/Mask"
wpad "  if (isInNet(host, \"8.8.0.0\", \"255.255.0.0\")) { return \"DIRECT\"; }"
while read LINHA ; do
  PARAM=`semremarks "$LINHA"`
  PARAM=`expr "$PARAM" |xargs`
  IP=`expr "$PARAM" |cut -d "/" -f1`
  MASK=`expr "$PARAM" |cut -d "/" -f2`
  if [ "$IP" == "" ] || [ -z "$IP" ] ; then
     IP="$PARAM"
     MASK="32"
  fi
  [ "$MASK" == "8" ] && MASK="255.0.0.0"
  [ "$MASK" == "16" ] && MASK="255.255.0.0"
  [ "$MASK" == "24" ] && MASK="255.255.255.0"
  [ "$MASK" == "32" ] && MASK="255.255.255.255"

  if valid_ip $IP; then 
    if valid_ip $MASK; then
      wpad "  if (isInNet(host, \"$IP\", \"$MASK\")) { return \"DIRECT\"; }"
    else
      OCT_MASK=$(cidr2oct $MASK)
      if valid_ip $OCT_MASK ; then
        wpad "  if (isInNet(host, \"$IP\", \"$OCT_MASK\")) { return \"DIRECT\"; }"
      else
        wpad "  /* if (isInNet(host, \"$IP\", \"$MASK\")) { return \"DIRECT\"; } -- mascara invalida */"
      fi
    fi
  fi
done < "$FILE_IP_DIRECT"

wpad "  // Destinos diretos por Regex URL"
wpad "  // if (shExpMatch(url, \"*t*p:*sh*u*.t*te*eg*st*r\"))  { return \"DIRECT\"; }"
while read LINHA ; do
  PARAM=`semremarks "$LINHA"`
  PARAM=`expr "$PARAM" |xargs`
  URL="$PARAM"
  [ "$URL" == "" ] || [ -z "$URL" ] && URL=""
  if [ "$URL" != "" ] ; then
    # Possui wildcards ?
    HAS_WILDCARDS=0
    [[ $URL =~ "*" ]] && HAS_WILDCARDS=1
    [[ $URL =~ "\[" ]] && HAS_WILDCARDS=1
    # Se nao possui wildcards entao acrescenta *path.to.url*
    [ $HAS_WILDCARDS -eq 0 ] &&  URL="*$URL*"
    wpad "  if (shExpMatch(url, \"$URL\"))  { return \"DIRECT\"; }"
  fi
done < "$FILE_DIRECT"

# rodape do script
wpad "  /* RESTANTE USA O PROXY DE NAVEGACAO, SE ESTE FALHAR ENTÃO DIRETO */"
wpad "  return \"PROXY $PROXY_IP:$PROXY_PORT; DIRECT\" ;"
wpad "}"
chown www-data.www-data "$FILE_WPAD"

exit 0;


