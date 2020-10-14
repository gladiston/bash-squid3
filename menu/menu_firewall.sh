#!/bin/bash 

function fw_editor() {
  arquivo=$1
  oferece_reiniciar=$2  # S ou N se deve perguntar sobre reiniciar o firewall
  REINICIOU_FIREWALL=""
  if [ -f "$arquivo" ] ; then
    MD5SUM_ANTES=`md5sum "$arquivo"`
    nano "$arquivo"
    MD5SUM_DEPOIS=`md5sum "$arquivo"`
    if [ "$MD5SUM_ANTES" != "$MD5SUM_DEPOIS" ] && [ "$oferece_reiniciar" != "N" ] ; then
      echo "O arquivo : $arquivo"
      echo "foi alterado, recomendo reiniciar o firewall."
      echo "Reiniciar o firewall ?"
      read CONFIRMA
      if [ "$CONFIRMA" = "SIM" ] || [ "$CONFIRMA" = "sim" ] || [ "$CONFIRMA" = "S" ] || [ "$CONFIRMA" = "s" ] ; then
         reinit_firewall
         REINICIOU_FIREWALL="OK" 
      fi
    fi
  fi
}

function fw_ips_transparentes() {
  arquivo="$1"
  echo "Liberando IPs transparentes temporarios a partir de $arquivo"
  while read LINHA ; do
    LIBERAR_IP=`semremarks "$LINHA"`
    if [ "$LIBERAR_IP" != "" ] ; then
       echo -e "\tIP transparente [temp] : $LINHA"
       $IPTABLES -t nat -A POSTROUTING -s $LIBERAR_IP -j MASQUERADE
    fi
  done <"$arquivo"
  press_enter_to_continue
} 

do_menu()
{
  clear
  while :
  do
    clear
    echo "-------------------------------------------------------------"
    echo "               M E N U  P A R A  I N T E R N E T             "
    echo "-------------------------------------------------------------"
    echo "1- Reiniciar o firewall"
    echo "2- Editar lista de IP com acesso transparente fixos*"
    echo "3- Editar lista de IP com acesso transparente temporario*"
    echo "4- Editar lista de sites negados (sem efeito para transparentes)"
    echo "5- Editar lista de sites liberados(transparentes e diretos)"
    echo "6- Editar lista de enderecos MACs a serem bloqueados"
    echo "7- Editar lista de portas bloqueadas"
    echo "8- Editar lista de portas liberadas"
    echo "9- Editar lista de portas redirecionadas"
    echo "99- Sair"
    echo "Marcados com [*] não requer reiniciar o firewall"
    echo -n "Escolha uma opcao [1-99] :"
    read opcao
    case $opcao in
    1)reinit_firewall;;
    2)fw_editor "$FIREWALL/fw-transparentes-fixos.txt" "N";
      if [ "$REINICIOU_FIREWALL" != "OK" ] ; then
        fw_ips_transparentes "$FIREWALL/fw-transparentes-fixos.txt" ;
      fi;;
    3)fw_editor "$FIREWALL/fw-transparentes-temp.txt" "N";
      if [ "$REINICIOU_FIREWALL" != "OK" ] ; then
        fw_ips_transparentes "$FIREWALL/fw-transparentes-temp.txt";
      fi;;
    4)fw_editor "$FIREWALL/sites_negados.txt";;
    5)fw_editor "$SQUIDACL/sites_diretos.txt";;
    6)fw_editor "$FIREWALL/macaddr_bloqueados.txt";;
    7)fw_editor "$FIREWALL/portas_bloqueadas.txt";;
    8)fw_editor "$FIREWALL/portas_liberadas.txt";;
    9)fw_editor "$FIREWALL/portas_redirecionadas.txt";;
    99)echo "Fim";
      exit 0;;
    *) echo "Opcao invalida !!!"; read;;
    esac
  done
}

#
# Inicio do Programa
#

# Variaveis importantes para este script
. /home/administrador/menu/mainmenu.var
if [ $? -ne 0 ] ; then
  echo "Nao foi possivel importar o arquivo [/home/administrador/menu/mainmenu.var] !"
  exit 2;
fi

# criando arquivos importantes
. /home/administrador/fw-scripts/firewall.files
if [ $? -ne 0 ] ; then
  echo "Nao foi possivel importar o arquivo [/home/administrador/fw-scripts/firewall.files] !"
  exit 2;
fi

# Funcoes importantes para este script
. /home/administrador/scripts/functions.sh
if [ $? -ne 0 ] ; then
  echo "Nao foi possivel importar o arquivo [/home/administrador/scripts/functions.sh] !"
  exit 2;
fi

. /home/administrador/fw-scripts/firewall.functions
if [ $? -ne 0 ] ; then
  echo "Nao foi possivel importar o arquivo [/home/administrador/fw-scripts/firewall.functions] !"
  exit 2;
fi

do_menu
# Fim do Programa
