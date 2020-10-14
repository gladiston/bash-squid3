#!/bin/bash
# Nome: testar_velocidade_internet.sh
# Funcao: testar a velocidade de internet
# Dependencias: speedtest-cli
# Parametros:
# -min:[velocidade em gb], Para enviar emails apenas quando a velocidade de
#    internet for abaixo de 10Gbit/s então use -min:10
#    Se este parametro nao for informado entao usara as variaveis
#    VELOCIDADE_MIN_VIRTUA e VELOCIDADE_MIN_IPWAVE para estabelecer a 
#    velocidade minima autoamticamente.

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

#
# Inicio
#
VELOCIDADE_MIN=0
VELOCIDADE_MIN_VIRTUA=50
VELOCIDADE_MIN_IPWAVE=1
for CURRENT_PARAM in "$@" ; do
  CURRENT_PARAM="${CURRENT_PARAM##*( )}"                                          # Trim
  if [[ "$CURRENT_PARAM" =~ "^-min" ]] ; then 
    VELOCIDADE_MIN=$(eval echo "$CURRENT_PARAM"|cut -d':' -f2)
  fi  
done
# Se o campo numero for invalido então...
if ! [[ $VELOCIDADE_MIN =~ '^[0-9]+$' ]] ; then
   echo "Não foi possivel identificar o parametro de velocidade minima: $VELOCIDADE_MIN" >&2
   echo "Variavel [VELOCIDADE_MIN] não é um numero." >&2
   exit 2
fi  


# Pegando o ip do proxy
DATA_ATUAL=$(date +%d-%m-%Y+%Hh%M)
MAILTO="suporte@vidy.com.br"
IP_PROXY=$(ifconfig $PROXY_IFACE|grep 'inet end.:'|cut -d':' -f2|xargs|cut -d' ' -f1)
#IP_EXTERNAL=$(lwp-request -o text checkip.dyndns.org | awk '{ print $NF }')
IP_EXTERNAL=$(dig +short  myip.opendns.com @resolver1.opendns.com)
IP_EXTERNAL_NAME=$(dig +short -x $IP_EXTERNAL|cut -d'.' -f2-)
SERVER_TEST=" "
if [[ "$IP_EXTERNAL_NAME" =~ "virtua" ]] ; then
  SERVER_TEST=" --server 4978"  # 4978) NET S/A (Sao Paulo, Brazil) [24.02 km]
  [ $ VELOCIDADE_MIN -eq 0 ] && VELOCIDADE_MIN=$VELOCIDADE_MIN_VIRTUA
fi
if [[ "$IP_EXTERNAL_NAME" =~ "ipwave" ]] ; then
  SERVER_TEST=" --server 3971"  # 3971) America Net (Barueri, Brazil) [14.93 km]
  [ $ VELOCIDADE_MIN -eq 0 ] && VELOCIDADE_MIN=$VELOCIDADE_MIN_IPWAVE
fi
FILE_TEMP="/tmp/testar-velocidade-$IP_PROXY-$$.log"
DO_PAUSE=0
DO_STOP_PROXY=0
if [ "$1" == "-p" ] || [ "$1" == "-p" ] ; then
  DO_PAUSE=1
fi

echo "+--------------------------------------------------------------------+"
echo "| DESCARREGANDO A ULTIMA VERSÃO DO SPEEDTEST                         |"
echo "+--------------------------------------------------------------------+"
wget -O $SCRIPTS/speedtest-cli https://raw.github.com/sivel/speedtest-cli/master/speedtest_cli.py
chmod a+x $SCRIPTS/speedtest-cli
chown administrador.administrador $SCRIPTS/speedtest-cli

echo "+--------------------------------------------------------------------+" 2>&1 | tee "$FILE_TEMP"
echo "| TESTE DE VELOCIDADE DE INTERNET                                    |" 2>&1 | tee -a "$FILE_TEMP"
echo "+--------------------------------------------------------------------+" 2>&1 | tee -a "$FILE_TEMP"
echo "O proxy está usando o IP: $IP_PROXY" 2>&1 | tee -a "$FILE_TEMP"
echo "Sua conexao de internet usa o IP: $IP_EXTERNAL ($IP_EXTERNAL_NAME)" 2>&1 | tee -a "$FILE_TEMP"

