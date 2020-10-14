#!/bin/bash
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
clear
myhome=""
erros=0
logfile="/tmp/iso_com_erros.txt"
unset lista
[ -d "/home/gladiston/Downloads/pierre" ] && myhome="/home/gladiston/Downloads/pierre"
[ -d "/home/wwwvidy/html/data/downloads" ] && myhome="/home/wwwvidy/html/data/downloads"
if  [ "$myhome" == "" ] ; then 
  echo "Pasta de download de arquivos não foi encontrada."
  exit 2
fi
tmpfile=`mktemp`
#tmpfile="/tmp/teste.txt"
cd "$myhome"
echo "---------------------------------------------------------------"
echo "conferindo se todos os arquivos de iso tem sua referencia .dat "
echo "---------------------------------------------------------------"
touch $logfile
formatos_iso="pdf doc docx xls xlsx ods odt"
for extensao in $formatos_iso ; do
    # Agora completo a operação com todos estes arquivos ja renomeados
    find *.$extensao >$tmpfile
    while read filei ; do
      arquivo_ext=${filei##*.}
      arquivo_basename=`basename $filei .$arquivo_ext`
      arquivo_dat="$arquivo_basename.dat"
      arquivo_title="$arquivo_basename"
      if ! [ -f "$arquivo_dat" ] ; then
	    echo -ne "\nArquivo :\n\t[$filei]\n nao tem um correspondente :\n\t[$arquivo_dat].\n"
	    echo -ne "\nArquivo :\n\t[$filei]\n nao tem um correspondente :\n\t[$arquivo_dat].\n" >>$logfile
	    lista=( "${lista[@]}" $filei )
	    erros=1
      fi
    done <$tmpfile
done

echo "---------------------------------------------------------"
echo "conferindo se todos os arquivos .dat tem seu link correto"
echo "---------------------------------------------------------"
find *.dat >$tmpfile
while read filei ; do
  arquivo_title=`sed '1q;d' "$filei"`
  arquivo_bin=`sed '2q;d' "$filei"`
  arquivo_erro=0
  se_url=0

  # sera que é uma uri/url ?
  [[ "$arquivo_bin" == *"://"* ]] && se_url=1

  # Se nao for link, sera que aponta para o arquivo correto ?
  if [ "$se_url" -eq 0 ] ; then 
    ! [ -f "$arquivo_bin" ] && arquivo_erro=1
    if [ $arquivo_erro -gt 0 ] ; then
      echo -ne "\nArquivo :\n\t[$filei]\nAponta para um arquivo que não existe :\n\t[$arquivo_bin].\n"
      lista=( "${lista[@]}" $filei )
      erros=1
    fi 
  fi
done <$tmpfile
rm -f $tmpfile
if [ $erros -eq 0 ] ; then
  echo "Nenhum erro encontrado."
else
  echo "Lista de arquivos com erros :"
  for arq in "${lista[@]}" ; do
    echo -ne "\t$arq\n"
    echo -ne "\t$arq\n" >>$logfile
  done
  echo "Uma lista foi criado com esses nomes e salva no arquivo $logfile."
fi
