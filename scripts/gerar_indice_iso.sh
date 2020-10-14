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
logfile="/tmp/iso_com_erros.txt"
unset lista
[ -d "/home/gladiston/Downloads/pierre" ] && myhome="/home/gladiston/Downloads/pierre"
[ -d "$SGQ_DOWNLOADS" ] && myhome="$SGQ_DOWNLOADS"
if  [ "$myhome" == "" ] ; then 
  echo "Pasta de download de arquivos não foi encontrada."
  exit 2
fi
cd "$myhome"
tmpfile=`mktemp`
formatos_iso="$SGQ_FORMATOS"
echo "---------------------------------------------------"
echo "criando indices para arquivos no formato : $formatos_iso"
for extensao in $formatos_iso ; do
  count=`find *.$extensao 2>/dev/null|wc -l`
  if [ "$count" -gt 0 ] ; then
    find *.$extensao >$tmpfile
    # Primeiro renomeio todos os arquivos removendo os espacos e colocando-os em minusculo
    while read filei ; do
      fileo=`expr "xxx$filei" : 'xxx\(.*\)'|tr '[A-Z]' '[a-z]'|tr ' ' '_'`
      if [ "$filei" != "$fileo" ] ; then
         mv "$filei" "$fileo"
      fi
    done <$tmpfile
    # Agora completo a operação com todos estes arquivos ja renomeados
    find *.$extensao >$tmpfile
    while read filei ; do      
      arquivo_ext=${filei##*.}
      arquivo_basename=`basename $filei .$arquivo_ext`
      arquivo_dat="$arquivo_basename.dat"
      arquivo_title="$arquivo_basename"
      replace=1
      # Se o .dat ja existir, ele manterá desde que tenha um titulo maior
      # que 5 caracteres e seja diferente do padrao estabelecido pelo
      # script (teste.pdf gera teste.dat entao titulo=teste)
      if [ -f "$arquivo_dat" ] ; then
         dat_title=`sed '1q;d' "$arquivo_dat"`
         dat_bin=`sed '2q;d' "$filei"`
         [ "$dat_title" == "" ] && dat_title="$arquivo_title"
         [ "$arquivo_title" != "$dat_title" ] && arquivo_title="$dat_title"
         title_length=`expr length "$dat_title"`
         [ "$title_length" -lt 5 ] && arquivo_title="$dat_title"
      fi
      if [ "$replace" -gt 0 ] ; then
        echo "criando arquivo $arquivo_dat para o correlato $filei..."
        echo "$arquivo_title" >$arquivo_dat      
        echo "$filei" >>$arquivo_dat
      fi 
    done <$tmpfile
  fi
done
rm -f $tmpfile
chown -R www-data.www-data "$SGQ_DOWNLOADS/"
echo "---------------------------------------------------"
echo "fim"
