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
	echo -e "\n\n>>Repetir contraseña: \c" && read -s PASS1
	if [[ $PASS = $PASS1 ]]
	then
		sleep 1
	else
		SUDO
	fi
}

ROOT () {
	echo -e "\n>>Contraseña del usuario administrador (root): \c" && read -s SECRET
	echo -e "\n\n>>Repetir contraseña: \c" && read -s SECRET1
	if [[ $SECRET = $SECRET1 ]]
	then
		sleep 1
	else
		ROOT
	fi
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
echo -e "\n>>En que disco quieres instalar el sistema: \c" && read -e -i "/dev/sd" DISCO
echo -e "\n>>Escoger tipo de instalacion: (cambonos/cambonos-lite/cambonos-server) \c" && read -e -i "cambonos" TYPE
echo -e "\n>>Nombre del equipo: \c" && read NOMBRE
ROOT
echo -e "\n\n>>Nombre para el nuevo usuario: \c" && read USER
SUDO
HEAD

echo -e "\n>>Actualizando reloj\c"
timedatectl set-ntp true >>$SALIDA 2>&1 && DONE || ERROR

echo -e "\n>>Particionando disco\c"
ls /sys/firmware/efi/efivars >/dev/null 2>&1 && GRUB='uefi' || GRUB='bios'
case $GRUB in
	uefi) 
		(echo -e "g\nn\n1\n\n+512M\nn\n2\n\n\nt\n1\n1\nt\n2\n23\nw\n" | fdisk -w always $DISCO >>$SALIDA 2>&1) && DONE || STOP 
		yes | mkfs.fat -F32 $DISCO$(echo 1) >>$SALIDA 2>&1 || STOP
		yes | mkfs.ext4 $DISCO$(echo 2) >>$SALIDA 2>&1 || STOP
		mount $DISCO$(echo 2) /mnt >>$SALIDA 2>&1 || STOP 
		mkdir /mnt/boot >>$SALIDA 2>&1 || STOP
		mount $DISCO$(echo 1) /mnt/boot >>$SALIDA 2>&1 || STOP ;;
	bios) 
		(echo -e "o\nn\np\n1\n\n\nt\n3\n83\nw\n" | fdisk -w always $DISCO >>$SALIDA 2>&1) && DONE || STOP
		yes | mkfs.ext4 $DISCO$(echo 1) >>$SALIDA 2>&1 || STOP
		mount $DISCO$(echo 1) /mnt >>$SALIDA 2>&1 || STOP ;;
esac

echo -e "\n>>Instalando base del sistema\c"
pacstrap /mnt linux-zen linux-zen-headers linux-firmware base >>$SALIDA 2>&1 && DONE || STOP

echo -e "\n>>Instalando utilidades basicas\c"
(grep 'Intel' /proc/cpuinfo >/dev/null && CPU='intel-ucode') && (grep 'AMD' /proc/cpuinfo >/dev/null && CPU='amd-ucode') || CPU='amd-ucode intel-ucode'
echo "pacman --noconfirm -S nano man man-db man-pages man-pages-es bash-completion neovim neofetch networkmanager $CPU git base-devel sudo ntfs-3g || exit 1" | CHROOTF

echo -e "\n>>Configurando sistema\c"
echo "sudo rm -rf /tmp/arch-distro; cd /tmp && git clone https://github.com/CambonOS/arch-distro.git && sudo bash arch-distro/cambonos-cmd.sh" > /mnt/usr/bin/cambonos-cmd && chmod 755 /mnt/usr/bin/cambonos-cmd && echo "cambonos-cmd" | arch-chroot /mnt >$SALIDA 2>&1
echo 'cd /tmp && git clone https://github.com/CambonOS/arch-distro.git && cp -r arch-distro/etc/* /etc' | arch-chroot /mnt >$SALIDA 2>&1
echo "ln -sf /usr/share/zoneinfo/Región/Ciudad /etc/localtime && hwclock --localtime || exit 1" | CHROOT

echo -e "\n>>Generando archivo fstab\c"
genfstab -U /mnt >> /mnt/etc/fstab && DONE || STOP

