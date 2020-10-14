#!/bin/bash

do_ver_log()
{
  BACKUPDIR="/home/administrador/backup"
  clear
  echo "digite o Ano seguido do mês (AAAA-MM), ex: 2006-04 para Abril de 2006"
  read ano_mes
  if [ -d "/home/administrador/backup/$ano_mes" ] ; then
    echo "Ok, periodo existente, vamos ao proximo passo..."
  else
    echo "Este período não existe nos nossos logs de backup."
    echo "pressione [ENTER] para prosseguir."
    read
    do_menu;
  fi
  clear;
  ls "$BACKUPDIR/$ano_mes"
  echo "Qual o nome do arquivo de backup que deseja consultar ?"
  echo -n "(uma lista acima foi exibida)" 
  read arquivo_log
  if [ -f "$BACKUPDIR/$ano_mes/$arquivo_log" ] ; then
    echo "arquivo de log existente, procurando abri-lo."
  else
    echo "Nao temos registro de backup neste dia ($ano_mes/$arquivo_log)."
    echo "pressione [ENTER] para prosseguir."
    read
    do_menu;
  fi
  
  nano -v "$BACKUPDIR/$ano_mes/$arquivo_log"

}

do_menu()
{
  clear
  while :
  do
    clear
    echo "-------------------------------------------------------------"
    echo "           C O N T R O L E   D E   B A C K U P S             "
    echo "-------------------------------------------------------------"
    echo "1- Realizar o backup completo agora"
    echo "2- Ver o log de backup dum determinado dia"
    echo "3- Editar lista de arquivos que NAO SERAO backupeados"
    echo "5- Autoreparo na unidade de backup"
    echo "6- Limpar backups mais antigos na unidade USB"
    echo "7- Montar/Desmontar Unidade de Backup"
    echo "99- Sair"
    echo -n "Escolha uma opcao [1-99] :"
    read opcao
    case $opcao in
    1)sudo "$SCRIPTS/fazer_backup_vidy.sh";;
    2)do_ver_log;;
    3)editar /home/administrador/backup/backup_lista_negra.txt;;
    5)sudo "$SCRIPTS/reparar_usbdisk.sh";
      echo "Tecle [ENTER] para prosseguir.";
      read espera;;    
    6)sudo "$SCRIPTS/limpar_usbdisk.sh";
      echo "Tecle [ENTER] para prosseguir.";
      read espera;;
    7)sudo "$SCRIPTS/montar_usbdisk.sh";
      echo "Tecle [ENTER] para prosseguir.";
      read espera;;    
    99)exit 0;;
    *) echo "Opcao invalida !!!"; sleep 1;;
    esac
  done
}

# Inicio do Programa
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

 
  do_menu

# Fim do Programa
