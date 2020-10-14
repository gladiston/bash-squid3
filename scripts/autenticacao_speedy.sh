#!/bin/bash

MAIL_TO="suporte@vidy.com.br"
LYNX="/usr/bin/lynx"
if ! [ -f "$LYNX" ] ; then
  echo "Navegador de Internet Lynx nao esta instalado."
  echo "Instale-o primeiro :"
  echo "sudo apt-get install lynx"
  exit 2;
fi

SPEEDYZONE="200.171.222.97"
USUARIO="vidy01@linkbr.com.br"
SENHA="19901206" # Senha de autenticacao

#
# USUARIO2=vidy02@linkbr.com.br
# SENHA2=19930128
#


SPEEDYZONE="http://$SPEEDYZONE/wsc/servlet/logon.do"
PAGINAL_INICIAL="http://registro.br"
URL_AUTENTICADORA="$SPEEDYZONE?opcion=internet&CPURL=$PAGINAL_INICIAL&username=$USUARIO&password=$SENHA"
ESPERAR="5s"
# exemplo de autenticacao :
# http://200.171.222.97/wsc/servlet/logon.do?opcion=internet&CPURL=http://registro.br&username=vidy1@speedycorp.com.br&password=1515
EXECUTAR="$LYNX -accept_all_cookies "

echo "Autenticacao Speedy"
echo "SpeedyZone : $SPEEDYZONE"
echo "usuario : $USUARIO"
echo "senha : $SENHA"
echo "Cmd : $EXECUTAR"   
echo "URL : $URL_AUTENTICADORA"


NUM_TESTES="0"


while [ "$CONTINUE" == "S" ] && [ "$NUM_TESTES" -lt "3" ] ; do
  NUM_TESTES=`expr $NUM_TESTES + 1`
  # tento pingar 3 vezes em registro.br
  ping -c 3 registro.br &>/dev/null
  # se falhar entao pratico a autenticacao
  if [ $? -ne 0 ] ; then
     # executa a autenticacao
     exec $EXECUTAR $URL_AUTENTICADORA&
     PID_LYNX=$!
     # espera 5 segundos e mata o processo
     echo "aguardando $ESPERAR para a autenticação do navegador $PID_LYNX ($EXECUTAR)..."
     sleep $ESPERAR
     echo "matando o navegador $PID_LYNX ($EXECUTAR)"
     kill -9 $PID_LYNX &>/dev/null
     # testando se autenticacao deu certo
     ping -c 3 registro.br &>/dev/null
     # se falhar entao volto ao loop e testo novamente
     if [ $? -ne 0 ] ; then
       echo "Nao pude autenticar ($NUM_TESTES)"
     else
       CONTINUE="N"
     fi # if [ $? -ne 0 ] ; then
  else
    echo "Ja se encontrava autenticado."
    CONTINUE="N"
  fi
done

# ultimo teste
ping -c 3 registro.br &>/dev/null
# se falhar entao pratico a autenticacao manualmente
if [ $? -ne 0 ] ; then
   echo "Infelizmente não foi possivel autenticar o speedy."
   echo "voce devera tentar a autenticacao manualmente com os dados :"
   echo "SpeedyZone : $SPEEDYZONE"
   echo "usuario : $USUARIO"
   echo "senha : $SENHA"
   echo "URL : $URL_AUTENTICADORA"  
   echo "Cmd : $EXECUTAR"   
   exit 2;
else
   echo "Autenticacao concluida com sucesso."
fi
  
exit 0;
