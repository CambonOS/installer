#!/bin/bash

##Definicion de grupos
STOP () {
	umount -R /mnt; rm -rf /mnt >>$SALIDA 2>&1; mkdir /mnt; exit
}

##Particionado
SALIDA='/tmp/particionado.log'
ls /sys/firmware/efi/efivars >/dev/null 2>&1 && GRUB='uefi' || GRUB='bios'
$DISCO = $1
$PART = $2

case $GRUB in
	uefi)
		(echo $DISCO | grep nvme >>$SALIDA 2>&1) && DISCOP=$DISCO$(echo p) || DISCOP=$DISCO
		N=1 && LIBRE=0
		if [[ $PART = "end-space"]]
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
		echo -e "\n>>Particionando disco...\c"
		(echo $DISCO | grep nvme >>$SALIDA 2>&1) && DISCOP=$DISCO$(echo p) || DISCOP=$DISCO
		(echo -e "o\nn\n\n\n\n+30G\nn\n\n\n\n\nw\n" | fdisk -w always /dev/$DISCO >>$SALIDA 2>&1) || STOP && N=1
		yes | mkfs.ext4 /dev/$DISCOP$N >>$SALIDA 2>&1 || STOP
		mount /dev/$DISCOP$N /mnt >>$SALIDA 2>&1 || STOP && N=$(($N+1))
		yes | mkfs.ext4 /dev/$DISCOP$N >>$SALIDA 2>&1 || STOP
		mkdir /mnt/home >>$SALIDA 2>&1 || STOP
		mount /dev/$DISCOP$N /mnt/home >>$SALIDA 2>&1
		;;
esac
