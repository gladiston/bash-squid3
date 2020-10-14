#!/bin/bash
# Script desenvolvido por : 
# Gladiston Santana <gladiston.santana@gmail.com>
# Data : 02/02/2006
# Uso : Faz backup de arquivos/pastas selecionadas
#       para dois discos usb, um disco usb para dias impares
#       (seq,qua,sex) e outro disco para dias pares(ter,qui)
#       dentro de cada disco usb possui os arquivos :
#       vol_1.txt (seg), vol_2.txt (ter), vol_3.txt (qua),
#       vol_4.txt (qui), vol_5.txt (sex), vol_6.txt (sab),
#       vol_7.txt (dom)
#       Se o dia que se realiza o backup (1(seg) ate 7(dom)) nao
#       for correspondente ao disco usb que foi plugado
#       entao o backup sera rejeitado.
#  
#       Dentro de cada disco usb tambem devera existir o
#       arquivo vol_vidy.txt, um arquivo texto contendo o
#       telefone, endereco e responsaveis que devem ser
#       contatados caso este disco usb seja roubado (ou outro
#       sinistro) e uma pessoa de boa indole resolva devolve-lo.
#
#       Tambem notifica por email, o sucesso ou falha inclusive
#       atachando o log por anexo.
#########################################################
# funcoes para envio de email contendo falha ou sucesso #
#########################################################
. /home/administrador/scripts/functions.sh

function do_test_disk {
  # Esta funcao testa se a unidade de backup esta OK
  DO_DISK_TEST_RESULT_VALUE="OK" 
  do_montar_dev "$ponto_device" "$mountdir"
  if [ "$RESULT_VALUE" != "OK" ] ; then
    DO_DISK_TEST_RESULT_VALUE="FALHOU"
    log "Não foi possivel montar : $ponto_device" 
    return;
  fi

  # ceritificando de que a unidade montada corresponde corretamente ao
  # dia da semana que estamos
  if ! [ -f "$mountdir/vol_$dia_semana.txt" ] ; then
    log "A unidade de backup foi montada com sucesso, no entanto, esta unidade nao corresponde a unidade desejada !"
    log "Certifique-se que :"
    log "- tenha colocado a unidade correta na unidade."
    log "  hoje e' `date +%a` ou dia da semana numero `date +%u`."
    log "  entao a unidade que deveria estar ligado deve ter "
    log "  na sua etiqueta esta data ou numero."
    log "- ou talvez, por engano alguem deve ter apagado o arquivo : "
    log "  $mountdir/vol_$dia_semana.txt"
    log "  que havia nessa unidade de backup."
    # desmontando a unidade de destino
    do_desmontar "$mountdir"
    DO_DISK_TEST_RESULT_VALUE="FALHOU" 
    return;
  fi

  # atualizando data dos arquivos de indices na unidade usb
  # para que sempre reflitam a data do ultima tentativa de backup
  sudo touch $mountdir/vol_1.txt
  sudo touch $mountdir/vol_3.txt
  sudo touch $mountdir/vol_5.txt
  sudo touch $mountdir/vol_7.txt
  sudo touch $mountdir/vol_vidy.txt
  sudo touch $mountdir/seg_qua_sex.txt
  sudo chmod 666 $mountdir/vol_1.txt
  sudo chmod 666 $mountdir/vol_3.txt
  sudo chmod 666 $mountdir/vol_5.txt
  sudo chmod 666 $mountdir/vol_7.txt
  sudo chmod 666 $mountdir/vol_vidy.txt
  sudo chmod 666 $mountdir/seg_qua_sex.txt

  log "Iniciando backup as $data_ini"

  # criando algumas pastas e arquivos
  if ! [ -d "$backup_folder" ] ; then
    echo "criando pasta $backup_folder"
    sudo mkdir -p "$backup_folder"
    if [ $? -ne 0 ] ; then
      log "[backup-falhou] : erro ao criar pasta $backup_folder"
      # desmontando a unidade de destino
      do_desmontar "$mountdir"
      DO_DISK_TEST_RESULT_VALUE="FALHOU" 
      return;
    else
      sudo chown $tape_operator.$tape_group "$backup_folder"
      sudo chmod 2777 "$backup_folder"
      echo -n "pasta criada."  
    fi
  fi

  if ! [ -d "$backup_log_folder" ] ; then
    sudo mkdir -p "$backup_log_folder"
    sudo chmod 2777 "$backup_folder"
    sudo chown $tape_operator.$tape_group $backup_log_folder
  fi

  # preparando arquivo de log
  sudo touch $file_error_log
  sudo chown $tape_operator.$tape_group $file_error_log

  # desmontando a unidade de destino
  do_desmontar "$mountdir"

}

