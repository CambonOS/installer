#!/bin/bash
#
NOCOLOR='\033[0m'
RED='\033[1;31m'
GREEN='\033[1;32m'
SALIDA='/tmp/salida'

HEAD () {
	clear && cat /etc/motd
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
	exit 1
}

CHROOT () {
	arch-chroot /mnt >>$SALIDA 2>&1 && DONE || ERROR
}
CHROOTF () {
	arch-chroot /mnt >>$SALIDA 2>&1 && DONE || STOP
}

SUDO () {
	echo -e "\n>>Contraseña del usuario: \c" && read -s PASS
	echo -e "\n>>Repetir contraseña: \c" && read -s PASS1
	if [[ $PASS = $PASS1 ]]
	then
		sleep 1
	else
		SUDO
	fi
}

PREGUNTAS () {
	echo -e "\n>>Tipo de arranque?(uefi/bios) \c" && read GRUB
	echo -e "\n>>Formato del disco?(mbr/gpt) \c" && read TDISCO
	echo -e "\n>>Procesador?(intel/amd) \c" && read CPU
	echo -e "\n>>Graficos?(nvidia/amd/vmware/all) \c" && read GPU
	echo -e "\n>>Entorno grafico?(terminal/gnome) \c" && read GDM
	echo -e "\n>>Escribe los programas adicionales: \c" && read -e -i "menulibre" ADD
}

VARIABLES () {	
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

echo -e "\n>>Listando discos\n" && lsblk
echo -e "\n>>En que disco quieres instalar el sistema? \c" && read -e -i "/dev/sd" DISCO

echo -e "\n>>Escoger tipo de instalacion: (default/custom) \c" && read -e -i "default" TYPE
case $TYPE in
	custom)
		PREGUTAS
		VARIABLES
	;;
	default)
		GRUB='bios'
		TDISCO='mbr'
		CPU='intel-ucode amd'
		GPU='all'
		GDM='gnome'
		ADD='menulibre'
		VARIABLES
	;;
esac

echo -e "\n>>Nombre del equipo? \c" && read NOMBRE
echo -e "\n>>Nombre para el nuevo usuario: \c" && read USER
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
pacstrap /mnt linux-zen linux-zen-headers linux-firmware base >>$SALIDA 2>&1 && DONE || STOP

echo -e "\n>>Generando archivo fstab\c"
genfstab -U /mnt >> /mnt/etc/fstab && DONE || STOP

echo -e "\n>>Configurando sistema\c"
echo "sudo rm -rf /tmp/arch-distro; cd /tmp && git clone https://github.com/CambonOS/arch-distro.git && sudo bash arch-distro/cambonos-cmd.sh" > /mnt/usr/bin/cambonos-cmd && chmod 755 /mnt/usr/bin/cambonos-cmd && (echo "cambonos-cmd || exit 1" | CHROOTF >$SALIDA 2>&1) && cp /mnt/tmp/arch-distro/etc/* /mnt/etc && (echo "ln -sf /usr/share/zoneinfo/Región/Ciudad /etc/localtime && hwclock --systohc || exit 1" | CHROOTF >$SALIDA 2>&1) && DONE || STOP

echo -e "\n>>Instalando utilidades basicas\c"
echo "pacman --noconfirm -S nano man man-db man-pages man-pages-es bash-completion neovim neofetch networkmanager $CPU-ucode git base-devel sudo cronie ntfs-3g || exit 1" | CHROOTF

echo -e "\n>>Configurando red\c"
echo "echo '$NOMBRE' >/etc/hostname && echo -e '127.0.0.1	localhost\n::1		localhost\n127.0.1.1	$NOMBRE' >/etc/hosts && systemctl enable NetworkManager.service || exit 1" | CHROOT

echo -e "\n>>Creando usuario\c"
echo "groupadd -g 513 sudo && useradd -m -s /bin/bash -g sudo $USER && (echo -e '$PASS\n$PASS' | passwd $USER) || exit 1" | CHROOT

echo -e "\n>>Instalando drivers graficos\c"
case $GPU in
	amd)
		echo "pacman --noconfirm -S xf86-video-vesa xf86-video-amdgpu lib32-mesa mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader || exit 1" | CHROOT
	;;
	nvidia)
		echo "pacman --noconfirm -S xf86-video-vesa nvidia lib32-nvidia-utils nvidia-utils nvidia-settings nvidia-dkms vulkan-icd-loader lib32-vulkan-icd-loader || exit 1" | CHROOT
	;;
	intel)
		echo "pacman --noconfirm -S xf86-video-vesa xf86-video-intel lib32-mesa mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader || exit 1" | CHROOT
	;;
	vmware)
		echo "pacman --noconfirm -S xf86-video-vesa xf86-video-vmware lib32-mesa mesa || exit 1" | CHROOT
	;;
	*)
		echo "pacman --noconfirm -S xf86-video-vesa xf86-video-amdgpu lib32-mesa mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader nvidia lib32-nvidia-utils nvidia-utils nvidia-settings nvidia-dkms xf86-video-vmware || exit 1" | CHROOT
	;;
esac

echo -e "\n>>Instalando entorno grafico\c"
case $GDM in
	terminal)
		DONE
	;;
	gnome)
		echo "pacman --noconfirm -S gdm nautilus gnome-control-center gnome-tweaks && systemctl enable gdm.service || exit 1" | CHROOT
	;;
esac

echo -e "\n>>Instalando grub\c"
case $GRUB in
	bios)
		echo "pacman --noconfirm -S grub && grub-install --target=i386-pc $DISCO && grub-mkconfig -o /boot/grub/grub.cfg || exit 1" | CHROOTF
	;;
	uefi)
		echo "pacman --noconfirm -S grub efibootmgr && grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=COS && grub-mkconfig -o /boot/grub/grub.cfg || exit 1" | CHROOTF
	;;
esac

echo -e "\n>>Instalando trizen\c"
echo "echo 'cd /tmp && git clone https://aur.archlinux.org/trizen.git && cd trizen && makepkg --noconfirm -si || exit 1' | su $USER || exit 1" | CHROOT

echo -e "\n>>Instalando programas adicionales\c"
mv /mnt/etc/sudoers /mnt/etc/sudoers.bk
echo "%sudo ALL=(ALL) NOPASSWD: ALL" > /mnt/etc/sudoers
echo "echo 'trizen --noconfirm -S brave-bin wine-staging $ADD || exit 1' | su $USER || exit 1" | CHROOT
mv /mnt/etc/sudoers.bk /mnt/etc/sudoers

swapoff $SWAP

echo -e "\n***************************************************************************************************"
echo "************************************** INSTALLED **************************************************"
echo "***************************************************************************************************"
