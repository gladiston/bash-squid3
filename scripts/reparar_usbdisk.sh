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

if [ "$modo_automatico" = "1" ] ; then
  SEMANA="3"
else
  echo "Digite [1] se a unidade que foi inserida for seg/qua/sex"
  echo "ou digite [2] se a unidade for ter/qui"
  echo "ou digite [3] para todos os dias da semana"
  echo -n "=>"
  read SEMANA
  if [ "$SEMANA" != "1" ] && [ "$SEMANA" != "2" ] && [ "$SEMANA" != "3" ] ; then
    echo "Discos de semanada (1-3) informado incorretamente."
    echo "operação abortada !";
    exit 1;
  fi;
fi
echo "Iniciando reparacao automatica do disco $ponto_device"
sudo fsck -vfy $ponto_device
echo "testando montagem da unidade em $ponto_montagem."
sudo mount -t auto $ponto_device $ponto_montagem -o async,rw,users
if [ $? -ne 0 ] ; then
    echo "A montagem da unidade de backup falhou !"
    echo "Ex: sudo mount -t $ponto_fs $ponto_device $ponto_montagem"
    echo "Certifique-se que :"
    echo "- tenha ligado a unidade numa porta USB deste servidor;"
    echo "- o dispositivo USB esteja ligado com o led de funcionamento piscando."
    echo "Desligue o aparelho, aguarde alguns instantes e ligue-o novamente"
    echo "e repita a operacao, se insistir o problema contate"
    echo "imediatamente o supervidor."
    exit 1;
fi
echo "Montagem da unidade OK"
echo "Preparando a unidade para realizacao de backup..."

if [ "$SEMANA" = "1" ] ; then
    sudo cp /home/administrador/backup/discos_diarios/seg_qua_sex.txt \
            /home/administrador/backup/discos_diarios/vol_1.txt \
            /home/administrador/backup/discos_diarios/vol_3.txt \
            /home/administrador/backup/discos_diarios/vol_5.txt \
            /home/administrador/backup/discos_diarios/vol_6.txt \
            /home/administrador/backup/discos_diarios/vol_7.txt \
            $ponto_montagem 
fi

if [ "$SEMANA" = "2" ] ; then
    sudo cp /home/administrador/backup/discos_diarios/seg_qua_sex.txt \
            /home/administrador/backup/discos_diarios/vol_2.txt \
            /home/administrador/backup/discos_diarios/vol_4.txt \
            /home/administrador/backup/discos_diarios/vol_6.txt \
            /home/administrador/backup/discos_diarios/vol_7.txt \
            $ponto_montagem 
fi

if [ "$SEMANA" = "3" ] ; then
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
fi
echo "Disco $ponto_device foi reparado com sucesso."

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
