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
rm /ISO/porfile/efiboot/loader/entries/archiso-x86_64-speech-linux.conf
mv /tmp/Scripts/camboninstall.sh /ISO/porfile/airootfs/usr/local/bin/camboninstall || ERROR
echo -e "chmod 777 /usr/local/bin/camboninstall" >>/ISO/porfile/airootfs/root/.zshrc
mv /tmp/Scripts/iso/paquetes /ISO/porfile/packages.x86_64 || ERROR
echo -e "camboniso" >/ISO/porfile/airootfs/etc/hostname
echo -e "KEYMAP=es" >/ISO/porfile/airootfs/etc/vconsole.conf
mv /tmp/Scripts/iso/porfile /ISO/porfile/profiledef.sh
mv /tmp/Scripts/iso/tail /ISO/porfile/syslinux/archiso_tail.cfg
mv /tmp/Scripts/iso/sys-linux /ISO/porfile/syslinux/archiso_sys-linux.cfg
mv /tmp/Scripts/iso/head /ISO/porfile/syslinux/archiso_head.cfg
mv /tmp/Scripts/iso/uefi /ISO/porfile/efiboot/loader/entries/archiso-x86_64-linux.conf
mv /tmp/Scripts/iso/motd /ISO/porfile/airootfs/etc/motd
mv /tmp/Scripts/iso/confpacman /ISO/porfile/airootfs/etc/pacman.conf
mv /tmp/Scripts/image/8ItevIK1iZMeCvOEdUSyOHIVW4UouWlkk1p7GeDjFY0.png /ISO/porfile/syslinux/splash.png
DONE

echo -e "\n>>Creando la ISO\n"
mkarchiso -v -w /ISO/work -o $RUTAD /ISO/porfile && DONE || ERROR

echo -e "\n>>Eliminado ficheros/paquetes innecesarios\c"
rm -rf /ISO
pacman --noconfirm -Rns archiso >>/tmp/Salida.txt 2>&1
chmod 777 $RUTAD/cambonos-*

echo -e "\n\n${GREEN}***********DONE***********\n\n${NOCOLOR}"
