#!/bin/bash

NOCOLOR='\033[0m'
RED='\033[1;31m'
GREEN='\033[1;32m'

ERROR () {
  echo -e "${RED} ERROR ${NOCOLOR}"
  exit
}

DONE () {
  echo -e "${GREEN} DONE ${NOCOLOR}"
  sleep 1
}

sudo clear
echo -e "******* ACTUALIZAR SISTEMA *******"

echo -e "\n>>Actualizando paquetes\c"
trizen -Syyu --noconfirm >/tmp/Salida.txt 2>&1 || ERROR
DONE

echo -e "\n>>Listando paquetes guerfanos...\c"
trizen -Qqdt

echo -e "\n>>Desistalando paquetes guerfanos\c"
trizen -Rns $(trizen -Qqdt) --noconfirm >>/tmp/Salida.txt 2>&1 || ERROR
DONE

echo -e "\n>>Actualizando GRUB\c"
sudo grub-mkconfig -o /boot/grub/grub.cfg >>/tmp/Salida.txt 2>&1 || ERROR
DONE

echo -e "\n>>Estos paquetes no son necesarios para el sistema:"
trizen -Qqet

echo -e "******* SISTEMA ACTUALIZADO *******"
