#!/bin/bash
# Script desenvolvido por :
# Gladiston Hamacker Santana <gladiston.santana@gmail.com>
# Data : 02/02/2006
# Uso : Reparar unidades de backup usbdisk ou pendrive
#
#       Dentro de cada disco usb tambem deverá existir o
#       arquivo vol_backup.txt, um arquivo texto contendo o
#       telefone, endereco e responsaveis que devem ser
#       contatados caso este disco usb seja roubado (ou outro
#       sinistro) e uma pessoa de boa indole resolva deveolve-lo.
#
# Dependencias :
#   sharutils zip fdisk sudoers
#
#########################################################

. /home/administrador/scripts/functions.sh

tape_user=$USER
tape_group=$USER
modo_automatico="1"
ponto_montagem="/media/usbdisk"
script_usbdisk="/home/administrador/scripts/usbdisk.sh"
if ! [ -d "$ponto_montagem" ] ; then
  mkdir -p "$ponto_montagem"
  chown $tape_user.$tape_group "$ponto_montagem"
  chmod 2666 "$ponto_montagem" 
fi

if ! [ -f "$script_usbdisk" ] ; then
  echo "Arquivo [$script_usbdisk] nao foi encontrado !"
  exit 2
fi

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
clear

do_montar_confere "$ponto_montagem"
if [ $do_montar_confere -gt 0 ] ; then
  echo "Esta pasta :"
  echo "$ponto_montagem"
  echo "Ja se encontra montada, certifique-se de que não haja um backup rodando neste momento, se houver tente nao prosseguir."
  do_confirmar "Prosseguir assim mesmo ? (sim ou nao)"
  if [[ $? -eq 0 ]]; then 
    echo "prosseguindo assim mesmo..." 
  else 
    echo "abandonando..." 
    exit 2;
  fi
fi

do_montar_dev "$ponto_device" "$ponto_montagem"

if [ "$RESULT_VALUE" != "OK"  ] ; then
   exit 2;
fi

echo "Montagem da unidade OK :  $ponto_device ($ponto_fs)"
echo "Periodo de backup a permanecer : $vencimento_em_dias dias."
echo ".   Espaço na unidade $ponto_device antes de iniciar a limpeza :" 
echo ".  `df -h $ponto_device|grep \"Uso\%\"`" 
echo ".  `df -h $ponto_device|grep \"$ponto_device\"`"
echo "Tente observar por outro computador a pasta :"
echo "$ponto_montagem"
echo "ou : ssh://administador@192.168.1.254:$ponto_montagem"
echo "Apos o usufruto da pasta, pressione [ENTER] para desmontá-la".
read espera

### desmontando a unidade USB
echo "Desmontando a unidade $ponto_device em $ponto_montagem."
if [ "`mount |grep $ponto_device|wc -l`"  -gt 0 ] ; then
  sudo umount $ponto_device
  if [ $? -ne 0 ] ; then
    echo "Erro ao tentar desmontar $ponto_device."
    echo "desmonte-a manualmente e repita a operacao."
    echo "operacao cancelada."
    exit 2;
  fi
fi

echo "processo finalizado."
