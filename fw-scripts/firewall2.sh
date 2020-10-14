#!/bin/bash
# Para colocar este script no momento do boot :
# rm /etc/rc2.d/S95firewall
# ln -s /etc/init.d/firewall.sh /etc/rc2.d/S95firewall
#

# trap ctrl-c and call ctrl_c() trap ctrl_c INT
trap ctrl_c INT
function ctrl_c() {
  echo "*** interrompido pelo usuario ***" ;
  exit 2;
}

# Variaveis importantes para este script
. /home/administrador/menu/mainmenu.var

# carregando funcoes importantes
. /home/administrador/fw-scripts/firewall.functions

# criando arquivos importantes
. /home/administrador/fw-scripts/firewall.files

#
# Inicio do Script
#

# Lista de DNSs
# Comente os que nao deseja usar, e mantenha apenas os que deseja
# O maximo de DNS que podem haver sao 3
#do_resolv_conf

# Interfaces de Rede
# Se precisar mudar a ordem das placas fisicamente, entao
# edite o arquivo :
# /etc/udev/rules.d/70-persistent-net.rules
IF_LAN=eth1
IF_INT="192.168.1.254"
IF_GW="192.168.1.1"
REDE_INTERNA="192.168.1.0/24"

# Os diversos módulos do iptables são chamdos através do modprobe
modprobe ip_tables
modprobe iptable_nat
modprobe ip_conntrack
modprobe ip_conntrack_ftp
modprobe ip_nat_ftp
modprobe ipt_LOG
modprobe ipt_REJECT
modprobe ipt_MASQUERADE
modprobe ipt_state
modprobe ipt_multiport
modprobe iptable_mangle
modprobe ipt_tos
modprobe ipt_limit
modprobe ipt_mark
modprobe ipt_MARK

# Mensagem de inicialização do script
echo "########################################"
echo "# Script de Firewall - v2010.12        #"
echo "########################################"
echo 
echo "##########################################################"
echo "# A CARGA DO FIREWALL ESTA INICIANDO                     #"
echo "##########################################################"

# Limpando regras atuais
$IPTABLES -F
$IPTABLES -X
$IPTABLES -P INPUT DROP
$IPTABLES -P OUTPUT ACCEPT
$IPTABLES -P FORWARD ACCEPT

echo "Ativando entrada/saida da interface de loopback"
$IPTABLES -I INPUT -i lo -j ACCEPT
$IPTABLES -I OUTPUT -o lo -j ACCEPT

exit 0;

#echo "Liberando IPs/Sites com acesso transparente e direito"
#echo "Lista : $SQUIDACL/sites_diretos.txt"
#while read LINHA ; do
#  LIBERAR_SITE=`semremarks "$LINHA"`
#  LIBERAR_SITE=`convert_url2site "$LIBERAR_SITE"`
#  if [ "$LIBERAR_SITE" != "" ] ; then
#     echo -e "\tSite transparente : $LINHA"
#     $IPTABLES -t nat -A POSTROUTING -s $REDE_INTERNA -d $LIBERAR_SITE -j MASQUERADE
#  fi
#done <"$SQUIDACL/sites_diretos.txt"

echo "Liberando IPs transparentes fixos"
echo "Lista : $LISTA_IP_TRANSPARENTES_FIXO"
while read LINHA ; do
  LIBERAR_IP=`semremarks "$LINHA"`
  if [ "$LIBERAR_IP" != "" ] ; then
     echo -e "\tIP transparente [fixo] : $LINHA"
     #$IPTABLES -I FORWARD -s $LIBERAR_IP -m state --state ESTABLISHED,RELATED -j ACCEPT
     $IPTABLES -t nat -A POSTROUTING -s $LIBERAR_IP -j MASQUERADE
  fi
done <"$LISTA_IP_TRANSPARENTES_FIXO"

echo "Liberando IPs transparentes temporarios"
echo "Lista : $LISTA_IP_TRANSPARENTES_TEMP"
while read LINHA ; do
  LIBERAR_IP=`semremarks "$LINHA"`
  if [ "$LIBERAR_IP" != "" ] ; then
     echo -e "\tIP transparente [temp] : $LINHA"
     #$IPTABLES -I FORWARD -s $LIBERAR_IP -m state --state ESTABLISHED,RELATED -j ACCEPT
     $IPTABLES -t nat -A POSTROUTING -s $LIBERAR_IP -j MASQUERADE
  fi
done <"$LISTA_IP_TRANSPARENTES_TEMP"

#echo "Bloqueando MacAddr da lista $LISTA_MACLIST_BLOQUEADOS :"
#echo "(este bloqueio precede outras permissoes)"
#while read LINHA ; do
#  MACSOURCE=`semremarks "$LINHA"`
#  if [ "$MACSOURCE" != "" ] ; then
#    echo -e "\tBloqueado MacAddr:$LINHA"
#    $IPTABLES -t filter -A FORWARD -m mac --mac-source $MACSOURCE -j DROP
#    $IPTABLES -t filter -A INPUT -m mac --mac-source $MACSOURCE -j DROP
#    #$IPTABLES -t filter -A PREROUTING -m mac --mac-source $MACSOURCE -j DROP
#  fi
#done < "$LISTA_MACLIST_BLOQUEADOS" 

