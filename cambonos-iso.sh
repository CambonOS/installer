#!/bin/bash

NOCOLOR='\033[0m'
RED='\033[1;31m'
GREEN='\033[1;32m'

ERROR () {
  echo -e "${RED} [ERROR] ${NOCOLOR}"
  rm -rf /ISO
  exit
}

DONE () {
  echo -e "${GREEN} [DONE] ${NOCOLOR}"
  sleep 1
}

sudo echo -e "\n>>Carpeta destino ISO:\c"
read -e -i $(pwd) RUTAD

echo -e "\n>>Instalando paquetes necesarios\c"
sudo pacman --noconfirm -Sy archiso >/tmp/Salida.txt 2>&1 && DONE || ERROR

echo -e "\n>>Descargando el script de instalacion"
sudo rm -rf /tmp/arch-distro >>/tmp/Salida.txt 2>&1
cd /tmp && git clone https://github.com/CambonOS/arch-distro.git && DONE || ERROR

echo -e "\n>>Creando ficheros de configuracion de la ISO\c"
sudo mkdir /ISO && sudo cp -r /usr/share/archiso/configs/releng /ISO/porfile || ERROR
sudo mv /tmp/arch-distro/cambonos-install.sh /ISO/porfile/airootfs/usr/local/bin/cambonos-install || ERROR
sudo echo 'chmod 777 /usr/local/bin/cambonos-install;VERDE="\033[1;32m";NOCOLOR="\033[0m";AZUL="\033[1;34m";echo -e "\n  Para instalar ${AZUL}CambonOS${NOCOLOR} ejecute el comando ${VERDE}cambonos-install${NOCOLOR}\n"' >>/ISO/porfile/airootfs/root/.zshrc
sudo echo -e "camboniso" >/ISO/porfile/airootfs/etc/hostname
sudo echo -e "KEYMAP=es" >/ISO/porfile/airootfs/etc/vconsole.conf
sudo cp -r /tmp/arch-distro/iso/* /ISO/porfile/ || ERROR
sudo rm /ISO/porfile/syslinux/splash.png
DONE

echo -e "\n>>Creando la ISO\n"
sudo mkarchiso -v -w /ISO/work -o $RUTAD /ISO/porfile && DONE || ERROR

echo -e "\n>>Eliminado ficheros/paquetes innecesarios\c"
sudo rm -rf /ISO
sudo pacman --noconfirm -Rns archiso >>/tmp/Salida.txt 2>&1

echo -e "\n\n${GREEN}***********DONE***********\n\n${NOCOLOR}"
