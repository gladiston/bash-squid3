#!/bin/bash


do_add_user()
{
 clear;
 invalid_char="\`!@#%*()-_=+~{}[]|\;:<>,.?/'"
 invalid_char="${invalid_char}\\\&"
 invalid_char="${invalid_char}\""
 invalid_char="${invalid_char}\$"
 invalid_char="${invalid_char}\^"

 echo -n "Entre o nome do login para acesso externo : "
 read novo_login
 if [ "$novo_login" = "" ] ; then
   echo "operacao cancelada !"
   press_enter_to_continue
   do_menu;
 fi;

 # Checando se o login ja nao existe
 login_existe=`cat $EXTRANET_USERS_FILE |grep $novo_login`
 if [ "$login_existe" != "" ] ; then
   echo "A entrada para esse login ja existe :"
   echo $login_existe
   if ! do_confirmar "Deseja continuar ?" ; then
     echo "Operacao cancelada !"
     press_enter_to_continue
     do_menu
   fi;
 fi;

 if ! do_confirmar "Criar o login [$novo_login] ?" ; then
   echo "Operacao cancelada !"
   press_enter_to_continue
   do_menu
 fi;

# Buscando uma senha provisoriai
 senha=`/usr/bin/apg -ML -a0 -n1 -t -x8 -l -E "$invalid_char"`
 nova_senha=`echo "$senha"|cut -f1 -d " "`

 # Cadastrando novo usuario
 htpasswd -b "$EXTRANET_USERS_FILE" "$novo_login" "$nova_senha"
 if [ $? -ne 0 ] ; then
    echo "Criacao da conta de acesso externo falhou !"
    press_enter_to_continue
    do_menu;
 else
   echo "Login criado com sucesso !!!"
   echo "Anote a senha para este usuario :"
   echo "======================="
   echo $senha
   echo "======================="   
   press_enter_to_continue
 fi;

}

do_change_password()
{
 clear;
 echo -n "Entre o nome da conta externa que tera a senha alterada : "
 read meu_login
 if [ "$meu_login" = "" ] ; then
   echo "operacao cancelada !"
   press_enter_to_continue
   do_menu;
 fi;

 # Checando se o login realmente existe
 login_existe=`cat "$EXTRANET_USERS_FILE" |grep $meu_login`
 if [ "$login_existe" = "" ] ; then
   echo "Essa conta nao existe !"
   press_enter_to_continue
   do_menu
 fi;

 echo "Digite uma nova senha para a conta $meu_login :"
 read nova_senha1
 echo "Repita novamente a nova senha para a conta $meu_login :"
 read nova_senha2
 if [ "$nova_senha1" != "$nova_senha2" ] ; then
    echo "Mudanca de senha falhou !"
    echo "As senhas digitadas eram diferentes!"
    press_enter_to_continue
    do_menu;
 fi
 
 #sudo passwd $meu_login
 htpasswd -b "$EXTRANET_USERS_FILE" "$meu_login" "$nova_senha1"
 
 if [ $? -ne 0 ] ; then
   echo "Mudanca de senha falhou !"
   press_enter_to_continue
 else
   echo "Mudanca de senha realizada com sucesso !!!"
   press_enter_to_continue
 fi;

}

do_del_user()
{
 clear;
 echo -n "Entre o nome da conta que deseja excluir : "
 read account
 if [ "$account" = "" ] ; then
   echo "operacao cancelada !"
   press_enter_to_continue
   do_menu;
 fi;

 # Checando se o login realmente existe
 login_existe=`cat "$EXTRANET_USERS_FILE" |grep $account`
 if [ "$login_existe" = "" ] ; then
   echo "Essa conta nao existe !"
   press_enter_to_continue
   do_menu
 fi;
 if ! do_confirmar "Deseja excluir a conta [$account] ?" ; then
   echo "Operacao cancelada !"
   press_enter_to_continue
   do_menu
 fi;

 # apagando login existente com todo o seu conteudo
 htpasswd -D "$EXTRANET_USERS_FILE" "$account"

 if [ $? -ne 0 ] ; then
   echo "A exclusao da conta [$account] falhou !"
   press_enter_to_continue
   do_menu;
 else
   echo "Conta [$account] foi excluida com sucesso!"
   press_enter_to_continue
 fi
}

function do_list_users() { 
  nano -v "$EXTRANET_USERS_FILE"
}

function do_list_mail_users() { 
  nano -v "/home/administrador/google-mail/emails_senhas.csv"
}

do_menu()
{
  clear
  while :
  do
    clear
    clear
    echo "-------------------------------------------------------------"
    echo "               M E N U  P A R A  E X T R A N E T             "
    echo "-------------------------------------------------------------"
    echo "1- Adicionar novas contas"
    echo "2- Mudar a senha de uma conta"
    echo "3- Remover contas"
    echo "4- Listar todos as contas existentes"
    echo "5- Listar contas de emails criadas"
    echo "99- Sair"
    echo -n "Escolha uma opcao [1-99] :"
    read opcao
    case $opcao in
    1) do_add_user;;
    2) do_change_password;;
    3) do_del_user;;
    4) do_list_users;;
    5) do_list_mail_users;;
    99) exit;;
    esac
  done;
}
 

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

if ! [ -f /usr/bin/apg ] ; then
  echo "falta o aplicativo /usr/bin/apg"
  press_enter_to_continue
  exit 2;
fi

EXTRANET_USERS_FILE="/etc/apache2/senhas/htpasswd"
TEMP=`dirname "$EXTRANET_USERS_FILE"`

if ! [ -d "$TEMP" ] ; then
  mkdir -p "$TEMP"
  touch "$EXTRANET_USERS_FILE"
  chown administrador.www-data "$EXTRANET_USERS_FILE"
fi


do_menu
# Fim do Programa
