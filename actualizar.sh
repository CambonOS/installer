#!/bin/bash

NOCOLOR='\033[0m'
RED='\033[1;31m'
GREEN='\033[1;32m'

ERROR () {
  echo -e "${RED} ERROR ${NOCOLOR}"
}

DONE () {
  echo -e "${GREEN} DONE ${NOCOLOR}"
}

clear
echo -e "******* ACTUALIZAR SISTEMA *******"

echo -e "\n>>Actualizando paquetes\c"
trizen -Syyu --noconfirm >/dev/null || ERROR
DONE

echo -e "\n>>Listando paquetes guerfanos...\c"
trizen -Qqdt

echo -e "\n>>Desistalando paquetes guerfanos\c"
trizen -Rns $(trizen -Qqdt) --noconfirm >/dev/null 2>&1 || ERROR
DONE

echo -e "\n>>Actualizando GRUB\c"
sudo grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1 || ERROR
DONE

echo -e "******* SISTEMA ACTUALIZADO *******"
