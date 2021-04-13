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
  echo -e "${RED} ERROR ${NOCOLOR}"
  exit
}

DONE () {
  echo -e "${GREEN} DONE ${NOCOLOR}"
  sleep 1
}

echo -e "\n>>Carpeta destino ISO:\c"
read -e -i $(pwd) RUTAD

echo -e "\n>>Instalando paquetes necesarios\c"
pacman --noconfirm -Sy archiso >/tmp/Salida.txt 2>&1 && DONE || ERROR

echo -e "\n>>Descargando el script de instalacion\c"
cd /tmp && git clone https://github.com/CambonOS/Scripts.git && DONE || ERROR

echo -e "\n>>Creando ficheros de configuracion de la ISO\c"
mkdir /ISO && cp -r /usr/share/archiso/configs/releng /ISO/porfile || ERROR
cp /tmp/Scripts/camboninstall.sh /ISO/porfile/airootfs/usr/local/bin/camboninstall || ERROR
chown root:root /ISO/porfile/airootfs/usr/local/bin/camboninstall
chmod 755 /ISO/porfile/airootfs/usr/local/bin/camboninstall
mv /tmp/Scripts/iso/paquetes /ISO/porfile/packages.x86_64 || ERROR
echo -e "camboniso" >/ISO/porfile/airootfs/etc/hostname
echo -e "LANG=es_ES.UTF-8\nLANGUAGE=es_ES.UTF-8\nLC_ALL=en_US.UTF-8" >/ISO/porfile/airootfs/etc/locale.conf
mv /tmp/Scripts/iso/porfile /ISO/porfile/profiledef.sh
DONE

echo -e "\n>>Creando la ISO\n"
mkarchiso -v -w /ISO/work -o $RUTAD /ISO/porfile && DONE || ERROR

echo -e "\n>>Eliminado ficheros/paquetes innecesarios\c"
rm -rf /ISO
pacman --noconfirm -Rns archiso >>/tmp/Salida.txt 2>&1
chmod 777 $RUTAD/archlinux*
echo -e "\n\n${GREEN}***********DONE***********\n\n${NOCOLOR}"
