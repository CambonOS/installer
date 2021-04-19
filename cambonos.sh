#!/bin/bash

NOCOLOR='\033[0m'
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'

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
		echo -e ">>Actualizando GRUB\c"
		sudo grub-mkconfig -o /boot/grub/grub.cfg >>/tmp/Salida.txt 2>&1 || ERROR
		DONE
		;;
	install)
		shift
		trizen -Sy $* || ERROR
		DONE
		;;
	list)
		shift
		trizen -Q $*
		;;
	search)
		shift
		trizen -Ss $*
		;;
	remove)
		shift
		trizen -Rns $* || ERROR
		DONE
		;;
	autoremove)
		trizen -Rns $(trizen -Qqdt)
		DONE
		;;
	clone)
		shift
		case $1 in
			-b)
				rm -rf Arch-Distro >/tmp/Salida.txt 2>&1
				git clone -b $2 https://github.com/CambonOS/Arch-Distro.git || ERROR
				;;
			--branch)
				rm -rf Arch-Distro >/tmp/Salida.txt 2>&1
				git clone -b $2 https://github.com/CambonOS/Arch-Distro.git || ERROR
				;;
			*)
				rm -rf Arch-Distro >/tmp/Salida.txt 2>&1
				git clone https://github.com/CambonOS/Arch-Distro.git || ERROR
				;;
		esac
		DONE
		;;
	*)
		echo -e "${RED}Opción ${BLUE}$1${RED} no reconocida.${NOCOLOR}"
		;;
esac
