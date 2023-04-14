#!/bin/bash

##Definicion de variables
NOCOLOR='\033[0m'
RED='\033[1;31m'
GREEN='\033[1;32m'

##Definicion de grupos
HEAD () {
	clear && cat /etc/motd
}

DONE () {
	echo -e "${GREEN} [DONE] ${NOCOLOR}"
}

ERROR () {
	echo -e "${RED} [ERROR] ${NOCOLOR}"
}

ARCH () {
	arch-chroot /mnt >>$SALIDA 2>&1
}

STOP () {
	echo -e "${RED} [ERROR FATAL] ${NOCOLOR}"
	umount /mnt/boot >>$SALIDA 2>&1; umount /mnt/home >>$SALIDA 2>&1; umount /mnt >>$SALIDA 2>&1; rm -rf /mnt >>$SALIDA 2>&1; mkdir /mnt; exit
}

##Comprobacion de red
NETWORK () {
ping -c 3 google.com >/dev/null 2>&1 || \
(systemctl start NetworkManager.service
sleep 5
nmtui connect
NETWORK
)
}
NETWORK || exit

##Particionado
SALIDA='/tmp/particionado.log'
HEAD
ls /sys/firmware/efi/efivars >/dev/null 2>&1 && GRUB='uefi' || GRUB='bios'
case $GRUB in
	uefi)
		echo '
Bienvenido al instalador oficial de CambonOS!!!

Para continuar su intalacion escoga entre:

  1-Instalacion borrando todo el disco
  2-Instalar sistema en el espacio libre al final del disco
  3-Cancelar'
		echo -e "\n(1,2,3): \c" && read PART
		if [[ $PART != 1 ]] && [[ $PART != 2 ]]
		then exit
		fi
		echo -e "\n>>Listando discos\n" && lsblk -o NAME,SIZE,VENDOR,MODEL -d
		echo -e "\n>>En que disco desea instalar el sistema (sda,nvme0n1,...): \c" && read DISCO
		(echo $DISCO | grep nvme >>$SALIDA 2>&1) && DISCOP=$DISCO$(echo p) || DISCOP=$DISCO
		N=1 && LIBRE=0
		if [[ $PART = 2 ]]
		then
			fdisk -l /dev/$DISCO | grep gpt >>$SALIDA 2>&1 && TD=gpt || TD=mbr
			case $TD in
			mbr)
				echo -e "\n>>El disco NO esta en GPT\c"
				STOP
				;;
			gpt)
				while [[ $LIBRE = 0 ]]
				do 
					lsblk | grep $DISCOP$N >>$SALIDA 2>&1 && N=$(($N+1)) || LIBRE=1
				done
				echo -e "\n>>Particionando disco...\c"
				(echo -e "n\n\n\n+512M\nn\n\n\n+30G\nn\n\n\n\nw\n" | fdisk -w always /dev/$DISCO >>$SALIDA 2>&1) || STOP
				;;
			esac
		else 
			echo -e "\n>>Se eliminaran ${RED}todos los datos del disco${NOCOLOR}. Desea continuar? (s/N): \c"
			read ANS
			if [[ $ANS = s ]] || [[ $ANS = si ]] || [[ $ANS = Si ]] || [[ $ANS = S ]]
			then sleep 0
			else exit
			fi
			echo -e "\n>>Particionando disco...\c"
			(echo -e "g\nn\n\n\n+512M\nn\n\n\n+30G\nn\n\n\n\nw\n" | fdisk -w always /dev/$DISCO >>$SALIDA 2>&1) || STOP
		fi
		yes | mkfs.vfat -F 32 /dev/$DISCOP$N >>$SALIDA 2>&1 || STOP && N=$(($N+1))
		yes | mkfs.ext4 /dev/$DISCOP$N >>$SALIDA 2>&1 || STOP && N=$(($N+1))
		yes | mkfs.ext4 /dev/$DISCOP$N >>$SALIDA 2>&1 || STOP && N=$(($N-1))
		mount /dev/$DISCOP$N /mnt >>$SALIDA 2>&1 || STOP && N=$(($N-1))
		mkdir /mnt/boot >>$SALIDA 2>&1 || STOP
		mount /dev/$DISCOP$N /mnt/boot >>$SALIDA 2>&1 || STOP && N=$(($N+2))
		mkdir /mnt/home >>$SALIDA 2>&1 || STOP
		mount /dev/$DISCOP$N /mnt/home >>$SALIDA 2>&1 && DONE || STOP
		;;
	bios)
		echo -e "\nBienvenido al instalador oficial de CambonOS!!!\n\n>>Con el istalador arrancado en BIOS solo se puede instalar borrando todo el disco.\n\n>>Quiere continuar? (s/N): \c"
		read ANS
		if [[ $ANS = s ]] || [[ $ANS = si ]] || [[ $ANS = Si ]] || [[ $ANS = S ]]
		then
			echo -e "\n>>Listando discos\n" && lsblk -o NAME,SIZE,VENDOR,MODEL -d
			echo -e "\n>>En que disco desea instalar el sistema (sda,nvme0n1,...): \c" && read DISCO
			echo -e "\n>>Se eliminaran ${RED}todos los datos del disco${NOCOLOR}. Desea continuar? (s/N): \c"
			read ANS
			if [[ $ANS = s ]] || [[ $ANS = si ]] || [[ $ANS = Si ]] || [[ $ANS = S ]]
			then sleep 0
			else exit
			fi
		else 
			exit
		fi
		echo -e "\n>>Particionando disco...\c"
		(echo $DISCO | grep nvme >>$SALIDA 2>&1) && DISCOP=$DISCO$(echo p) || DISCOP=$DISCO
		(echo -e "o\nn\n\n\n\n+30G\nn\n\n\n\n\nw\n" | fdisk -w always /dev/$DISCO >>$SALIDA 2>&1) || STOP && N=1
		yes | mkfs.ext4 /dev/$DISCOP$N >>$SALIDA 2>&1 || STOP
		mount /dev/$DISCOP$N /mnt >>$SALIDA 2>&1 || STOP && N=$(($N+1))
		yes | mkfs.ext4 /dev/$DISCOP$N >>$SALIDA 2>&1 || STOP
		mkdir /mnt/home >>$SALIDA 2>&1 || STOP
		mount /dev/$DISCOP$N /mnt/home >>$SALIDA 2>&1 && DONE || STOP
		;;
esac

installer/dialog.sh $DISCO
