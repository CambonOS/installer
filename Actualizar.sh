#!/bin/bash

# COLORES
NOCOLOR='\033[0m'
BLUE='\033[1;34m'
RED='\033[1;31m'
GREEN='\033[0;32m'

# PROGRAMA
sudo clear
echo -e "${BLUE}******* ACTUALIZAR SISTEMA *******${NOCOLOR}"
echo -e "${BLUE}\n>>Actualizando paquetes${NOCOLOR}"
(trizen -Syyu --noconfirm >/dev/null && echo -e "${GREEN}DONE${NOCOLOR}") || echo -e "${RED}ERROR${NOCOLOR}"
echo -e "${BLUE}\n>>Listando paquetes guerfanos...${NOCOLOR}"
trizen -Qqdt
echo -e "${BLUE}\n>>Desistalando paquetes guerfanos${NOCOLOR}"
trizen -Rns $(trizen -Qqdt) --noconfirm >/dev/null 2>&1; echo -e "${GREEN}DONE${NOCOLOR}"
echo -e "${BLUE}\n>>Actualizando GRUB${NOCOLOR}"
(sudo grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1 && echo -e "${GREEN}DONE${NOCOLOR}") || echo -e "${RED}ERROR${NOCOLOR}"
echo -e "${GREEN}******* SISTEMA ACTUALIZADO *******${NOCOLOR}"
