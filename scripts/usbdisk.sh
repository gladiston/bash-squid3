#!/bin/bash
# Nome do script : xendisk.sh
# Autor : Hamacker (sirhamacker [em] gmail.com)
# Licença : GPL-2
# Função : Script para procurar um disco valido para a realização
# de backup de maquinas virtuais.
#
# Abaixo alistamos todos os UUIDs de discos que serao aceitos para backup
# Dentro dos scripts de backup e limpeza, esta rotina retornará a UUID
# que foi encontrada e o script prosseguirá ou vazio e provavelmente
# o script interromperá o processo dizendo que o backup ou a limpeza
# nao poderá ser realizada porque nenhum disco valido de backup foi
# encontrado no sistema.
#
# Programa 'blkid' é usado para detectar os discos pludados por UUID
# ele é mais confiavel do que usar o diretorio /dev/disk/disk-by-uuid
BLKID="/sbin/blkid"
# discos de backups utilizados aqui na VIDY
unset groupdisk
groupdisk[0]="c7cb4979-328f-4f25-a3c1-c784556aa3fc" # superdog-01
groupdisk[1]="7e8364a2-1bf9-45ed-89e9-b4860bed7cec" # superdog-02
# Procura se algum dos discos alistados para backup estao presentes no sistema
backup_dev_disk=""
tmpfile=$(mktemp "/tmp/usbdisk.XXXXXXXXXX")
$BLKID |grep "UUID">$tmpfile
while read line ; do
  disk_device=""
  disk_label=""
  disk_uuid=""
  disk_type="" 
  disk_device=$(eval echo $line|cut -d ":" -f1) 
  [[ "$line" =~ "LABEL=" ]] && disk_label=$(eval echo ${line#*LABEL=}|cut -d " " -f1|tr -d "\"")
  [[ "$line" =~ "UUID=" ]] && disk_uuid=$(eval echo ${line#*UUID=}|cut -d " " -f1|tr -d "\"")
  [[ "$line" =~ "TYPE=" ]] && disk_type=$(eval echo ${line#*TYPE=}|cut -d " " -f1|tr -d "\"")    
  # debug :
  #echo "uuid=$disk_uuid,label=$disk_label,type=$disk_type,device=$disk_device"
  for uuid in "${groupdisk[@]}" ; do
    if [ "$uuid" = "$disk_uuid" ] ; then  
      backup_dev_disk="$disk_device"
      break
    fi
  done
done <$tmpfile
[ -f "$tmpfile" ] && rm -f "$tmpfile"
echo "$backup_dev_disk"

