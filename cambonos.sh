#!/bin/bash

NOCOLOR='\033[0m'
RED='\033[1;31m'
GREEN='\033[1;32m'

ERROR () {
  echo -e "${RED} ERROR \n${NOCOLOR}"
  exit
}

DONE () {
  echo -e "${GREEN} DONE \n${NOCOLOR}"
  sleep 1
}
case $1 in
	upgrade)
		echo -e "\n>>Actualizando paquetes\c"
		trizen -Syyu --noconfirm >/tmp/Salida.txt 2>&1 || ERROR
		DONE

		echo -e ">>Desistalando paquetes guerfanos\c"
		trizen -Rns $(trizen -Qqdt) --noconfirm >>/tmp/Salida.txt 2>&1
		DONE

		echo -e ">>Actualizando GRUB\c"
		sudo grub-mkconfig -o /boot/grub/grub.cfg >>/tmp/Salida.txt 2>&1 || ERROR
		DONE
		;;
	install)
		shift
		trizen -Sy $* || ERROR
		DONE
		;;
	remove)
		shift
		trizen -Rns $* || ERROR
		DONE
		;;
	clone)
		if [ $2 = -b ] or [ $2 = --branch]
		then
			git clone -b $3 https://github.com/CambonOS/Arch-Distro.git || ERROR
		else
			git clone https://github.com/CambonOS/Arch-Distro.git || ERROR
		fi
		DONE
		;;
	*)
		echo "${RED}Opción ${BLUE}$1${RED} no reconocida.${NOCOLOR}"
		;;
esac
