#!/bin/bash
if ! [ -f /home/administrador/scripts/functions.sh ] ; then
  echo "Arq. nao existe : /home/administrador/scripts/functions.sh "
  exit 2;
fi
. /home/administrador/scripts/functions.sh
echo "Desmontando $1"
do_desmontar $1

