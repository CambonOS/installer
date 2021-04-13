#!/bin/bash

ERROR () {
  echo -e "${\033[1;31m} ERROR ${\033[0m}"
}

DONE () {
  echo -e "${\033[0;32m} ERROR ${\033[0m}"
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
