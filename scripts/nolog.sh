#!/bin/bash
# Remover do log, os acessos dos diretores e suporte que as vezes tem
# de auditar acessos de usuarios com acesso suspeito.
sed -i '/pierre/d' /var/log/squid3/access.log*
sed -i '/sergio/d' /var/log/squid3/access.log*
sed -i '/gladiston/d' /var/log/squid3/access.log*