if [ $DO_PAUSE -gt 0 ] ; then
  #echo "Arquivo temporário: $FILE_TEMP"
  echo "Se estiver usando um gateway que também é um load balance então vá"
  echo "até ele e ajuste-o para que o IP acima não tenha multiplos provedores"
  echo "de internet, mas somente o provedor que deseja testar a velocidade."
  echo "Gostaria de parar o compartilhamento de internet para que o teste"
  echo -n "possa ser mais efetivo?"
  read resposta
  resposta=${resposta:0:1}
  [ $resposta == "S" ] || [ $resposta == "s" ] && DO_STOP_PROXY=1
  if [ $DO_STOP_PROXY -gt 0 ] ; then
    echo "Atenção: O compartilhamento de internet será paralizado até que"
    echo "teste de velocidade esteja concluído."
  fi
fi
if [ $DO_STOP_PROXY -gt 0 ] ; then
  echo "Paralização temporaria do proxy durante o teste: Sim" 2>&1 | tee -a "$FILE_TEMP"
else
  echo "Paralização temporaria do proxy durante o teste: Não" 2>&1 | tee -a "$FILE_TEMP"
fi
if [ $DO_PAUSE -gt 0 ] ; then
  echo "Pressione [ENTER] pasra prosseguir com o teste ou Ctrl+C para cancelar."
  read espera
fi
echo "Iniciando o teste de velocidade, aguarde..." 2>&1 | tee -a "$FILE_TEMP"
if [ $DO_STOP_PROXY -gt 0 ] ; then 
  service squid3 stop
fi
$SCRIPTS/speedtest-cli $SERVER_TEST 2>&1 | tee -a "$FILE_TEMP"
if [ $DO_STOP_PROXY -gt 0 ] ; then 
  service squid3 start
fi
DOWNLOAD=$(cat "$FILE_TEMP"|grep "Download"|cut -d':' -f2|cut -d'/' -f1)
DOWNLOAD="${DOWNLOAD##*( )}"                                          # Trim
UPLOAD=$(cat "$FILE_TEMP"|grep "Upload"|cut -d':' -f2|cut -d'/' -f1)
UPLOAD="${UPLOAD##*( )}"                                              # Trim
if [ "$DOWNLOAD" == "" ] && [ "$UPLOAD" == "" ] ; then
  SUBJECT="[URGENTE] Problemas com acesso à internet em $DATA_ATUAL"
  echo "--> Não conseguir efetuar o teste pode ser indicativo de problemas no acesso de internet."  2>&1 | tee -a "$FILE_TEMP" 
  echo "--> Vou deixar de testar a velocidade da internet e vou executar testes de acesso à internet."  2>&1 | tee -a "$FILE_TEMP"   
else
  SUBJECT="Velocidade da internet($DOWNLOAD / $UPLOAD) em $DATA_ATUAL"
fi
echo "--> Iniciando testes de acesso a internet..."  2>&1 | tee -a "$FILE_TEMP" 
$SCRIPTS/testar_internet.sh "$DOWNLOAD" "$UPLOAD" 2>&1 | tee -a "$FILE_TEMP" 
echo "+--------------------------------------------------------------------+" 2>&1 | tee -a "$FILE_TEMP"
echo "| FIM DO TESTE DE VELOCIDADE DE INTERNET                             |" 2>&1 | tee -a "$FILE_TEMP"
echo "+--------------------------------------------------------------------+" 2>&1 | tee -a "$FILE_TEMP"
if [ $DO_PAUSE -gt 0 ] ; then
  echo "Pressione [ENTER] pasra prosseguir."
  read espera
fi

# Se a velocidade calculado for menor que a minima então haverá envio de email
if [ $DOWNLOAD -le $VELOCIDADE_MIN ] ; then
  $SCRIPTS/enviar_email_admin.sh "$MAILTO" "$SUBJECT" "$FILE_TEMP"
fi
[ -f "$FILE_TEMP" ] && rm -f "$FILE_TEMP"

# Fim do script
exit 0;


