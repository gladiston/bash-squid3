#!/bin/bash
# Script desenvolvido por : 
# Gladiston Hamacker Santana <gladiston.santana@gmail.com>
# Data : 02/02/2006
# Uso : Limpar a unidade de troca de arquivos (O:)

# trap ctrl-c and call ctrl_c() trap ctrl_c INT
trap ctrl_c INT
function ctrl_c() { 
  echo "*** backup interrompido pelo usuario ***" ;
  do_sendmail;
  exit 1;
}

function log() {
  if [ -z "$1" ] ; then
    echo "Parametro para log esta vazio"
    return
  fi
  if ! [ -f "$file_error_log" ] ; then
    echo "Arquivo para registrar log [$file_error_log]  não existe !"
    echo -ne "Criando um arquivo vazio..."
    touch "$file_error_log"
    echo "[OK]"
    #exit 2;
  fi
  echo "$1"
  echo "$1" >>$file_error_log
}

function sugestao_nome_arq_comprimido() {
  # retorna um nome sugestivo para uma pasta
  # em forma de nome de arquivo
  # util para compactar uma pasta, porem
  # escolher um nome para o zip que tenha
  # alguma coisa a ver com o nome original
  # da pasta onde foram comprimido os 
  # arquivos.
  if [ -z "$1" ] || [ "$1" = "" ] ; then
    echo "Parametro esta vazio"
    return
  fi

  # nomes sem acentuacao
  do_remover_acentuacao "$1"
  SUGESTAO_ARQUIVO="$RETURN_STRING"

  # trocando // por servidor_ (caso de a origem for um endereco smb //server/compartilhamento)
  if [ "${SUGESTAO_ARQUIVO:0:2}" = "//" ] ; then
      SUGESTAO_ARQUIVO=${SUGESTAO_ARQUIVO//\/\//servidor_}
  else
      # removendo o primeiro "/" do endereco para compor o nome nome
      if [ "${backup_file:0:1}" = "/" ] ; then
        SUGESTAO_ARQUIVO=${SUGESTAO_ARQUIVO:1} 
      fi
  fi
  # iniciou com _ entao remove o primeiro caracter
  [ "${SUGESTAO_ARQUIVO:0:1}" = "_" ] && SUGESTAO_ARQUIVO=${SUGESTAO_ARQUIVO:1}
  [ "${SUGESTAO_ARQUIVO:0:1}" = "_" ] && SUGESTAO_ARQUIVO=${SUGESTAO_ARQUIVO:1} 
  # trocando / por :
  SUGESTAO_ARQUIVO=${SUGESTAO_ARQUIVO//\//:}
  # trocando :mnt: por nada
  SUGESTAO_ARQUIVO=${SUGESTAO_ARQUIVO//:mnt:/}
  # trocando :media: por nada
  SUGESTAO_ARQUIVO=${SUGESTAO_ARQUIVO//:media:/}
  # trocando : por _
  SUGESTAO_ARQUIVO=${SUGESTAO_ARQUIVO//:/_}
  # iniciou com _ entao remove o primeiro caracter
  [ "${SUGESTAO_ARQUIVO:0:1}" = "_" ] && SUGESTAO_ARQUIVO=${SUGESTAO_ARQUIVO:1}
  [ "${SUGESTAO_ARQUIVO:0:1}" = "_" ] && SUGESTAO_ARQUIVO=${SUGESTAO_ARQUIVO:1} 
  echo $SUGESTAO_ARQUIVO
}


function do_montar_dev() {
  alvo_device="$1"
  alvo_pasta="$2"
  RESULT_VALUE="FALHOU"
  if [ "$alvo_device" = "" ] ; then 
     log "Erro na montagem de dispositivo : O nome do dispositivo não foi informado."
     return
  fi  
  if [ "$alvo_pasta" = "" ] ; then
     log "Erro na montagem de dispositivo : O nome do pasta onde seria montado o dispositivo não foi informado."
     return
  fi 
  if ! [ -d  "$alvo_pasta" ] ; then
    mkdir -p "$alvo_pasta"
  fi
  # montando a unidade de destino, normalmente o usbdisk
  mount -t $ponto_fs $alvo_device $alvo_pasta -o sync,nosuid,nouser,rw,dirsync,users
  if [ $? -ne 0 ] ; then
    log "A montagem da unidade de destino-backup falhou !"
    log "Tentativa : mount -t $ponto_fs $ponto_device $ponto_destino -o sync,nosuid,nouser,rw,dirsync,users"
    log "Certifique-se que :"
    log "- tenha ligado a unidade numa porta USB deste servidor;"
    log "- o dispositivo USB esteja ligado com o led de funcionamento piscando."
    log "Desligue o aparelho, aguarde alguns instantes e ligue-o novamente"
    log "e repita a operacao, se insistir o problema contate"
    log "imediatamente o supervidor." 
  else
    RESULT_VALUE="OK"  
  fi
}  

function do_montar_cifs() {
  alvo_smb="$1"
  alvo_pasta="$2"
  RESULT_VALUE="FALHOU"
  if [ "$alvo_smb" = "" ] ; then 
     log "Erro na montagem de SMB : O nome de rede não foi informado."
     return
  fi  
  if [ "$alvo_pasta" = "" ] ; then
     log "Erro na montagem de SMB : O nome do pasta onde seria montado o acesso a [$alvo_device] não foi informado."
     return
  fi 
  if ! [ -d  "$alvo_pasta" ] ; then 
    mkdir -p "$alvo_pasta"
  fi
  # montando a unidade de rede, as variaveis agente_user, agente_pass e agente_dom serao reaproveitadas
  mount -t cifs $alvo_smb $alvo_pasta -o username=$agente_user,password=$agente_pass,domain=$agente_dom,users,file_mode=0777,dir_mode=0777,iocharset=utf8,rw
  if [ $? -ne 0 ] ; then
    log "Falhou : mount -t cifs $alvo_smb $alvo_pasta -o username=$agente_user,password=*****,domain=$agente_dom,users,file_mode=0777,dir_mode=0777,iocharset=utf8,rw"
  else
    RESULT_VALUE="OK"    
  fi
} 

function do_desmontar() {
  alvo="$1"
  if [ "$alvo" = "" ] || \
     ! [ -d "$alvo" ] ; then
     echo "alvo para desmontar nao existe : [$alvo]"
     return
  fi

  # verifica se esta realmente montado
  dir_to_unmount=$(mount |grep "$alvo"|cut -d" " -f 3)
  
  # verifica se o que se esta tentado desmontar é realmente uma unidade montada
  if ! [[ "$alvo" =~ "$dir_to_unmount" ]] ; then
    echo "Tentando desmontar : $alvo"
    echo "Mas, achei : $dir_to_unmount"
    echo "Como sao diferentes, o software recusa-se a desmontar a unidade."
    return 
  fi
  
  if [ -d "$dir_to_unmount" ] ; then
      umount $dir_to_unmount
      if [ "$dir_to_unmount/*" = "$dir_to_unmount/*" ] ; then
        echo "removendo diretorio vazio [$alvo]"
        rmdir $alvo
      fi
  fi
}

#######################################
# Limpando as caixas de entradas      #
#######################################
. /home/administrador/menu/mainmenu.var
if [ $? -ne 0 ] ; then
  echo "Nao foi possivel importar o arquivo [/home/administrador/menu/mainmenu.var] !"
  exit 2;
fi
maxage=0
smbserver="obelix"
agente_user="agente_backup"
agente_pass="ViDy123"
agente_dom="vidy.local"
data_ini=`date +%d-%m-%Y+%H:%M%S`
trash_folder="/home/mnt/caixa_entrada_pub"
trash_smbfolder="//$smbserver/pub"
tempfile="/tmp/$smbserver_pub.txt"

# Arquivo de log
file_error_log="$LOGS/pub/limpar_caixa_entrada-`date +%Y-%m-%d%S`.log"
folder_error_log=`dirname "$file_error_log"`

# Verificando se o nome do servidor smb está em /etc/hosts
EXISTE=`cat /etc/hosts|grep $smbserver|wc -l`
if [ "$EXISTE" -eq 0 ] ; then
  log "O nome do servidor SMB ($smbserver) nao foi encontrado no arquivo /etc/hosts"
  exit 2;
fi

# criando pasta para guardar os logs
if ! [ -d "$folder_error_log" ] ; then
  mkdir -p "$folder_error_log"
  chmod 2777 "$folder_error_log"
fi

[ -f "$file_error_log" ] && mv -f "$file_error_log" "$file_error_log.old"
# criando pasta para montagem
if ! [ -d "$trash_folder" ] ; then
  mkdir -p "$trash_folder"
  chmod 2777 "$trash_folder"
fi

# montando o diretorio para acesso ao CAIXA DE ENTRADA
do_montar_cifs "$trash_smbfolder" "$trash_folder"

if [ "$RESULT_VALUE" != "OK" ] ; then
  log "Saída prematura do programa."
  exit 2
fi

#
# Iniciando processo
#
log "[$data_ini] Iniciando a limpeza nas caixas de entradas (pub) em $trash_smbfolder"
log "  montada a pasta $trash_smbfolder em $trash_folder"
log "  gerando listagem das pastas em $tempfile"
log "  arquivo de log em $file_error_log"

unset lixeira
ls -1 "$trash_folder/"  >$tempfile
mydir=""

log "Inspecionando $trash_smbfolder"
while read current_dir ; do
   if [ "$current_dir" != "" ] ; then
     mydir="$trash_folder/$current_dir"
     [ -d "$mydir" ] && lixeira=( "${lixeira[@]}" "$mydir" )
     log "  Acrescentado a lista : $mydir"
   fi
done <$tempfile

echo "[$data_ini] Eliminando arquivos de cada pasta em $trash_smbfolder"
for pasta in "${lixeira[@]}" ; do
  if [ "$(ls -A $pasta 2>/dev/null)" ] ; then
    log "Eliminando arquivos de $pasta"
    rm -fR "$pasta/"*
  fi
done

# desmonta a unidade remotada
do_desmontar "$trash_folder"

#
# Finalizando a operacao 
#
data_fim=`date +%d-%m-%Y+%H:%M%S`
log "[$data_fim] Terminada a limpeza nas caixas de entradas em $trash_smbfolder"
