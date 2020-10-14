#!/bin/bash 
# Este programa pela os arquivos no formato ISO que estao em
# \\obelix\pub\isos
# e os coloca disponiveis para download na Intranet na seção SGQ
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

usepause=0
formatos_iso="dat $SGQ_FORMATOS"
agente_user="agente_backup"
agente_pass="vidy123"
agente_dom="vidy.local"
ponto_smb="//obelix/pub"
ponto_local="/mnt/pub"
[ "$1" == "--pause" ] && usepause=1

do_montar_cifs "$ponto_smb" "$ponto_local"
if [ "$RESULT_VALUE" != "OK" ] ; then
  echo "Não foi possivel montar a unidade de origem [$ponto_smb] em [$ponto_local] "
  do_desmontar "$ponto_local"
  return
fi

clear
max_count=0
echo "Procurando pelos formatos : $formatos_iso"
for extensao in $formatos_iso ; do
  find "$ponto_local/isos/" -name "*.$extensao" -printf "%f\n" 2>/dev/null
  count=`find "$ponto_local/isos/" -name "*.$extensao" 2>/dev/null|wc -l`
  max_count=`expr $max_count + $count`
done

if [ "$max_count" -eq 0 ] ; then
  do_desmontar "$ponto_local"
  echo "A pasta [$ponto_smb/isos] não contém arquivos nos formatos SGQ($formatos_iso)."
  echo "O sistema busca as publicações em :"
  echo -ne "\tServidor Obelix->Compartilhamento PUB->Pasta ISOS\n"
  echo -ne "\t(\\\\obelix\\pub\\isos)\n"
  echo -ne "Voce precisa criar esta pasta/compartilhamento e dar permissoes para o usuario [agente_backup]."
  echo "tecle [ENTER] para prosseguir." ;
  [ "$usepause" -gt 0 ] && press_enter_to_continue;
  return
fi 

echo "Vou integrar os arquivos acima ao Sistema de Gestao de Qualidade VIDY 9001."
echo "Contudo, se houverem revisões novas, o sistema não eliminará as antigas que deverão ser eliminadas manualmente."
do_confirmar "Confirma publicá-los? (sim ou nao)"
if [[ $? -gt 0 ]] ; then
  do_desmontar "$ponto_local"
  echo "A operação foi cancelada." ;
  echo "tecle [ENTER] para prosseguir." ;
  [ "$usepause" -gt 0 ] && press_enter_to_continue;
  return
fi

echo "---------------------------------------------------"
echo "copiando arquivos no formato : $formatos_iso para $SGQ_DOWNLOADS"
for extensao in $formatos_iso ; do
  mv -vf $ponto_local/isos/*.$extensao $SGQ_DOWNLOADS/ 2>/dev/null
done
echo "---------------------------------------------------"
do_desmontar "$ponto_local"
#echo "tecle [ENTER] para prosseguir com a geração de novos indices." ;
#[ "$usepause" -gt 0 ] && press_enter_to_continue;

"$SCRIPTS/gerar_indice_iso.sh";

echo "Processo concluido." ;
# Fim do Programa
