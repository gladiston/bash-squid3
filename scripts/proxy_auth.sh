#!/bin/bash
# Trata-se dum loop infinito que através do autenticador do squid
# pega o usuário e senha, confere e retorna OK ou ERR
#auth_param basic program /usr/bin/bash "/home/administrador/scripts/proxy_auth.sh" ou
#auth_param basic program /home/administrador/scripts/proxy_auth.sh 
#auth_param basic children 2
#auth_param basic realm Autenticacao via Bash 
#auth_param basic credentialsttl 5 hours
FILE_LOG="/tmp/squid-auth.log"
#[ -f "$FILE_LOG" ] && rm -f "$FILE_LOG"

#while read -r LINE ; do
  LINE="${LINE#"${LINE%%[![:space:]]*}"}"   # remove leading whitespace characters
  LINE="${LINE%"${LINE##*[![:space:]]}"}"   # remove trailing whitespace characters
  PROXY_USERNAME=$(echo "$LINE"|cut -d' ' -f1)
  PROXY_PASSWORD=$(echo "$LINE"|cut -d' ' -f2)
  RESULT="ERR"
  
  # Ordem de autenticacao
  # NTLM
  RESULT=$(echo "$PROXY_USERNAME $PROXY_PASSWORD"|/usr/bin/ntlm_auth --helper-protocol=squid-2.5-ntlmssp --domain=VIDY --kerberos /usr/lib/squid3/squid_kerb_auth -d -s GSS_C_NO_NAME)
  echo "NTLM: ${RESULT}"  
  
  # Primeiro testa se a senha funciona no AD
  RESULT=$(echo "$PROXY_USERNAME $PROXY_PASSWORD"|/usr/lib/squid3/basic_ldap_auth -R -b "dc=VIDY,dc=local" -D proxy_internet@VIDY.local -W /etc/squid3/ldappass.txt -f sAMAccountName=%s -h obelix.VIDY.local)
  echo "LDAP: ${RESULT}"  
  
  if [ "RESULT=ERR" ] && [ "$PROXY_USERNAME" == "hello" ] && [ "$PROXY_PASSWORD" == "world" ] ; then
    RESULT="OK"
  fi

  # Senhas personalizadas
  if [ "RESULT=ERR" ] && [ "$PROXY_USERNAME" == "suporte" ] && [ "$PROXY_PASSWORD" == "ok" ] ; then
    RESULT="OK"
  fi

  echo "${RESULT}"
  #echo "${LINE}=${RESULT}" >>/tmp/squid-auth.log  
#done < /dev/stdin
#done < <(cat -- "$file")
exit 0;