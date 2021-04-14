#!/bin/bash
if [[ $EUID -ne 0 ]]
then
	echo -e "\nEJECUTAR CON PRIVILEGIOS\n"
	exit
fi

NOCOLOR='\033[0m'
RED='\033[1;31m'
GREEN='\033[1;32m'
SALIDA="/tmp/salida"

HEAD () {
	clear
	echo "***************************************************************************************************"
	echo "******************************* CAMBON OS INSTALLER ***********************************************"
	echo "***************************************************************************************************"
}

DONE () {
	echo -e "${GREEN} [DONE] ${NOCOLOR}"
	sleep 1
}

ERROR () {
	echo -e "${RED} [ERROR] ${NOCOLOR}"
	sleep 3
}

STOP () {
	echo -e "${RED} [ERROR FATAL] ${NOCOLOR}"
	umount /mnt/boot >>$SALIDA 2>&1; umount /mnt/home >>$SALIDA 2>&1; umount /mnt >>$SALIDA 2>&1; swapoff $SWAP >>$SALIDA 2>&1; rm -rf /mnt >>$SALIDA 2>&1; mkdir /mnt
	exit
}

HEAD

echo -e "\n>>Iniciando instalacion\c"
loadkeys es && ping -c 4 archlinux.org >$SALIDA 2>&1 || STOP
DONE

echo -e "\n>>Tipo de arranque?(uefi/bios) \c" && read GRUB
echo -e "\n\n>>Listando discos\n" && lsblk
echo -e "\n>>En que disco quieres instalar el sistema? \c" && read -e -i "/dev/sd" DISCO
echo -e "\n\n>>Formato del disco?(mbr/gpt) \c" && read TDISCO
echo -e "\n\n>>Nombre del equipo? \c" && read NOMBRE
echo -e "\n\n>>Dominio? \c" && read -e -i "$NOMBRE.cambon.local" DOMINIO
echo -e "\n\n>>Procesador?(intel/amd) \c" && read CPU
echo -e "\n\n>>Graficos?(nvidia/amd/vmware) \c" && read GPU
echo -e "\n\n>>Entorno grafico?(terminal/gnome) \c" && read GDM
echo -e "\n\n>>Contraseña del root? \c" && read -s PASS

BOOT="$DISCO$(echo 1)"
SWAP="$DISCO$(echo 2)"
RAIZ="$DISCO$(echo 3)"
HOME="$DISCO$(echo 4)"
OUEFI="o\nn\np\n1\n\n+512M\nn\np\n2\n\n+4G\nn\np\n3\n\n+40G\nn\np\n4\n\n\nt\n1\nEF\nt\n2\n82\nt\n3\n83\nt\n4\n83\nw\n"
OBIOS="o\nn\np\n1\n\n+512M\nn\np\n2\n\n+4G\nn\np\n3\n\n+40G\nn\np\n4\n\n\nt\n1\n83\nt\n2\n82\nt\n3\n83\nt\n4\n83\nw\n"
GUEFI="g\nn\n1\n\n+512M\nn\n2\n\n+4G\nn\n3\n\n+40G\nn\n4\n\n\nt\n1\n1\nt\n2\n19\nt\n3\n23\nt\n4\n28\nw\n"
GBIOS="g\nn\n1\n\n+512M\nn\n2\n\n+4G\nn\n3\n\n+40G\nn\n4\n\n\nt\n1\n4\nt\n2\n19\nt\n3\n23\nt\n4\n28\nw\n"

HEAD

echo -e "\n>>Actualizando reloj\c"
timedatectl set-ntp true >>$SALIDA 2>&1 && DONE || ERROR

echo -e "\n>>Particionando disco\c"
case $TDISCO in
	gpt) 
		case $GRUB in
			uefi)
				(echo -e $GUEFI | fdisk -w always $DISCO >>$SALIDA 2>&1) || STOP
			;; 
			bios)
				(echo -e $GBIOS | fdisk -w always $DISCO >>$SALIDA 2>&1) || STOP
			;;
		esac
	;;
	mbr) 
		case $GRUB in
			uefi)
				(echo -e $OUEFI | fdisk -w always $DISCO >>$SALIDA 2>&1) || STOP
			;;
			bios)
				(echo -e $OBIOS | fdisk -w always $DISCO >>$SALIDA 2>&1) || STOP
			;;
		esac
	;;
esac
DONE

echo -e "\n>>Formateando y montando sistemas de archivos\c"
case $GRUB in
	bios)
		echo -e "y\n" | mkfs.ext4 $BOOT >>$SALIDA 2>&1 || STOP
	;;
	uefi)
		echo -e "y\n" | mkfs.fat -F32 $BOOT >>$SALIDA 2>&1 || STOP
	;;
esac
mkswap $SWAP >>$SALIDA 2>&1 || STOP
echo -e "y\n" | mkfs.ext4 $RAIZ >>$SALIDA 2>&1 || STOP
echo -e "y\n" | mkfs.ext4 $HOME >>$SALIDA 2>&1 || STOP
swapon $SWAP >>$SALIDA 2>&1 || STOP
mount $RAIZ /mnt >>$SALIDA 2>&1 || STOP
mkdir /mnt/home >>$SALIDA 2>&1 || STOP
mount $HOME /mnt/home >>$SALIDA 2>&1 || STOP
mkdir /mnt/boot >>$SALIDA 2>&1 || STOP
mount $BOOT /mnt/boot >>$SALIDA 2>&1 || STOP
DONE

