#!/bin/bash
# formato do access.log :
# http://www.linuxjunkies.org/adminstration%20Howto/webminguide/x4591.htm
# conversao de unixtime para data local
# date +%d-%m-%Y+%H:%M -d '1970-01-01 1223045940 sec'
# fonte de materia (conversao de perl para bash) :
# #!/usr/bin/perl -p
# exibe o arquivo de log do squid no formato .csv
# Squid2csv by Vincent Chartier <vcr@kyxar.fr> 
#s/^\d+\.\d+/localtime $&/e;s/^[A-Z]/"$&/g;s/[ ][ ]*/";"/g;s/\n/"$&/g
#
# linha do squid (exemplo)
# 1223046604.116(1) 21(2) 192.168.1.224(3) TCP_IMS_HIT/304(4) 402(5) GET(6) http://img.terra.com.br/uv/uv.js(7) rodrigo(8) NONE/-(9) application/javascript(10)
#
# Exemplo de uso :
# cat /var/log/squid3/access.log |squidlog.sh >/tmp/novo_squid_log.txt
#
if ! [ -f /usr/bin/bc ] ; then
   echo "programa bc nao esta instalado !"
   exit 2;
fi

while true; do
  read SQUID_LINHA || break
  PARAM_DATA_UNIXTIME=`echo $SQUID_LINHA|cut -d " " -f 1`
  # Compensacao de fuso horario para se ter exibido a data/hora local
  # o valor é em segundos, assim cada unidade de 3600 representa 1 hora
  # 3600  = 1h
  # 7200  = 2h
  # 10800 = 3h
  # 14400 = 4h
  PARAM_DATA_UNIXTIME=`echo "$PARAM_DATA_UNIXTIME-10800"|bc`
  PARAM_DATA=`date +%d-%m-%Y+%H:%M -d "1970-01-01 $PARAM_DATA_UNIXTIME sec"`
  PARAM_DURACAO=`echo $SQUID_LINHA|cut -d " " -f 2`
  DURACAO_SEGUNDOS="$[PARAM_DURACAO/100]"
  PARAM_DURACAO=`date +%H:%M:%S -d "1970-01-01 $DURACAO_SEGUNDOS sec"`
  PARAM_CLIENTE=`echo $SQUID_LINHA|cut -d " " -f 3`
  PARAM_RESULTADO=`echo $SQUID_LINHA|cut -d " " -f 4`
  PARAM_BYTES=`echo $SQUID_LINHA|cut -d " " -f 5`
  PARAM_METODO_REQUISITADO=`echo $SQUID_LINHA|cut -d " " -f 6`
  PARAM_URL=`echo $SQUID_LINHA|cut -d " " -f 7`
  PARAM_LOGIN=`echo $SQUID_LINHA|cut -d " " -f 8`
  PARAM_HIERARQUIA_CODIGO=`echo $SQUID_LINHA|cut -d " " -f 9`
  PARAM_MIME=`echo $SQUID_LINHA|cut -d " " -f 10`
  [ "$PARAM_LOGIN" = "-" ] && PARAM_LOGIN="anonimo"
  # Removendo visitas ao Google
  [[ "$PARAM_URL" =~ "google.com" ]] && PARAM_LOGIN="anonimo"
  # Removendo visitas ao GMail
  [[ "$PARAM_URL" =~ "gmail.com" ]] && PARAM_LOGIN="anonimo"
  [[ "$PARAM_URL" =~ "expolabor.com.br" ]] && PARAM_LOGIN="anonimo"
  [[ "$PARAM_URL" =~ "vidy.com.br" ]] && PARAM_LOGIN="anonimo"
  [[ "$PARAM_URL" =~ "192.168." ]] && PARAM_LOGIN="anonimo"
  if [ "$PARAM_LOGIN" != "anonimo" ] ; then
    echo "$PARAM_DATA $PARAM_DURACAO $PARAM_LOGIN $PARAM_CLIENTE $PARAM_URL $PARAM_RESULTADO $PARAM_METODO_REQUISITADO $PARAM_HIERARQUIA_CODIGO $PARAM_MIME"
  fi
done

