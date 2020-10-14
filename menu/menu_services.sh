#!/bin/bash 

function servicos_editar() {
  arquivo="$1"
  if editar "$arquivo" ; then 
    echo "O arquivo :"
    echo -e "\t$arquivo"
    echo "foi alterado, bem poucos serviços requerem reiniciar o servidor."
    echo "Voce deseja reiniciar o servidor ?"
    read CONFIRMA
    if [ "$CONFIRMA" = "SIM" ] || [ "$CONFIRMA" = "sim" ] || [ "$CONFIRMA" = "S" ] || [ "$CONFIRMA" = "s" ] ; then
       restart
    fi
  fi
}

function restart() {
  echo "Reiniciar este servidor ?"
  read CONFIRMA
  if [ "$CONFIRMA" = "SIM" ] || [ "$CONFIRMA" = "sim" ] || [ "$CONFIRMA" = "S" ] || [ "$CONFIRMA" = "s" ] ; then
     reboot
  fi
}

function do_setdns_local()
{
  #
  # Ajusta qual será o DNS externo que o DNS local usará
  #
  clear;
  # Sera que esta instalado o BIND ou DNSMASQ
  DNSLOCAL=""
  ARQ_CONF=""
  if [ -f "/etc/init.d/bind9" ] ; then
    DNSLOCAL="bind9"
    ARQ_CONF="/etc/bind/named.conf.options"
  fi

  if [ -f "/etc/init.d/dnsmasq" ] ; then
     DNSLOCAL="dnsmasq"
     ARQ_CONF="/etc/resolv-dnsmasq.conf"
  fi

  if [ -z "$DNSLOCAL" ] || [ "$DNSLOCAL" = "" ] ; then
    echo "Servico de DNS nao esta instalado."
    echo "Nao encontrei nem o BIND e nem o DNSMASQ."
    press_enter_to_continue
    return
  fi

  if editar "$ARQ_CONF" ; then 
      echo "O arquivo :"
      echo -e "\t$ARQ_CONF"
      echo "foi alterado, recomendo reiniciar o serviço de DNS."
      echo "Reiniciar o serviço de DNS ?"
      read CONFIRMA
      if [ "$CONFIRMA" = "SIM" ] || [ "$CONFIRMA" = "sim" ] || [ "$CONFIRMA" = "S" ] || [ "$CONFIRMA" = "s" ] ; then
         service $DNSLOCAL restart
         press_enter_to_continue
      fi
  fi
}

function do_liberar_espaco()
{
  echo -ne "\nPara liberar espaço em disco, o sistema remover o cache de pacotes instalados neste computador "
  echo -ne "e tambem versões antigas de kerneis que foram baixados e ainda residem no computador."
  echo -ne "\nAntes de executar a limpeza é adequado reiniciar o computador para conferir se "
  echo -ne "não há nenhuma versão de kernel novo sendo aguardado para aplicação após o boot."
  echo -ne "\nDigite [SIM] para prosseguir, qualquer outra resposta para retornar."
  if ! do_confirmar "Digite [SIM] para prosseguir, qualquer outra resposta para retornar."; then 
    return
  fi
  echo "Eliminando pacotes em cache..."
  sudo apt-get clean
  echo "Eliminando kerneis antigos..."
  sudo dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d' | xargs sudo apt-get -y purge
  echo "Limpeza completada."
  press_enter_to_continue  
}

function do_update()
{
  echo "O sistema fará agora a atualização de si próprio."
  if ! do_confirmar "Digite [SIM] para prosseguir, qualquer outra resposta para retornar."; then 
    return
  fi
  echo "Atualização em andamento..."
  sudo apt-get update -y
  sudo apt-get upgrade -y
  echo "Atualização completada."
  press_enter_to_continue  
}

function do_testar_conectividade_internet() {
  clear
  "$SCRIPTS/testar_internet.sh"
  press_enter_to_continue;
}

function do_testar_conectividade_dnslocal() {
  clear
  "$SCRIPTS/testar_dns_local.sh"
  press_enter_to_continue;
}

function do_menu()
{
  clear
  while :
  do
    clear
    echo "-------------------------------------------------------------"
    echo "                      S E R V I Ç O S"
    echo "-------------------------------------------------------------"
    echo "1 - Ir para o terminal (bash)"
    echo "2 - Autenticação do Speedy"
    echo "3 - Testar a capacidade de envio de email deste host"
    echo "3 - Editar /etc/services"
    echo "5 - Editar /etc/resolv.conf"
    echo "6 - Editar /etc/hosts"
    echo "7 - Editar /etc/network/interfaces"
    echo "8 - Agendamento Local"
    echo "9 - Configurar DNS Local (dnsmasq ou bind9)"
    echo "10- Forçar o checkdisk no próximo boot"
    echo "11- Liberar espaço em disco"
    echo "12- Atualiza este sistema"    
    echo "13- Testar conectividade com a internet"
    echo "14- Testar resolução de DNS Local"
    echo "15- Placas de rede detectadas"
    echo "98- Reiniciar este servidor"
    echo "99- Sair"
    echo -n "Escolha uma opcao [1-99] :"
    read opcao
    case $opcao in
    1)/bin/bash --norc;;
    2) echo "aguarde a autenticacao...";
       sudo "$SCRIPTS/scripts/autenticacao_speedy.sh";
       echo "operacão finalizada, se essa autenticacao automatica nao funcionar"
       echo "entao faça a autenticacao manualmente no endereço WEB :"
       echo "http://200.171.222.93/wsc/servlet/popupView.do?CPURL="
       echo "tecle [ENTER] para prosseguir." ;
       press_enter_to_continue;;
    3)"$SCRIPTS/testar_email.sh"
       press_enter_to_continue;;
    4) servicos_editar "/etc/services";; 
    5) servicos_editar "/etc/resolv.conf";;
    6) servicos_editar "/etc/hosts";;
    7) servicos_editar "/etc/network/interfaces";;
    8) crontab -e;;
    9) do_setdns_local;;
    10)touch /forcefsck;
       echo "Pronto. No próximo reinicio o boot será realizado.";
       echo "Se estiver desesperado para realizar a checagem agora, ";
       echo "entao execute no terminal :";
       echo "sudo shutdown -rF now";
       echo "Isso reiniciará o computador, e fará a checagem imediatamente.";
       press_enter_to_continue;;
    11) do_liberar_espaco;;
    12) do_update;;
    13) do_testar_conectividade_internet;;
    14) do_testar_conectividade_dnslocal;;
    15) editar "/etc/udev/rules.d/70-persistent-net.rules";;
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

# Funcoes importantes para este script
. /home/administrador/scripts/functions.sh
if [ $? -ne 0 ] ; then
  echo "Nao foi possivel importar o arquivo [/home/administrador/scripts/functions.sh] !"
  exit 2;
fi

do_menu
# Fim do Programa
