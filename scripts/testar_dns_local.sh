#!/bin/bash

# Variaveis importantes para este script
. /home/administrador/menu/mainmenu.var

# Funcoes importantes para este script
. /home/administrador/menu/mainmenu.functions

# Funcoes importantes para este script
. /home/administrador/fw-scripts/firewall.functions



#
# Inicio do script
#
dns1=$1
dns2=$2
if [ "$dns1" == "" ] && [ "$dns2" == "" ] ; then
  lista_dns=`get_dns_bind9`
  dns1=`echo $lista_dns|cut -d' ' -f1`
  dns2=`echo $lista_dns|cut -d' ' -f2`
  #echo "DNSs do bind9: $lista_dns"
  #echo "dns #1: $dns1"  
  #echo "dns #2: $dns2"  
  #read espera 
fi

[ "$dns1" == "" ] && dns1="localhost"
[ "$dns2" == "" ] && dns2="localhost"
dig_opt=" +noall +stats"
qtde=0
tempfile="/tmp/sites-acessados-ultimos.txt"
echo "=== Testando Servidor de DNS Local (bind9) ==="
echo "O sistema testará os sites mais utilizados com os DNSs [$dns1] e [$dns2]."
echo "Depois testará os ultimos 500 acessos no squid numa lista sem repetição."
echo "Observe o tempo de execução, se o tempo for alto então configure"
echo "os serviços locais (ex. squid) para utilizar outros DNSs e"
echo "contate o administrador da rede para resolver o problema com os DNSs locais."
press_enter_to_continue

echo " "
echo "registro.br">$tempfile
echo "www.vidy.com.br">>$tempfile
echo "mail.google.com">>$tempfile
echo "www.google.com.br">>$tempfile
echo "www.bradesco.com.br">>$tempfile
echo "receita.fazenda.gov.br">>$tempfile
echo "caixa.gov.br">>$tempfile
lista_sites=`tail /var/log/squid3/access.log -n500|grep GET|sed -n -e 's/^.*GET //p' |cut -d' ' -f1|uniq`
for linha in $lista_sites ; do
  site=`convert_url2site $linha`
  existe=`cat $tempfile|grep "$site"|wc -l`
  if [ $existe -le 0 ] ; then
    echo $site>>$tempfile
	qtde=$((qtde+1))
  fi
done
START=$(date +%s.%N)
while read site ; do
  echo "Testando DNS[$dns1]: $site `dig @$dns1 $site $dig_opt|grep "Query time:"`"
done <$tempfile
END=$(date +%s.%N)
elap_time1=$(echo "$END - $START" | bc)
echo "Foram testados $qtde sites no DNS [$dns1] e o tempo foi de $elap_time1."
if [ "$dns1" != "$dns2" ] ; then
  START=$(date +%s.%N)
  while read site ; do
    echo "Testando DNS[$dns2]: $site `dig @$dns2 $site $dig_opt|grep "Query time:"`"
  done <$tempfile
  END=$(date +%s.%N)
  elap_time2=$(echo "$END - $START" | bc)
  echo "Foram testados $qtde sites no DNS [$dns1] e o tempo foi de $elap_time1."
  echo "Foram testados $qtde sites no DNS [$dns2] e o tempo foi de $elap_time2."
fi

exit 0;
