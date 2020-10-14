#!/bin/bash
# Script desenvolvido por :
# Gladiston Hamacker Santana <gladiston.santana@gmail.com>
# Data : 02/02/2006
# Uso : Limpar as unidades de backup usbdisk ou pendrive
#       removendo arquivos mais antigos que 7 dias. 
#
# Dependencias :
#   sharutils zip fdisk sudoers
#

. /home/administrador/scripts/functions.sh

#########################################################
# acrescentando arquivo header proprio para discos USBs #
#########################################################
modo_automatico="1"
ponto_montagem="/media/usbdisk"
script_usbdisk="/home/administrador/scripts/usbdisk.sh"
if ! [ -f "$script_usbdisk" ] ; then
  echo "Arquivo [$script_usbdisk] nao foi encontrado !"
  exit 2
fi

vencimento_em_dias="+7"
###########################################
# Detectando nossos discos USBs de backup #
###########################################
ponto_device=$($script_usbdisk)
if [ $? -ne 0 ] ; then
  log "Nao foi possivel importar o arquivo [$script_usbdisk] !"
  exit 2;
fi 

### se nao foi encontrado nenhum disco entao abandona o script.
if [ "$ponto_device" = "" ] ; then
  echo "Nenhuma unidade de backup foi detectada!"
  exit 2;
else
  echo "UDEV midia de backup detectado em $ponto_device"
fi

#########################################################
# prosseguindo com o meu programa                       #
#########################################################
echo "Limpando a unidade :"
echo -ne "\t$ponto_device\n"
echo "Que será montada na pasta :"
echo -ne "\t$ponto_montagem\n"

do_montar_dev "$ponto_device" "$ponto_montagem"

if [ "$RESULT_VALUE" != "OK"  ] ; then
   exit 2;
fi

echo "Montagem da unidade OK :  $ponto_device ($ponto_fs)"
echo "Periodo de backup a permanecer : $vencimento_em_dias dias."
echo ".   Espaço na unidade $ponto_device antes de iniciar a limpeza :" 
echo ".  `df -h $ponto_device|grep \"Uso\%\"`" 
echo ".  `df -h $ponto_device|grep \"$ponto_device\"`"

#
# Elimina os arquivos com mais de $vencimento_em_dias dias;
#
echo "Eliminando de $ponto_montagem arquivos mais antigos que $vencimento_em_dias dias."
for d in $ponto_montagem; do
  find $d  -type f -mtime "$vencimento_em_dias" -exec rm --force "{}" \;
  #
  # Removemos os diretorios vazios
  #
  find $d/* -type d -print0 | \
       sort --zero-terminated --reverse | \
       xargs --no-run-if-empty --null --max-args 1 rmdir 2> /dev/null
done
echo "processo de limpeza da unidade finalizado."
echo ".   Espaço na unidade $ponto_device apos a limpeza :" 
echo ".  `df -h $ponto_device|grep \"Uso\%\"`" 
echo ".  `df -h $ponto_device|grep \"$ponto_device\"`"
echo "Desmontando a unidade em $ponto_montagem."
  #
  # copiando arquivos que por ventura podem ter sido apagados
  #
  sudo cp /home/administrador/backup/discos_diarios/seg_qua_sex.txt \
          /home/administrador/backup/discos_diarios/ter_qui.txt \
          /home/administrador/backup/discos_diarios/vol_1.txt \
          /home/administrador/backup/discos_diarios/vol_2.txt \
          /home/administrador/backup/discos_diarios/vol_3.txt \
          /home/administrador/backup/discos_diarios/vol_4.txt \
          /home/administrador/backup/discos_diarios/vol_5.txt \
          /home/administrador/backup/discos_diarios/vol_6.txt \
          /home/administrador/backup/discos_diarios/vol_7.txt \
          $ponto_montagem
	    
### desmontando a unidade USB
echo "Desmontando a unidade $ponto_device em $ponto_montagem."
do_desmontar "$ponto_montagem"
if [ "$RESULT_VALUE" != "OK"  ] ; then
   echo "Erro ao tentar desmontar $ponto_device."
   echo "desmonte-a manualmente."
fi

echo "processo finalizado."

