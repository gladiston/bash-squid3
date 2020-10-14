#!/bin/bash 
# Coloque este arquivo como /etc/init.d/after-boot.sh 
# Depois crie o seguinte Symlink : 
# ln -s /etc/init.d/after-boot.sh /etc/rc2.d/S96after-boot 
echo "carregando firewall especifico para este servidor." 
#/home/administrador/fw-scripts/firewall.sh 
