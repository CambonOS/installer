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
	-h)
		echo -e "\n${BLUE}>>Comando: cambonos [OPTION]${NOCOLOR}
		\n\n		[OPTIONS]
		\n		${BLUE}-h${NOCOLOR}			Muestra esta ayuda
		\n		${BLUE}upgrade${NOCOLOR}			Actualiza tanto los paquetes de pacman como de AUR ademas de actualizar el script cambonos
		\n		${BLUE}install${NOCOLOR}			Instala paquetes tanto de pacman como de AUR
		\n		${BLUE}list${NOCOLOR}			Lista los paquetes instalados incluyendo paquetes de AUR
		\n		${BLUE}search${NOCOLOR}			Busca un paquete en los repositorios oficiales y en AUR
		\n		${BLUE}remove${NOCOLOR}			Elimina paquetes instalados
		\n		${BLUE}autoremove${NOCOLOR}			Elimina los paquetes que han sido instalados automaticamento como dependencias y no son necesarios
		\n		${BLUE}clone${NOCOLOR}			Clona el repositorio de CambonOS"
		;;
	--help)
		echo -e "\n${BLUE}>>Comando: cambonos [OPTION]${NOCOLOR}
		\n\n		[OPTIONS]
		\n		${BLUE}-h${NOCOLOR}			Muestra esta ayuda
		\n		${BLUE}upgrade${NOCOLOR}			Actualiza tanto los paquetes de pacman como de AUR ademas de actualizar el script cambonos
		\n		${BLUE}install${NOCOLOR}			Instala paquetes tanto de pacman como de AUR
		\n		${BLUE}list${NOCOLOR}			Lista los paquetes instalados incluyendo paquetes de AUR
		\n		${BLUE}search${NOCOLOR}			Busca un paquete en los repositorios oficiales y en AUR
		\n		${BLUE}remove${NOCOLOR}			Elimina paquetes instalados
		\n		${BLUE}autoremove${NOCOLOR}			Elimina los paquetes que han sido instalados automaticamento como dependencias y no son necesarios
		\n		${BLUE}clone${NOCOLOR}			Clona el repositorio de CambonOS"
		;;
	upgrade)
		case $2 in
			-b)
				echo -e "${BLUE}>>Actualizando comandos de CambonOS${NOCOLOR}"
				sleep 2
				cd /tmp; sudo rm -rf Arch-Distro >/tmp/Salida.txt 2>&1
				git clone -b $3 https://github.com/CambonOS/Arch-Distro
				cd Arch-Distro
				sudo cp ./cambonos-iso.sh /usr/bin/cambonos-iso || ERROR
				sudo chmod 755 /usr/bin/cambonos-iso || ERROR
				sudo cp ./cambonos.sh /usr/bin/cambonos || ERROR
				sudo chmod 755 /usr/bin/cambonos || ERROR
				DONE
				;;
			--branch)
				echo -e "${BLUE}>>Actualizando comandos de CambonOS${NOCOLOR}"
				sleep 2
				cd /tmp; sudo rm -rf Arch-Distro >/tmp/Salida.txt 2>&1
				git clone -b $3 https://github.com/CambonOS/Arch-Distro
				cd Arch-Distro
				sudo cp ./cambonos-iso.sh /usr/bin/cambonos-iso || ERROR
				sudo chmod 755 /usr/bin/cambonos-iso || ERROR
				sudo cp ./cambonos.sh /usr/bin/cambonos || ERROR
				sudo chmod 755 /usr/bin/cambonos || ERROR
				DONE
				;;
			*)
				echo -e "${BLUE}>>Actualizando comandos de CambonOS${NOCOLOR}"
				sleep 2
				cd /tmp; sudo rm -rf Arch-Distro >/tmp/Salida.txt 2>&1
				git clone https://github.com/CambonOS/Arch-Distro
				cd Arch-Distro
				sudo cp ./cambonos-iso.sh /usr/bin/cambonos-iso || ERROR
				sudo chmod 755 /usr/bin/cambonos-iso || ERROR
				sudo cp ./cambonos.sh /usr/bin/cambonos || ERROR
				sudo chmod 755 /usr/bin/cambonos || ERROR
				DONE
				echo -e "${BLUE}\n>>Actualizando paquetes${NOCOLOR}"
				sleep 2
				trizen -Syyu || ERROR
				DONE
				echo -e "${BLUE}\n>>Actualizando GRUB${NOCOLOR}"
				sleep 2
				sudo grub-mkconfig -o /boot/grub/grub.cfg || ERROR
				DONE
				;;
		esac
		;;
	install)
		echo -e "${BLUE}>>Instalando paquetes${NOCOLOR}"
		sleep 2
		shift
		trizen -Sy $* || ERROR
		DONE
		;;
	list)
		echo -e "${BLUE}>>Listando paquetes instalados${NOCOLOR}"
		sleep 2
		shift
		trizen -Q $*
		;;
	search)
		echo -e "${BLUE}>>Buscando paquetes${NOCOLOR}"
		sleep 2
		shift
		trizen -Ss $*
		;;
	remove)
		echo -e "${BLUE}>>Eliminando paquetes${NOCOLOR}"
		sleep 2
		shift
		trizen -Rns $* || ERROR
		DONE
		;;
	autoremove)
		echo -e "${BLUE}>>Eliminando paquetes guerfanos${NOCOLOR}"
		sleep 2
		trizen -Rns $(trizen -Qqdt)
		DONE
		;;
	clone)
		shift
		case $1 in
			-b)
				echo -e "${BLUE}>>Clonando repositorio CambonOS/Arch-Distro${NOCOLOR}"
				sleep 2
				rm -rf Arch-Distro >/tmp/Salida.txt 2>&1
				git clone -b $2 https://github.com/CambonOS/Arch-Distro.git || ERROR
				;;
			--branch)
				echo -e "${BLUE}>>Clonando repositorio CambonOS/Arch-Distro${NOCOLOR}"
				sleep 2
				rm -rf Arch-Distro >/tmp/Salida.txt 2>&1
				git clone -b $2 https://github.com/CambonOS/Arch-Distro.git || ERROR
				;;
			*)
				echo -e "${BLUE}>>Clonando repositorio CambonOS/Arch-Distro${NOCOLOR}"
				sleep 2
				rm -rf Arch-Distro >/tmp/Salida.txt 2>&1
				git clone https://github.com/CambonOS/Arch-Distro.git || ERROR
				;;
		esac
		DONE
		;;
	*)
		echo -e "${RED}Opción ${BLUE}$1${RED} no reconocida. Para obtener ayuda ${BLUE}cambonos -h${NOCOLOR}"
		sleep 2
		;;
esac
