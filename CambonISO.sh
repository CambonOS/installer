#!/bin/bash
if [[ $EUID -ne 0 ]]
then
	echo -e "Debese ejecutar como usuario con privilejios"
	exit
fi
echo -e "\n>>Carpeta destino ISO:\c"
read -e -i $(pwd) RUTAD
echo -e "\n>>Instalando paquetes necesarios"
pacman -noconfirm -Sy archiso >>/tmp/Salida.txt 2>&1
echo -e "\n>>Descargando el script de instalacion"
cd /tmp
git clone https://github.con/cambonos/scripts.git
echo -e "\n>>Creando ficheros de configuracion de la ISO"
mkdir /ISO
cp -r /usr/share/archiso/configs/releng /ISO/porfile
cp /tmp/scripts/CambonOS-Install.sh /ISO/porfile/airootfs/usr/local/bin/cambonos-install
chown root:root /ISO/porfile/airootfs/usr/local/bin/cambonos-install
chmod 755 /ISO/porfile/airootfs/usr/local/bin/cambonos-install
cp /tmp/scripts/iso/paquetes /ISO/profile/packages.x86_64
echo -e "camboniso" >/ISO/porfile/airootfs/etc/hostname
echo -e "\n>>Creando la ISO"
mkarchiso -v -w /ISO/work -o $RUTAD /ISO/porfile
echo -e "\n>>Eliminado ficheros/paquetes innecesarios"
rm -rf /ISO
pacman -noconfirm -Rns archiso >>/tmp/Salida.txt 2>&1
chmod 777 $RUTAD/archlinux*
echo -e "\n\n***********DONE***********\n\n"
