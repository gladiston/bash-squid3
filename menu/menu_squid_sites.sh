#!/bin/bash 

function do_menu()
{
  clear
  while :
  do
    clear
    echo "-------------------------------------------------------------"
    echo "               M E N U  P A R A  I N T E R N E T             "
    echo "-------------------------------------------------------------"
    echo "1 - Editar lista de estacoes por IP transparente (via GW)"
    echo "2 - Editar lista de sites livres(somente dominios)"
    echo "3 - Editar lista de sites livres(dom regex)"
    echo "4 - Editar lista de sites de suporte(dom regex)"
    echo "5 - Editar lista de sites do serviço(dom regex)"
    echo "6 - Editar lista de sites de download(dom regex)"
    echo "7 - Editar lista de sites de certificados(url regex)"
    echo "8 - Editar lista de sites exclusivo para horario-almoço(url regex)"
    echo "9 - Editar lista de sites diretos (via GW)"
    echo "10- Editar lista de sites diretos por IP (via GW)"
    echo "11- Editar lista de sites proibidos(url regex)"
    echo "12- Editar lista de sites governamentais(dom regex)"
    echo "13- Editar lista de extensoes proibidas para download"
    echo "30- Procurar um site em nossas listas de liberação ACL"
    echo "31- Procurar saber se site tem acesso direto ou nao"
    echo "32- Procurar duplicações em sites liberados"
    echo "33- Testar um acesso por usuário sem liberação prévia"    
    echo "34- Publicar lista atual de sites livres"
    echo "99- Sair"
    echo -n "Escolha uma opcao [1-99] :"
    read opcao
    case $opcao in
    1)proxy_conf "$SQUIDACL/ip_liberado.txt" "S";;
    2)proxy_conf "$SQUIDACL/sites_livres.txt";
      "$SCRIPTS/squid_relatorio_sites_livres.sh";;
    3)proxy_conf "$SQUIDACL/sites_livres_regex.txt";
      "$SCRIPTS/squid_relatorio_sites_livres.sh";;
    4)proxy_conf "$SQUIDACL/sites_suporte.txt";
      "$SCRIPTS/squid_relatorio_sites_livres.sh";;
    5)proxy_conf "$SQUIDACL/sites_servico.txt";
      "$SCRIPTS/squid_relatorio_sites_livres.sh";;
    6)proxy_conf "$SQUIDACL/sites_download.txt";
      "$SCRIPTS/squid_relatorio_sites_livres.sh";;
    7)proxy_conf "$SQUIDACL/sites_certificados.txt";
      "$SCRIPTS/squid_relatorio_sites_livres.sh";;
    8)proxy_conf "$SQUIDACL/sites_exclusivo_almoco.txt";
      "$SCRIPTS/squid_relatorio_sites_livres.sh";;
    9)proxy_conf "$SQUIDACL/sites_diretos.txt" "S";
      "$SCRIPTS/squid_relatorio_sites_livres.sh";;
    10)proxy_conf "$SQUIDACL/sites_diretos_ip.txt" "S";
      "$SCRIPTS/squid_relatorio_sites_livres.sh";;
    11)proxy_conf "$SQUIDACL/sites_url_proibidos.txt";;
    12)proxy_conf "$SQUIDACL/sites_governo.txt";
       "$SCRIPTS/squid_relatorio_sites_livres.sh";;
    13)proxy_conf "$SQUIDACL/sites_extensoes_proibidos.txt";;
    30)"$SCRIPTS/squid_procura_site.sh";;  
    31)"$SCRIPTS/squid_procura_direto.sh";
       "$SCRIPTS/squid_relatorio_sites_livres.sh";;
    32)"$SCRIPTS/squid_procura_duplicacoes.sh";;
    33)"$SCRIPTS/squid_testa_site.sh";;  
    34)"$SCRIPTS/squid_relatorio_sites_livres.sh";
       echo "Pressione [ENTER] para retornar..."
       read;; # press_enter_to_continue;
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
  echo "Nao foi possivel importar o arquivo [. /home/administrador/scripts/functions.sh] !"
  exit 2;
fi

do_menu
# Fim do Programa
