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

echo "Digite a mascara:"
read mask
if grep -q '\.' <<<$mask; then
    convert_mask=$(oct2cidr $mask)
else
    convert_mask=$(cidr2oct $mask)
fi

echo "Conversão: $convert_mask"

exit 0;