#
# A politica de negar certos sites simplesmente não funciona
# porque se libero um IP de forma transparente, tais
# regras se sobrepoem a negação
#
#echo "Bloqueando o acesso de nossa rede a algumas redes externas :"
#echo "Lista : $LISTA_SITES_NEGADOS"
#while read LINHA ; do
#  SITE=`semremarks "$LINHA"`
#  SITE=`convert_url2site "$SITE"`
#  if [ "$SITE" != "" ] ; then
#    echo -e "\tSite :$SITE"
#    $IPTABLES -t filter -A FORWARD -s $REDE_INTERNA -d $SITE -j DROP
#    $IPTABLES -t filter -A FORWARD -s $SITE -d $REDE_INTERNA -j DROP
#    $IPTABLES -t filter -A INPUT -s $SITE -j DROP
#    $IPTABLES -t filter -A OUTPUT -d $SITE -j DROP
#    $IPTABLES -A FORWARD -d $SITE -j DROP
#  fi
#done <"$LISTA_SITES_NEGADOS"


echo "Liberando portas do servidor ($WAN):"
echo "Lista : $LISTA_PORTAS_LIBERADAS"
while read LINHA ; do
  INSTRUCAO=`semremarks "$LINHA"`
  PROTO=`echo $INSTRUCAO | cut -d '|' -f 1` #recebe o protocolo a ser redirecionado
  PORTA=`echo $INSTRUCAO | cut -d '|' -f 2` #recebe a porta a ser redirecionado
  [ "$PROTO" = "" ] && PROTO="tcp"
  if [ "$PORTA" != "" ] ; then
    echo -e "\tLiberando Protocolo/Porta : $PROTO:$PORTA"
    $IPTABLES -A INPUT -p $PROTO  --dport $PORTA -j ACCEPT
 fi
done <"$LISTA_PORTAS_LIBERADAS"


#echo "Redirecionando portas ($WAN) a outros servidores :"
#echo "Lista : $LISTA_REDIRECIONAMENTOS"
#while read LINHA ; do
#  i=`semremarks "$LINHA"`
#  if [ "$i" != "" ] ; then
#    REDIPROTO=`echo $i | cut -d '|' -f 1` #recebe o protocolo a ser redirecionado
#    REDIPORTA=`echo $i | cut -d '|' -f 2` #recebe a porta a ser redirecionado
#    REDIP=`echo $i | cut -d '|' -f 3` #recebe o ip a ser redirecionado
#    REDISERVICO=`echo $i | cut -d '|' -f 4` #recebe o nome do serviço 
#    REDIHOST=`echo $i | cut -d '|' -f 5` #recebe o nome do host
#    # liberando a porta
#    echo -e "\tLiberando Protocolo/Porta : $REDIPROTO:$REDIPORTA"
#    $IPTABLES -A INPUT  -p $REDIPROTO --dport $REDIPORTA -j ACCEPT
#    $IPTABLES -A FORWARD  -p $REDIPROTO --dport $REDIPORTA -j ACCEPT
#    $IPTABLES -A OUTPUT -p $REDIPROTO --sport $REDIPORTA -j ACCEPT
#    $IPTABLES -I FORWARD -p tcp --dport $REDIPORTA -j ACCEPT
#    # redirecionando a porta
#    echo -e "\t$WAN:$REDIPORTA($REDISERVICO) ->$REDIP($REDIHOST)"
#    $IPTABLES -A FORWARD -p $REDIPROTO --dport $REDIPORTA -j ACCEPT
#    $IPTABLES -t nat -A PREROUTING -m $REDIPROTO -p $REDIPROTO --dport $REDIPORTA -j DNAT --to-destination $REDIP
#  fi
#done <"$LISTA_REDIRECIONAMENTOS"



#echo "Estabelecendo este servidor como Proxy Transparente."
#$IPTABLES -t nat -A PREROUTING -i $IF_LAN -p tcp --dport 80 -j REDIRECT --to-port 3128

#echo "Mascaramento de rede, mas ninguem terá acesso completo"
#echo "porque o acesso porta 80 esta desviado para o squid."
#$IPTABLES -t nat -A POSTROUTING  -s $REDE_INTERNA -d 0.0.0.0/0.0.0.0 -j MASQUERADE

IP_FORWARD="1"
if [ "$IP_FORWARD" = "1" ] ; then
  echo "Ativando o redirecionamento entre as placas de rede (ip_forward)"
  echo "1" > /proc/sys/net/ipv4/ip_forward
else
  echo "Desativando o redirecionamento entre as placas de rede (ip_forward)"
  echo "0" > /proc/sys/net/ipv4/ip_forward
fi

echo "fim do firewall" >/tmp/fim_do_firewall.txt
echo "##########################################################"
echo "# A CARGA DO FIREWALL ESTA COMPLETA                      #"
echo "##########################################################"

exit 0
