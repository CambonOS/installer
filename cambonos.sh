#!/bin/bash

NOCOLOR='\033[0m'
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'

ERROR () {
  echo -e "${RED}ERROR${NOCOLOR}"
  rm -rf /ISO >>/tmp/Salida.txt 2>&1
  exit
}

DONE () {
  echo -e "${GREEN}DONE${NOCOLOR}"
  sleep 1
}
sudo rm -f /tmp/Salida.txt
case $1 in
	-h)
		echo -e "\n${BLUE}>>Comando: cambonos [OPTION]${NOCOLOR}
	[OPTIONS]
	${BLUE}-h${NOCOLOR}		Muestra esta ayuda
	${BLUE}upgrade${NOCOLOR}		Actualiza tanto los paquetes de pacman como de AUR
			ademas de actualizar el script cambonos
	${BLUE}install${NOCOLOR}		Instala paquetes tanto de pacman como de AUR
	${BLUE}list${NOCOLOR}		Lista los paquetes instalados incluyendo paquetes de AUR
	${BLUE}search${NOCOLOR}		Busca un paquete en los repositorios oficiales y en AUR
	${BLUE}remove${NOCOLOR}		Elimina paquetes instalados
	${BLUE}autoremove${NOCOLOR}	Elimina los paquetes que han sido instalados automaticamento
			como dependencias y no son necesarios
	${BLUE}clone${NOCOLOR}		Clona el repositorio de CambonOS
	${BLUE}mkiso${NOCOLOR}		Crea una ISO de instalacion de CambonOS"
		;;
	--help)
		echo -e "\n${BLUE}>>Comando: cambonos [OPTION]${NOCOLOR}
	[OPTIONS]
	${BLUE}-h${NOCOLOR}		Muestra esta ayuda
	${BLUE}upgrade${NOCOLOR}		Actualiza tanto los paquetes de pacman como de AUR
			ademas de actualizar el script cambonos
	${BLUE}install${NOCOLOR}		Instala paquetes tanto de pacman como de AUR
	${BLUE}list${NOCOLOR}		Lista los paquetes instalados incluyendo paquetes de AUR
	${BLUE}search${NOCOLOR}		Busca un paquete en los repositorios oficiales y en AUR
	${BLUE}remove${NOCOLOR}		Elimina paquetes instalados
	${BLUE}autoremove${NOCOLOR}	Elimina los paquetes que han sido instalados automaticamento
			como dependencias y no son necesarios
	${BLUE}clone${NOCOLOR}		Clona el repositorio de CambonOS
	${BLUE}mkiso${NOCOLOR}		Crea una ISO de instalacion de CambonOS"
		;;
	upgrade)
		sudo rm -rf /tmp/arch-distro
		case $2 in
			-b)
				echo -e "${BLUE}>>Actualizando comandos de CambonOS${NOCOLOR}"
				sleep 2
				cd /tmp
				git clone -b $3 https://github.com/CambonOS/arch-distro
				cd arch-distro
				sudo cp ./cambonos.sh /usr/bin/cambonos || ERROR
				sudo chmod 755 /usr/bin/cambonos || ERROR
				DONE
				;;
			--branch)
				echo -e "${BLUE}>>Actualizando comandos de CambonOS${NOCOLOR}"
				sleep 2
				cd /tmp
				git clone -b $3 https://github.com/CambonOS/arch-distro
				cd arch-distro
				sudo cp ./cambonos.sh /usr/bin/cambonos || ERROR
				sudo chmod 755 /usr/bin/cambonos || ERROR
				DONE
				;;
			*)
				echo -e "${BLUE}>>Actualizando comandos de CambonOS${NOCOLOR}"
				sleep 2
				cd /tmp
				git clone https://github.com/CambonOS/arch-distro
				cd arch-distro
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
	mkiso)
		if [[ $EUID -ne 0 ]]
		then
			echo -e "${RED}Debese ejecutar como usuario con privilejios${NOCOLOR}"
			exit
		fi
		echo -e "\n>>Carpeta destino ISO:\c"
		sleep 2
		read -e -i $(pwd) RUTAD

		echo -e "\n>>Instalando paquetes necesarios"
		sleep 2
		pacman --noconfirm -Sy archiso >/tmp/Salida.txt 2>&1 && DONE || ERROR

		echo -e "\n>>Descargando el script de instalacion"
		sleep 2
		rm -rf /tmp/arch-distro >>/tmp/Salida.txt 2>&1
		case $1 in
			-b)
				cd /tmp && git clone -b $2 https://github.com/CambonOS/arch-distro.git >>/tmp/Salida.txt 2>&1 && DONE |${NOCOLOR}| ERROR
				;;
			--branch)
				cd /tmp && git clone -b $2 https://github.com/CambonOS/arch-distro.git >>/tmp/Salida.txt 2>&1 && DONE |${NOCOLOR}| ERROR
				;;
			*)
				cd /tmp && git clone https://github.com/CambonOS/arch-distro.git >>/tmp/Salida.txt 2>&1 && DONE || ERROR
				;;
		esac

		echo -e "\n>>Creando ficheros de configuracion de la ISO"
		sleep 2
		mkdir /ISO && cp -r /usr/share/archiso/configs/releng /ISO/porfile || ERROR
		mv /tmp/arch-distro/cambonos-install.sh /ISO/porfile/airootfs/usr/local/bin/cambonos-install || ERROR
		echo 'chmod 777 /usr/local/bin/cambonos-install;VERDE="\033[1;32m";NOCOLOR="\033[0m";AZUL="\033[1;34m";echo -e "\n  Para instalar ${AZUL}CambonOS${NOCOLOR} ejecute el comando ${VERDE}cambonos-install${NOCOLOR}\n"' >>/ISO/porfile/airootfs/root/.zshrc
		echo -e "camboniso" >/ISO/porfile/airootfs/etc/hostname
		echo -e "KEYMAP=es" >/ISO/porfile/airootfs/etc/vconsole.conf
		cp -r /tmp/arch-distro/iso/* /ISO/porfile/ || ERROR
		rm /ISO/porfile/syslinux/splash.png
		rm /ISO/porfile/efiboot/loader/entries/archiso-x86_64-speech-linux.conf
		DONE

		echo -e "\n>>Creando la ISO"
		sleep 2
		mkarchiso -v -w /ISO/work -o $RUTAD /ISO/porfile && DONE || ERROR

		echo -e "\n>>Eliminado ficheros/paquetes innecesarios"
		sleep 2
		rm -rf /ISO
		pacman --noconfirm -Rns archiso >>/tmp/Salida.txt 2>&1
		DONE
		;;
	*)
		echo -e "${RED}Opción ${BLUE}$1${RED} no reconocida. Para obtener ayuda ${BLUE}cambonos -h${NOCOLOR}"
		sleep 2
		;;
esac
