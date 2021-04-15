#!/bin/bash
#
NOCOLOR='\033[0m'
RED='\033[1;31m'
GREEN='\033[1;32m'
SALIDA='/tmp/salida'

HEAD () {
	clear
	echo "***************************************************************************************************"
	echo "******************************* CAMBON OS INSTALLER ***********************************************"
	echo "***************************************************************************************************"
}

DONE () {
	echo -e "${GREEN} [DONE] ${NOCOLOR}" && sleep 1
}

ERROR () {
	echo -e "${RED} [ERROR] ${NOCOLOR}" && sleep 3
}

STOP () {
	echo -e "${RED} [ERROR FATAL] ${NOCOLOR}"
	umount /mnt/boot >>$SALIDA 2>&1; umount /mnt/home >>$SALIDA 2>&1; umount /mnt >>$SALIDA 2>&1; swapoff $SWAP >>$SALIDA 2>&1; rm -rf /mnt >>$SALIDA 2>&1; mkdir /mnt
	exit
}

CHROOT () {
	arch-chroot /mnt >>$SALIDA 2>&1 && DONE || ERROR
}
CHROOTF () {
	arch-chroot /mnt >>$SALIDA 2>&1 && DONE || STOP
}

SUDO () {
	echo -e "\n\n>>Contraseña del usuario: \c" && read -s PASS
	echo -e "\n\n\n>>Repetir contraseña: \c" && read -s PASS1
	if [[ $PASS = $PASS1 ]]
	then
		sleep 1
	else
		SUDO
	fi
}

OPTIONS () {
	echo -e "\n>>Tipo de arranque?(uefi/bios) \c" && read GRUB
	echo -e "\n\n>>Formato del disco?(mbr/gpt) \c" && read TDISCO
	echo -e "\n\n>>Procesador?(intel/amd) \c" && read CPU
	echo -e "\n\n>>Graficos?(nvidia/amd/vmware/all) \c" && read GPU
	echo -e "\n\n>>Entorno grafico?(terminal/gnome) \c" && read GDM
	echo -e "\n\n>>Escribe los programas adicionales: \c" && read -e -i "brave-bin menulibre wine-staging" ADD
	BOOT="$DISCO$(echo 1)"
	SWAP="$DISCO$(echo 2)"
	RAIZ="$DISCO$(echo 3)"
	HOME="$DISCO$(echo 4)"
	OUEFI="o\nn\np\n1\n\n+512M\nn\np\n2\n\n+4G\nn\np\n3\n\n+40G\nn\np\n4\n\n\nt\n1\nEF\nt\n2\n82\nt\n3\n83\nt\n4\n83\nw\n"
	OBIOS="o\nn\np\n1\n\n+512M\nn\np\n2\n\n+4G\nn\np\n3\n\n+40G\nn\np\n4\n\n\nt\n1\n83\nt\n2\n82\nt\n3\n83\nt\n4\n83\nw\n"
	GUEFI="g\nn\n1\n\n+512M\nn\n2\n\n+4G\nn\n3\n\n+40G\nn\n4\n\n\nt\n1\n1\nt\n2\n19\nt\n3\n23\nt\n4\n28\nw\n"
	GBIOS="g\nn\n1\n\n+512M\nn\n2\n\n+4G\nn\n3\n\n+40G\nn\n4\n\n\nt\n1\n4\nt\n2\n19\nt\n3\n23\nt\n4\n28\nw\n"
}

HEAD

if [[ $EUID -ne 0 ]]
then
	echo -e "\nEJECUTAR CON PRIVILEGIOS\n"
	exit
fi

echo -e "\n>>Iniciando instalacion\c"
reflector --country Spain --sort rate --save /etc/pacman.d/mirrorlist >$SALIDA 2>&1 && DONE || STOP

echo -e "\n\n>>Listando discos\n" && lsblk
echo -e "\n>>En que disco quieres instalar el sistema? \c" && read -e -i "/dev/sd" DISCO

echo -e "\n>>Escoger tipo de instalacion: (default/custom) \c" && read -e -i "default" TYPE
case $TYPE in
	custom)
		OPTIONS
	;;
	default)
		echo -e "bios\nmbr\nintel-ucode amd\nall\ngnome\nbrave-bin menulibre\n" | OPTIONS >>$SALIDA 2>&1
	;;
esac
echo -e "\n\n>>Nombre del equipo? \c" && read NOMBRE
echo -e "\n\n>>Nombre para el nuevo usuario: \c" && read USER
SUDO

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
		yes | mkfs.ext4 $BOOT >>$SALIDA 2>&1 || STOP
	;;
	uefi)
		yes | mkfs.fat -F32 $BOOT >>$SALIDA 2>&1 || STOP
	;;
esac
mkswap $SWAP >>$SALIDA 2>&1 || STOP
yes | mkfs.ext4 $RAIZ >>$SALIDA 2>&1 || STOP
yes | mkfs.ext4 $HOME >>$SALIDA 2>&1 || STOP
swapon $SWAP >>$SALIDA 2>&1 || STOP
mount $RAIZ /mnt >>$SALIDA 2>&1 || STOP
mkdir /mnt/home >>$SALIDA 2>&1 || STOP
mount $HOME /mnt/home >>$SALIDA 2>&1 || STOP
mkdir /mnt/boot >>$SALIDA 2>&1 || STOP
mount $BOOT /mnt/boot >>$SALIDA 2>&1 || STOP
DONE

echo -e "\n>>Instalando base del sistema\c"
pacstrap /mnt linux-zen linux-zen-headers linux-firmware base >>$SALIDA 2>&1 || STOP
DONE

