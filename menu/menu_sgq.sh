#!/bin/bash 

function pega_nome_arquivo () {
  echo "Digite ou cole a url onde se encontra a publicação que pretende editar:"
  echo "Ou apenas [.] para sair."
  echo -ne "URI->"
  while true ; do
    read pega_nome_arquivo
    [ "$pega_nome_arquivo" = "." ] && break
    if  [[ "$pega_nome_arquivo" == *"://"* ]] ; then
      pega_nome_arquivo=`echo "$pega_nome_arquivo" |cut -d"=" -f4`
    fi
    [ -f "$SGQ_DOWNLOADS/$pega_nome_arquivo.dat" ] && pega_nome_arquivo="$SGQ_DOWNLOADS/$pega_nome_arquivo.dat"
    [ -f "$SGQ_DOWNLOADS/$pega_nome_arquivo" ] && pega_nome_arquivo="$SGQ_DOWNLOADS/$pega_nome_arquivo"
    [ -f "$pega_nome_arquivo" ] && break
    if [ -f "$pega_nome_arquivo" ] ; then
      break
    else
      echo "Parece que este arquivo não existe :"
      echo -ne "\t$pega_nome_arquivo\n"
      echo "Tente outra vez ou digite [.] para sair:"
      echo -ne "URI->"
    fi
  done
}

function editar_dat() {
  clear
  pega_nome_arquivo
  arquivo="$pega_nome_arquivo"

  if [ "$arquivo" = "." ]; then
    echo "A operação foi cancelada." ;
    echo "tecle [ENTER] para prosseguir." ;
    press_enter_to_continue;
    return
  fi

  editar "$arquivo"

  echo "tecle [ENTER] para prosseguir." ;
  press_enter_to_continue;
}

function pegar_isos() {
  clear
  echo "Vou integrar os arquivos em \\\\obelix\\pub\\isos ao Sistema de Gestao de Qualidade VIDY 9001."
  echo "Contudo, se houverem revisões novas, o sistema não eliminará as antigas que deverão ser eliminadas manualmente."
  do_confirmar "Confirma publicá-los? (sim ou nao)"
  if [[ $? -gt 0 ]] ; then
    echo "A operação foi cancelada." ;
    echo "tecle [ENTER] para prosseguir." ;
    press_enter_to_continue;
    return
  fi

  "$SCRIPTS/pegar_sgq.sh" --pause;

  echo "Processo completo, tecle [ENTER] para retornar ao menu." ;
  press_enter_to_continue;

}

function remover_isos() {
  clear
  pega_nome_arquivo
  arquivo="$pega_nome_arquivo"
  [ "$arquivo" = "." ] && return

  arquivo_title=`sed '1q;d' "$arquivo"`
  arquivo_bin=`sed '2q;d' "$arquivo"`
  
  echo "A publicação a ser eliminada :"
  echo -e "\tTitulo=$arquivo_title"
  echo -e "\tArquivo=$arquivo_bin"
  do_confirmar "Confirma a eliminação ? (sim ou nao)"
  if [[ $? -eq 0 ]]; then 
    rm -f "$arquivo"
    rm -f "$arquivo_bin"
  fi
  echo "tecle [ENTER] para prosseguir." ;
  press_enter_to_continue;
}


function do_menu()
{
  clear
  while :
  do
    clear
    echo "-------------------------------------------------------------"
    echo "      Sistema de Gestao de Qualidade VIDY 9001"
    echo "-------------------------------------------------------------"
    echo "1 - Editar o titulo de uma publicacao"
    echo "2 - Conferir erros de indice"
    echo "3 - Corrigir erros de indice"
    echo "4 - Publicar arquivos em \\\\obelix\\pub\\isos"
    echo "5 - Remover publicaçoes"
    echo "99- Sair"
    echo -n "Escolha uma opcao [1-99] :"
    read opcao
    case $opcao in
    1) editar_dat ;; 
    2)"$SCRIPTS/confere_indice_iso.sh";
      echo "tecle [ENTER] para prosseguir." ;
      press_enter_to_continue;;
    3)"$SCRIPTS/gerar_indice_iso.sh";
      echo "tecle [ENTER] para prosseguir." ;
      press_enter_to_continue;;
    4) pegar_isos ;; 
    5) remover_isos ;; 
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
