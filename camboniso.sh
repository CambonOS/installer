#!/bin/bash
if [[ $EUID -ne 0 ]]
then
	echo -e "Debese ejecutar como usuario con privilejios"
	exit
fi

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

echo -e "\n>>Carpeta destino ISO:\c"
read -e -i $(pwd) RUTAD

echo -e "\n>>Instalando paquetes necesarios\c"
pacman --noconfirm -Sy archiso >/tmp/Salida.txt 2>&1 && DONE || ERROR

echo -e "\n>>Descargando el script de instalacion"
rm -rf /tmp/Scripts >>/tmp/Salida.txt 2>&1
cd /tmp && git clone https://github.com/CambonOS/Scripts.git && DONE || ERROR

echo -e "\n>>Creando ficheros de configuracion de la ISO\c"
mkdir /ISO && cp -r /usr/share/archiso/configs/releng /ISO/porfile || ERROR
mv /tmp/Scripts/camboninstall.sh /ISO/porfile/airootfs/usr/local/bin/camboninstall || ERROR
echo 'chmod 777 /usr/local/bin/camboninstall;VERDE="\033[1;32m";NOCOLOR="\033[0m";AZUL="\033[1;34m";echo -e "\n  Para instalar ${AZUL}CambonOS${NOCOLOR} ejecute el comando ${VERDE}camboninstall${NOCOLOR}\n"' >>/ISO/porfile/airootfs/root/.zshrc
echo -e "camboniso" >/ISO/porfile/airootfs/etc/hostname
echo -e "KEYMAP=es" >/ISO/porfile/airootfs/etc/vconsole.conf
cp -r /tmp/Scripts/iso/* /ISO/porfile/ || ERROR
rm /ISO/porfile/syslinux/splash.png
DONE

echo -e "\n>>Creando la ISO\n"
mkarchiso -v -w /ISO/work -o $RUTAD /ISO/porfile && DONE || ERROR

echo -e "\n>>Eliminado ficheros/paquetes innecesarios\c"
rm -rf /ISO
pacman --noconfirm -Rns archiso >>/tmp/Salida.txt 2>&1

echo -e "\n\n${GREEN}***********DONE***********\n\n${NOCOLOR}"