echo -e "\n>>Instalando utilidades basicas\c"
echo "yes | pacman -S nano man man-db man-pages man-pages-es bash-completion neovim neofetch networkmanager grub $CPU-ucode git base-devel sudo || exit 1" | CHROOTF

case $GRUB in
	uefi)
		echo "yes | pacman -S efibootmgr || exit 1" | CHROOTF
	;;
	bios)
		DONE
	;;
esac

echo -e "\n>>Instalando drivers graficos\c"
case $GPU in
	amd)
		echo "yes | pacman -S xf86-video-vesa xf86-video-amdgpu lib32-mesa mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader || exit 1" | CHROOT
	;;
	nvidia)
		echo "yes | pacman -S xf86-video-vesa nvidia lib32-nvidia-utils nvidia-utils nvidia-settings nvidia-dkms vulkan-icd-loader lib32-vulkan-icd-loader || exit 1" | CHROOT
	;;
	intel)
		echo "yes | pacman -S xf86-video-vesa xf86-video-intel lib32-mesa mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader || exit 1" | CHROOT
	;;
	vmware)
		echo "yes | pacman -S xf86-video-vesa xf86-video-vmware lib32-mesa mesa || exit 1" | CHROOT
	;;
	all)
		echo "yes | pacman -S xf86-video-vesa xf86-video-amdgpu lib32-mesa mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader nvidialib32-nvidia-utils nvidia-utils nvidia-settings nvidia-dkms xf86-video-vmware || exit 1" | CHROOT
	;;
esac

echo -e "\n>>Instalando entorno grafico seleccionado\c"
case $GDM in
	terminal)
		DONE
	;;
	gnome)
		echo "yes | pacman -S gdm nautilus alacritty gedit gnome-calculator gnome-control-center gnome-tweaks || exit 1" | CHROOT
	;;
esac

echo -e "\n>>Generando archivo fstab\c"
genfstab -U /mnt >> /mnt/etc/fstab && DONE || STOP

echo -e "\n>>Estableciendo zona horaria\c"
echo "ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime && hwclock --systohc || exit 1" | CHROOT
	
echo -e "\n>>Cambiando idioma del sistema\c"
echo -e "\nes_ES.UTF-8 UTF-8\nen_US.UTF-8 UTF-8" >> /mnt/etc/locale.gen && locale-gen >>$SALIDA 2>&1 && echo -e "LANG=es_ES.UTF-8\nLANGUAGE=es_ES.UTF-8\nLC_ALL=en_US.UTF-8" >/etc/locale.conf && echo -e "KEYMAP=es" >/mnt/etc/vconsole.conf && DONE || ERROR
	
echo -e "\n>>Creando archivos host\c"
echo -e "$NOMBRE" >/mnt/etc/hostname && echo -e "127.0.0.1	localhost\n::1		localhost\n127.0.1.1	$NOMBRE" >/mnt/etc/hosts && DONE || ERROR
	
echo -e "\n>>Configurando red\c"
echo "systemctl enable NetworkManager.service || exit 1" | CHROOT
	
echo -e "\n>>Configurando grub\c"
case $GRUB in
	bios)
		echo "grub-install --target=i386-pc $DISCO && grub-mkconfig -o /boot/grub/grub.cfg || exit 1" | CHROOTF
	;;
	uefi)
		echo "grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=COS && grub-mkconfig -o /boot/grub/grub.cfg || exit 1" | CHROOTF
	;;
esac
	
echo -e "\n>>Activando entorno grafico\c"
case $GDM in
	terminal)
		DONE
	;;
	gnome)
		echo "systemctl enable gdm.service || exit 1" | CHROOT
	;;
esac
	
echo -e "\n>>Configurando usuario\c"
echo "groupadd -g 513 sudo && useradd -m -s /bin/bash -g sudo $USER && (echo -e '$PASS\n$PASS' | passwd $USER) || exit 1" | CHROOT
	
echo -e "\n>>Editando skel\c"
echo -e "\n\nneofetch" >/mnt/etc/skel/.bashrc && DONE || ERROR

echo -e "\n>>Configurando sudo\c"
cp /mnt/etc/sudoers /mnt/etc/sudoers.bk && echo "%sudo ALL=(ALL) ALL" >>/mnt/etc/sudoers.bk && echo "%sudo ALL=(ALL) NOPASSWD: ALL" >>/mnt/etc/sudoers && DONE || ERROR

echo -e "\n>>Instalando trizen\c"
echo "echo 'cd /tmp && git clone https://aur.archlinux.org/trizen.git && cd trizen && makepkg --noconfirm -si || exit 1' | su $USER || exit 1" | CHROOT

echo -e "\n>>Instalando programas adicionales\c"
echo "echo 'trizen --noconfirm -S $ADD || exit 1' | su $USER || exit 1" | CHROOT
mv /mnt/etc/sudoers.bk /mnt/etc/sudoers
	
echo -e "\n>>Ejecutando el script cmd de https://github.com/cambonos/cmd.sh\c"
echo "rm -rf /tmp/Scripts; cd /tmp && git clone https://github.com/CambonOS/Scripts.git && bash Scripts/cmd.sh && echo OK || echo FAIL" > /mnt/usr/bin/actualizar-cmd && chmod 755 /mnt/usr/bin/actualizar-cmd && (echo "actualizar-cmd || exit 1" | CHROOT) || ERROR

swapoff $SWAP

echo -e "\n***************************************************************************************************"
echo "************************************** INSTALLED **************************************************"
echo "***************************************************************************************************"
