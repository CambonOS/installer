#!/bin/bash

NOCOLOR='\033[0m'
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'

ERROR () {
  echo -e "${RED}ERROR${NOCOLOR}"
  exit
}

DONE () {
  echo -e "${GREEN}DONE${NOCOLOR}"
  sleep 1
}
case $1 in
	upgrade)
		if [ $2 = '-b' ]
		then
			echo -e "${BLUE}\n>>Actualizando comandos de CambonOS${NOCOLOR}"
			cd /tmp; sudo rm -rf Arch-Distro >/tmp/Salida.txt 2>&1
			git clone -b $3 https://github.com/CambonOS/Arch-Distro >>/tmp/Salida.txt 2>&1
			cd Arch-Distro
			sudo cp ./cambonos-iso.sh /usr/bin/cambonos-iso || ERROR
			sudo chmod 755 /usr/bin/cambonos-iso || ERROR
			sudo cp ./cambonos.sh /usr/bin/cambonos || ERROR
			sudo chmod 755 /usr/bin/cambonos || ERROR
			DONE
		else
			echo -e "${BLUE}\n>>Actualizando comandos de CambonOS${NOCOLOR}"
			cd /tmp; sudo rm -rf Arch-Distro >/tmp/Salida.txt 2>&1
			git clone https://github.com/CambonOS/Arch-Distro >>/tmp/Salida.txt 2>&1
			cd Arch-Distro
			sudo cp ./cambonos-iso.sh /usr/bin/cambonos-iso || ERROR
			sudo chmod 755 /usr/bin/cambonos-iso || ERROR
			sudo cp ./cambonos.sh /usr/bin/cambonos || ERROR
			sudo chmod 755 /usr/bin/cambonos || ERROR
			DONE
			echo -e "${BLUE}\n>>Actualizando paquetes${NOCOLOR}"
			sleep 3
			trizen -Syyu || ERROR
			DONE
			echo -e "${BLUE}\n>>Actualizando GRUB${NOCOLOR}"
			sudo grub-mkconfig -o /boot/grub/grub.cfg >>/tmp/Salida.txt 2>&1 || ERROR
			DONE
		fi
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
				echo -e "${BLUE}\n>>Clonando repositorio CambonOS/Arch-Distro${NOCOLOR}"
				rm -rf Arch-Distro >/tmp/Salida.txt 2>&1
				git clone -b $2 https://github.com/CambonOS/Arch-Distro.git >>/tmp/Salida.txt 2>&1 || ERROR
				;;
			--branch)
				echo -e "${BLUE}\n>>Clonando repositorio CambonOS/Arch-Distro${NOCOLOR}"
				rm -rf Arch-Distro >/tmp/Salida.txt 2>&1
				git clone -b $2 https://github.com/CambonOS/Arch-Distro.git >>/tmp/Salida.txt 2>&1 || ERROR
				;;
			*)
				echo -e "${BLUE}\n>>Clonando repositorio CambonOS/Arch-Distro${NOCOLOR}"
				rm -rf Arch-Distro >/tmp/Salida.txt 2>&1
				git clone https://github.com/CambonOS/Arch-Distro.git >>/tmp/Salida.txt 2>&1 || ERROR
				;;
		esac
		DONE
		;;
	*)
		echo -e "${RED}Opción ${BLUE}$1${RED} no reconocida.${NOCOLOR}"
		;;
esac