function do_sendmail2() {
  BIN="/usr/bin/mutt"
  if ! [ -f "$BIN" ] ; then
    echo "Nao posso notificar por email por falta do arquivo : $BIN"
    return;  
  fi  
  if [ "$data_fim" == "" ] ; then 
    data_fim="interrompido"
  else
    data_fim=`date`
  fi
  echo "enviando email notificando sucesso na realizacao do backup"
  echo "incluindo $file_error_log"
  sudo touch "$sendmail_message_file"
  sudo chmod 666 "$sendmail_message_file"
  MAILTO="registros@vidy.com.br"
  COPYTO="suporte@vidy.com.br"
  SUBJECT="[backup-superdog] $backup_title"
  echo "Segue em anexo o log do backup" >"$sendmail_message_file"
  echo "=> $backup_title" >>"$sendmail_message_file"
  echo "que foi iniciado as $data_ini" >>"$sendmail_message_file"
  echo "e terminou (incluindo verificacao) as $data_fim" >>"$sendmail_message_file"
  # compactando o arquivo de log
  #sudo zip -j "$sendmail_attach_file" $file_error_log
  #sudo chmod 666 "$sendmail_attach_file"
  # enviando mensagem
  cat "$file_error_log" >>"$sendmail_message_file"
  if [ "$COPYTO" = "" ] ; then
     $BIN -s "$SUBJECT" "$MAILTO" < "$sendmail_message_file"
  else
     $BIN -s "$SUBJECT" -c "$COPYTO" "$MAILTO" < "$sendmail_message_file"
  fi
  #if [ "$COPYTO" = "" ] ; then
  #   mutt -s "$SUBJECT" -a $file_error_log "$MAILTO" < "$sendmail_message_file"
  #else
  #   mutt -s "$SUBJECT" -a $file_error_log -c "$COPYTO" "$MAILTO" < "$sendmail_message_file"
  #fi
}

function do_backup_esteservidor() {
  log "*****************************************************************"
  log "* ESTE SERVIDOR : $HOSTNAME     *"
  log "*****************************************************************"
  DO_BACKUP_STATUS_ESTESERVIDOR="S"
  # montando a unidade de destino, normalmente o usbdisk
  do_montar_dev "$ponto_device" "$mountdir"
  if [ "$RESULT_VALUE" != "OK" ] ; then
    do_desmontar "$mountdir"
    return;
  fi 

  # lista de pastas a serem backupeadas
  unset backup_lista
  # coloque as pastas em ordem de importancia
  # ex.1 : todas as pastas :
  #backup_lista=`ls -1 $ponto_origem`
  # ex.2 : apenas agumas
  backup_lista=( "${backup_lista[@]}" "/home/administrador" )
  backup_lista=( "${backup_lista[@]}" "/home/wwwvidy" )
  backup_lista=( "${backup_lista[@]}" "/etc" )
  backup_lista=( "${backup_lista[@]}" "/var/log/squid3" )
  # conferindo se todos os diretorios requisitados existem
  pastas_inexistentes=0
  #for dir2bkp in "${backup_lista[@]}"; 
  for dir2bkp in $backup_lista;
  do
    if ! [ -d "$dir2bkp" ] ; then
      log "A pasta para backup-$HOSTNAME [$dir2bkp] nao existe!"
      pastas_inexistentes=1
    fi
  done

  # realizando o backup
  log "Iniciando backup-$HOSTNAME as $data_ini" 
  DO_BACKUP_STATUS_ESTESERVIDOR="S"
  for pak in "${backup_lista[@]}" ; do
    # confere se permanece montada
    do_montar_confere "$alvo_pasta"
    if [ $do_montar_confere -gt 0 ] ; then
      do_copy_comprime "$pak" "$backup_folder" "tgz"
      if [ "$do_copy_comprime" = "OK" ] ; then
        log "Backup de $pak para $backup_folder realizado com sucesso."
      else
        DO_BACKUP_STATUS_ESTESERVIDOR="N"  
        log "Backup de $pak para $backup_folder reteve erros, verifique o log."
      fi
    else
      log "[backup-falhou] Unidade de Backup desmountou-se sozinha : [$mountdir]."
      DO_BACKUP_STATUS_ESTESERVIDOR="N"  
    fi
  done

  ### desmontando a unidade de destino
  do_desmontar "$mountdir"
}
  