echo -e "\n>>Configurando red\c"
echo "$NOMBRE" >/mnt/etc/hostname && echo -e "127.0.0.1	localhost\n::1		localhost\n127.0.1.1	$NOMBRE" >/mnt/etc/hosts && echo 'systemctl enable NetworkManager.service || exit 1' | CHROOT

echo -e "\n>>Creando usuario\c"
echo "groupadd -g 513 sudo && useradd -m -s /bin/bash -g sudo $USER && (echo -e '$PASS\n$PASS' | passwd $USER) || exit 1" | CHROOT

echo -e "\n>>Instalando drivers graficos\c"
(lspci | grep VGA) | grep -o 'NVIDIA' >/dev/null && GPU='nvidia'
(lspci | grep VGA) | grep -o 'AMD' >/dev/null && GPU='amd'
(lspci | grep VGA) | grep -o 'Intel' >/dev/null && GPU='intel'
(lspci | grep VGA) | grep -o 'VMware' >/dev/null && GPU='vmware'
case $GPU in
	amd)
		echo "pacman --noconfirm -S xf86-video-vesa xf86-video-amdgpu lib32-mesa mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader || exit 1" | CHROOT ;;
	nvidia)
		echo "pacman --noconfirm -S xf86-video-vesa nvidia lib32-nvidia-utils nvidia-utils nvidia-settings nvidia-dkms vulkan-icd-loader lib32-vulkan-icd-loader || exit 1" | CHROOT ;;
	intel)
		echo "pacman --noconfirm -S xf86-video-vesa xf86-video-intel lib32-mesa mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader || exit 1" | CHROOT ;;
	vmware)
		echo "pacman --noconfirm -S xf86-video-vesa xf86-video-vmware lib32-mesa mesa || exit 1" | CHROOT ;;
	*)
		echo "pacman --noconfirm -S xf86-video-vesa xf86-video-amdgpu lib32-mesa mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader nvidia lib32-nvidia-utils nvidia-utils nvidia-settings nvidia-dkms xf86-video-vmware || exit 1" | CHROOT ;;
esac

echo -e "\n>>Instalando entorno grafico\c"
case $TYPE in
	cambonos-server)
		DONE ;;
	cambonos)
		echo "pacman --noconfirm -S gdm nautilus gnome-control-center gnome-tweaks && systemctl enable gdm.service || exit 1" | CHROOT ;;
	cambonos-lite)
		echo "pacman --noconfirm -S xfce4 lightdm && systemctl enable lightdm.service || exit 1" | CHROOT ;;
esac

echo -e "\n>>Instalando grub\c"
case $GRUB in
	bios)
		echo "pacman --noconfirm -S grub && grub-install --target=i386-pc $DISCO && grub-mkconfig -o /boot/grub/grub.cfg || exit 1" | CHROOTF ;;
	uefi)
		echo "pacman --noconfirm -S grub efibootmgr && grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=COS && grub-mkconfig -o /boot/grub/grub.cfg || exit 1" | CHROOTF ;;
esac

echo -e "\n>>Instalando trizen\c"
cp /mnt/etc/sudoers /mnt/etc/sudoers.bk
echo -e "\n%sudo ALL=(ALL) NOPASSWD: ALL" > /mnt/etc/sudoers
echo "echo 'cd /tmp && git clone https://aur.archlinux.org/trizen.git && cd trizen && makepkg --noconfirm -si || exit 1' | su $USER || exit 1" | CHROOT

echo -e "\n>>Instalando programas adicionales\c"
echo "echo 'trizen --noconfirm -S zramd brave-bin menulibre gedit gnome-calculator alacritty steam virtualbox virtualbox-guest-iso virtualbox-ext-oracle || exit 1' | su $USER || exit 1" | CHROOT
mv /mnt/etc/sudoers.bk /mnt/etc/sudoers

echo -e "\n>>Activando zswap \c"
systemctl enable zramd.service | CHROOT

echo -e "\n>>Terminando instalacion"
swapoff $SWAP
echo 'locale-gen' | CHROOT