echo -e "\n>>Instalando base del sistema\c"
pacstrap /mnt linux-zen linux-zen-headers linux-firmware base nano man man-db man-pages man-pages-es bash-completion neovim neofetch networkmanager grub $CPU-ucode git base-devel sudo >>$SALIDA 2>&1 || STOP
case $GRUB in
	uefi)
		pacstrap /mnt efibootmgr >>$SALIDA 2>&1 || STOP
	;;
	bios)
	;;
esac
DONE

echo -e "\n>>Instalando drivers graficos\c"
case $GPU in
	amd)
		pacstrap /mnt xf86-video-vesa xf86-video-amdgpu lib32-mesa mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader >>$SALIDA 2>&1 && DONE || ERROR
	;;
	nvidia)
		pacstrap /mnt xf86-video-vesa nvidia lib32-nvidia-utils nvidia-utils nvidia-settings nvidea-dkms vulkan-icd-loader lib32-vulkan-icd-loader >>$SALIDA 2>&1 && DONE || ERROR
	;;
	intel)
		pacstrap /mnt xf86-video-vesa xf86-video-intel lib32-mesa mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader >>$SALIDA 2>&1 && DONE || ERROR
	;;
	vmware)
		pacstrap /mnt xf86-video-vesa xf86-video-vmware lib32-mesa mesa >>$SALIDA 2>&1 && DONE || ERROR
	;;
esac

echo -e "\n>>Instalando entorno grafico seleccionado\c"
case $GDM in
	terminal)
		DONE
	;;
	gnome)
		pacstrap /mnt gdm nautilus alacritty gedit gnome-calculator gnome-control-center gnome-tweak-tool >>$SALIDA 2>&1 && DONE || ERROR
	;;
esac

echo -e "\n>>Generando archivo fstab\c"
genfstab -U /mnt >> /mnt/etc/fstab && DONE || STOP

echo "
	NOCOLOR='\033[0m'
	RED='\033[1;31m'
	GREEN='\033[1;32m'
	
	DONE () {
		echo -e "${GREEN} [DONE] ${NOCOLOR}"
		sleep 1
	}
	
	ERROR () {
		echo -e "${RED} [ERROR] ${NOCOLOR}"
		sleep 3
	}

	echo -e '\n>>Estableciendo zona horaria\c'
	ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime && hwclock --systohc && DONE || ERROR
	
	echo -e '\n>>Cambiando idioma del sistema\c'
	echo 'es_ES.UTF-8 UTF-8\nen_US.UTF-8 UTF-8' >> /etc/locale.gen && locale-gen >>$SALIDA 2>&1 && echo -e 'LANG=es_ES.UTF-8\nLANGUAGE=es_ES.UTF-8\nLC_ALL=en_US.UTF-8' >/etc/locale.conf && echo -e 'KEYMAP=es' >/etc/vconsole.conf && DONE || ERROR
	
	echo -e '\n>>Creando archivos host\c'
	echo -e '$NOMBRE' >/etc/hostname && echo -e '127.0.0.1	localhost\n::1		localhost\n127.0.1.1	$DOMINIO $NOMBRE' >/etc/hosts && DONE || ERROR
	
	echo -e '\n>>Configurando red\c'
	systemctl enable NetworkManager.service >>$SALIDA 2>&1 && DONE || ERROR
	
	echo -e '\n>>Configurando grub\c'
	case $GRUB in
		bios)
			grub-install --target=i386-pc $DISCO >>$SALIDA 2>&1 || exit 1
		;;
		uefi)
			grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB >>$SALIDA 2>&1 || exit 1
		;;
	esac && grub-mkconfig -o /boot/grub/grub.cfg >>$SALIDA 2>&1 && DONE || exit 1
	
	echo -e '\n>>Activando entorno grafico\c'
	case $GDM in
		terminal)
		;;
		gnome)
			systemctl enable gdm.service >>$SALIDA 2>&1 || ERROR
		;;
	esac
	DONE
	
	echo -e '\n>>Configurando root\c'
	(echo -e '$PASS\n$PASS' | passwd) && DONE || exit 1
	
	echo -e '\n>>Editando skel\c'
	echo -e '\nneofetch' >/etc/skel/.bashrc && DONE || ERROR

	echo -e '\n>>Creando grupo sudo\c'
	groupadd -g 513 sudo && cp /etc/sudoers /etc/sudoers.bk && echo '%sudo ALL=(ALL) ALL' >>/etc/sudoers.bk && echo '%sudo ALL=(ALL) NOPASSWD: ALL' >>/etc/sudoers && useradd -m -s /bin/bash -g sudo sysop && DONE || exit 1
	
	echo -e '\n>>Instalando trizen\c'
	echo -e 'cd /tmp && git clone https://aur.archlinux.org/trizen.git >>$SALIDA 2>&1 && cd trizen && makepkg -si >>$SALIDA 2>&1 && exit || exit 1' | su - sysop && DONE || ERROR
	
	usedel -r sysop >>$SALIDA 2>&1
	mv /etc/sudoers.bk /etc/sudoers
	
	echo -e '\n>>Ejecutando el script cmd de https://github.com/cambonos/cmd.sh\c'
	echo -e 'rm -rf /tmp/Scripts; cd /tmp && git clone https://github.com/CambonOS/Scripts.git >>$SALIDA 2>&1 && bash Scripts/cmd.sh && echo OK || echo FAIL' > /usr/bin/actualizar-cmd
	chmod 755 /usr/bin/actualizar-cmd
	actualizar-cmd
	
	exit
" > /mnt/usr/bin/seguir

chmod 777 /mnt/usr/bin/seguir
arch-chroot /mnt seguir || STOP
rm -f /mnt/usr/bin/seguir

echo -e "\n***************************************************************************************************"
echo "************************************** INSTALLED **************************************************"
echo "***************************************************************************************************"