function do_backup_firebirdsql() {
  log "****************************************************"
  log "* BACKUP DO SERVIDOR DE BANCO DE DADOS FIREBIRDSQL *"
  log "****************************************************"
  DO_BACKUP_STATUS_FIREBIRD="S"
  FB_USER='SYSDBA'
  FB_PASSWORD='kubix2vidy'

  # montando a unidade de destino, normalmente o usbdisk
  do_montar_dev "$ponto_device" "$mountdir"
  if [ "$RESULT_VALUE" != "OK" ] ; then
    do_desmontar "$mountdir"
    return;
  fi
  DO_BACKUP_STATUS_FIREBIRDSQL="S"  
  # lista de databases do firebird a serem backupeados
  # coloque os databases em ordem de importancia
  # lista de pastas a serem backupeadas
  unset backup_lista
  #backup_lista=( "${backup_lista[@]}" "192.168.1.14:admin1.fdb" )
  backup_lista=( "${backup_lista[@]}" "192.168.1.14:c:/jade/dados/admin1.fdb" )
  backup_lista=( "${backup_lista[@]}" "192.168.1.14:c:/jade/dados/consultaonline.fdb" )
  backup_lista=( "${backup_lista[@]}" "192.168.1.14:c:/sesmt/dados/sesmt.fdb" )
  #backup_lista=( "${backup_lista[@]}" "192.168.1.14:c:/Arquivos de programas/Firebird/Firebird_2_5/security2.fdb" )
  #backup_lista=( "${backup_lista[@]}" "192.168.1.14:/var/lib/firebird2/system/security.fdb" )
  if [ "${#backup_lista[@]}" -eq 0 ] ; then
    log "[falha] firebird : não há lista para backup."
    do_desmontar "$mountdir"
    return;
  fi
  
  
  for fb_source in "${backup_lista[@]}" ; do  
    # o nome do arquivo de backup sera praticamente o mesmo
    # nome da origem, apenas o sufixo .fbk para diferenciar
    # e os _ que subsituirao caracteres especiais
    fb_dest="$fb_source"
    fb_dest=${fb_dest//.fb/\.fbk}
    fb_dest=${fb_dest//.fdb/\.fbk}
    fb_dest=${fb_dest//.dat/\.fbk}
    fb_dest=${fb_dest//.gdb/\.fbk}
    # trocando / por _
    fb_dest=${fb_dest//\//\_}
    # trocando : por apenas -
    fb_dest=${fb_dest//:/\-}
    # trocando \\ por apenas -
    fb_dest=${fb_dest//\\/\-}
    # trocando -_ por apenas -  
    fb_dest=${fb_dest//-_/\-}
    # acrescentando o path de destino
    fb_dest="$backup_folder/$fb_dest"
    fb_folder=`dirname "$fb_dest"`
    # confere se permanece montada
    do_montar_confere "$alvo_pasta"
    if [ $do_montar_confere -gt 0 ] ; then
      if ! [ -d "$fb_folder" ] ; then
        mkdir -p "$fb_folder"
      fi
      log "Processando backup de :\n\t\"$fb_source\" \n para \n\t\"$fb_dest\""
      /usr/bin/gbak -t -user "$FB_USER" -password "$FB_PASSWORD" "$fb_source" "$fb_dest" 2>>$file_error_log
      if [ $? -ne 0 ] ; then
        log "[backup-falhou] firebird : gbak -v -t -user \"$FB_USER\" -password \"*****\" \"$fb_source\" \"$fb_dest\""
        DO_BACKUP_STATUS_FIREBIRDSQL="N"
      else
        log "[sucesso] firebird : backup de \"$fb_source\" para \"$fb_dest\""
      fi
    else
      log "[backup-falhou] Unidade de Backup desmountou-se sozinha : [$mountdir]."
      DO_BACKUP_STATUS_FIREBIRDSQL="N"
    fi
  done

  ### desmontando a unidade de destino
  do_desmontar "$mountdir"
}

function do_backup_mssql() {
  log "**********************************************"
  log "* BACKUP DO SERVIDOR DE BANCO DE DADOS MSSQL *"
  log "**********************************************"
  DO_BACKUP_STATUS_MSSQL="S"
  agente_user="agente_backup"
  agente_pass="Vidy123"
  agente_dom="vidy.local"
  NOVA_PASTA="$backup_folder/mssql65"
  ponto_rede_mssql="//192.168.1.14/sqlbackup"
  ponto_origem="/media/remoto/mssql"
  DO_BACKUP_STATUS_MSSQL="S"  
  # confere se permanece montada
  do_montar_confere "$ponto_rede_mssql"
  if [ $do_montar_confere -ne 0 ] ; then
    do_montar_cifs "$ponto_rede_mssql" "$ponto_origem"
    if [ "$RESULT_VALUE" != "OK" ] ; then
      log "[backup-falhou] mssql : Não foi possivel montar a unidade de origem [$ponto_rede_mssql] em [$ponto_origem] "
      do_desmontar "$ponto_origem"
      return
    fi 
  fi

  # montando a unidade de destino, normalmente o usbdisk
  do_montar_dev "$ponto_device" "$mountdir"
  if [ "$RESULT_VALUE" != "OK" ] ; then
    DO_BACKUP_STATUS_MSSQL="N"
    do_desmontar "$ponto_origem"
    do_desmontar "$mountdir"
    return
  fi  


  ARQ_ATUAL="$ponto_origem/backup_total.DAT"
  NOME_ARQUIVO=`basename "$ARQ_ATUAL"`
  # verifica se havia arquivos para serem copiados la
  if [ -s "$ARQ_ATUAL" ] ; then
    # confere se permanece montada
    do_montar_confere "$alvo_pasta"
    if [ $do_montar_confere -gt 0 ] ; then
      if ! [ -d "$NOVA_PASTA" ] ; then
        mkdir -p "$NOVA_PASTA"
      fi
      gzip -c "$ARQ_ATUAL" >"$NOVA_PASTA/$NOME_ARQUIVO.gz"
       if [ $? -ne 0 ] ; then
          log "[backup-falhou] : erro ao copiar [$ponto_rede_mssql/backup_total.DAT] para [$NOVA_PASTA/$NOME_ARQUIVO.gz]"
	  DO_BACKUP_STATUS_MSSQL="N"
       else
          log "[sucesso] : Backup de[$ponto_rede_mssql/backup_total.DAT] para [$NOVA_PASTA/$NOME_ARQUIVO.gz] feito com sucesso."
          # se o backup foi feito com sucesso entao remove o backup do servidor mssql, pois o mesmo
          # sera recirado conforme a programacao no servidor
          rm -f "$ARQ_ATUAL"
          if [ $? -ne 0 ] ; then
            log "  Porem não foi possivel eliminar [$ponto_rede_mssql/backup_total.DAT] após a cópia."
          fi
       fi
    else
      log "[backup-falhou] Unidade de Backup desmountou-se sozinha : [$mountdir]."
      DO_BACKUP_STATUS_MSSQL="N"
    fi
  else
      log "[backup-falhou] Backup do SQLServer nao foi encontrado : [$ponto_rede_mssql/backup_total.DAT]."
      DO_BACKUP_STATUS_MSSQL="N"
  fi

  # desmontando a unidade de origem
  do_desmontar "$ponto_origem"
        
  ### desmontando a unidade de destino
  do_desmontar "$ponto_device"
}



############################
# Inicio do Programa       #
############################
export LANGUAGE="pt_BR:pt:pt_PT"
export LANG="pt_BR.UTF-8"

tape_operator='administrador'
tape_group='nogroup'
tape_prioridade=0

FB_USER='SYSDBA'
FB_PASSWORD='masterkey'

modo_automatico="1"
ponto_device=""
device_type="auto"
ponto_rede_smb=""
ponto_rede_nfs=""
ponto_origem=""
mountdir="/media/usbdisk"

#
# Preparando o backup
#


# eliminando arquivos temporarios
sudo rm -f "$sendmail_attach_file" 
sudo rm -f "$sendmail_message_file"

# verificando o dia da semana
# 1=segunda...7=domingo
dia_semana=`date +%u`

#
# variaives importantes que definem destino do backup
# titulos, etc...
script_usbdisk="/home/administrador/scripts/usbdisk.sh"
backup_cronfile="/home/administrador/backup/cron.txt"
#backup_title="backup-servidores-$HOSTNAME-`date +%Y-%m-%d`"
backup_title="backup-`date +%Y-%m-%d`"
backup_lista_negra="/home/administrador/backup/backup_lista_negra.txt"
backup_log_folder="/home/administrador/backup/`date +%Y-%m`";
file_error_log="$backup_log_folder/$backup_title.log"
LOGS="$file_error_log"
backup_folder="$mountdir/`date +%Y-%m-%d`"
backup_inicio="`date +%Y-%m-%d+%H:%M`"
data_ini="`date +%Y-%m-%d+%H:%M`"
sendmail_message_file=`mktemp`
sendmail_attach_file="/tmp/$backup_title.zip"
# verificando a presenca do arquivo backup-cron
if ! [ -f "$backup_cronfile" ] ; then
  sudo touch $backup_cronfile
  sudo chown administrador $backup_cronfile
  sudo chmod 660 $backup_cronfile
fi

if [ -f "$file_error_log" ] ; then 
  rm -f "$file_error_log"
  touch "$file_error_log"
  chmod 666 "$file_error_log"
  echo "Lista de arquivos que nao serao copiados :">>"$file_error_log"
  cat /home/administrador/backup/backup_lista_negra.txt >>"$file_error_log"
fi

# verificando se o ponto de montagem existe, se nao existir entao cria
if ! [ -d $mountdir ] ; then
  mkdir -p "$mountdir"
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

# testando a unidade
do_test_disk "$ponto_device" "$mountdir"
if [ "$DO_DISK_TEST_RESULT_VALUE" != "OK" ] ; then
  do_desmontar "$mountdir"
  log "O disco $ponto_device não passou no teste inicial."
  do_sendmail2;
  exit 1;
else
  log "O disco $ponto_device passou no teste inicial e o backup prosseguirá."
fi 

# eliminado arquivos desnecessarios (se existir)  
sudo rm -fv "$sendmail_attach_file"
sudo rm -fv "$sendmail_message_file" 

# no relatorio acrescentando o espaco disponivel antes de iniciar o backup :
log "-"
log ".   Espaco na unidade $ponto_device antes de iniciar o backup :" 
log ".  `df -h $ponto_device|grep \"Uso\%\"`"
log ".  `df -h $ponto_device|grep \"$ponto_device\"`"
log "-"   
log "Arquivo de log sera gerado em :"
log "=>$file_error_log"

#
# Variaveis importantes
#

data_ini=`date +%d-%m-%Y+%H:%M` 

# variaveis com status se o backup
# foi bem sucedido ou nao
DO_BACKUP_STATUS_FIREBIRDSQL="N"
DO_BACKUP_STATUS_ESTESERVIDOR="N"
DO_BACKUP_STATUS_MSSQL="N"

# Identificando os backups que serao realizados
#REPARAR_DISCO_USB="S"
DO_BACKUP_FIREBIRDSQL="S"
DO_BACKUP_MSSQL="S"
DO_BACKUP_ESTESERVIDOR="S"

### So habilitar quando o backup do fileserver nao puder ser feito pelo proprio fileserver

log "[inicio] Relatorio do backup $backup_title iniciado em $data_ini :" 

# Antes de prosseguir com o Backup precisamos
# checar a integridade do disco USB
# e repara-lo caso haja problemas
if [ "$REPARAR_DISCO_USB" = "S" ] ; then
    ### desmontando a unidade USB se ela estiver montada
    if [ "`mount |grep $ponto_device|wc -l`" -gt 0 ] ; then
      umount $ponto_device
    fi
    /home/administrador/scripts/reparar_usbdisk.sh "$ponto_device"
    # aguarda uns 30 segundos
    sleep 30s;
fi

#
# Nas linhas abaixo realizamos o backup, a precedencia é importante
# no exemplo abaixo, o backup do mssql vem primeiro, depois firebird, etc...
#
if [ "$DO_BACKUP_MSSQL" = "S" ] ; then
  do_backup_mssql
  if [ "$DO_BACKUP_STATUS_MSSQL" = "S" ] ; then
    log ".  Servidor TERRA MSSQL.....................OK"
  else
    log ".  Servidor TERRA MSSQL.....................FALHOU (ou o backup já foi feito hoje, confira o disco)"
  fi
fi

if [ "$DO_BACKUP_FIREBIRDSQL" = "S" ] ; then
  do_backup_firebirdsql
  if [ "$DO_BACKUP_STATUS_FIREBIRDSQL" = "S" ] && [ "$DO_BACKUP_FIREBIRDSQL" = "S" ]; then
    log ".  Servidor FirebirdSQL...............OK" 
  else
    log ".  Servidor FirebirdSQL...............FALHOU (parcial ou total, confira o log)" 
  fi
fi

if [ "$DO_BACKUP_ESTESERVIDOR" = "S" ] ; then
  do_backup_esteservidor
  if [ "$DO_BACKUP_STATUS_ESTESERVIDOR" = "S" ] ; then
    log ".  Este servidor $HOSTNAME.................OK" 
  else
    log ".  Este servidor $HOSTNAME.................FALHOU (parcial ou total, confira o log)" 
  fi
fi

echo "preparando um relatorio para envio..."
data_fim=`date +%d-%m-%Y+%H:%M` 

log "[fim] $backup_title iniciado em $data_ini ate $data_fim"

do_sendmail2;

# elimina arquivos temporarios
[ -f "$sendmail_attach_file" ] && rm -f "$sendmail_attach_file"
[ -f "$sendmail_message_file" ] && rm -f "$sendmail_message_file"

# Fim do Programado_mount
