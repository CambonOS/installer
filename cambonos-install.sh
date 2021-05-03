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
  umount /mnt/boot >>$SALIDA 2>&1; umount /mnt >>$SALIDA 2>&1; rm -rf /mnt >>$SALIDA 2>&1; mkdir /mnt ; exit 1
}

CHROOT () {
	arch-chroot /mnt >>$SALIDA 2>&1 && DONE || ERROR
}

CHROOTF () {
	arch-chroot /mnt >>$SALIDA 2>&1 && DONE || STOP
}

SOFTWARE () {
	HEAD
	echo -e "
***** Software a instalar *****

Emulador de terminal:
1-Alacritty		2-Gnome Terminal	3-Konsole
4-Terminator		5-Xterm

Suite ofimatica:
7-LibreOffice		8-OpenOffice		9-Calligra

Programas basicos:
10-Wine			11-Editor de textos	12-Calculadora

Gaming:
13-GameHub		14-Steam		15-Chiaki
16-Lutris

Virtualizacion:
19-VirtualBox		20-Gnome Boxes

Multimedia:
22-Video (VLC)		23-Fotos (EOG)		24-Musica (Rhythmbox)

Navegadores:
25-Firefox		26-Brave		27-Chrome
28-Opera		29-Chromiun

Escribir los numeros separados: \c" && read NUMBER
}

INSTALL () {
	case $CONT in
		0) APP='zramd' ;;
		1) APP='alacritty' ;;
		2) APP='gnome-terminal' ;;
		3) APP='konsole' ;;
		4) APP='terminator' ;;
		5) APP='xterm' ;;
		7) APP='libreoffice-fresh libreoffice-fresh-es' ;;
		8) APP='openoffice-bin' ;;
		9) APP='calligra' ;;
		10) APP='wine-staging' ;;
		11) APP='gedit' ;;
		12) APP='gnome-calculator' ;;
		13) APP='gamehub' ;;
		14) APP='steam' ;;
		15) APP='chiaki' ;;
		16) APP='lutris' ;;
		19) APP='virtualbox virtualbox-guest-iso virtualbox-ext-oracle' ;;
		20) APP='gnome-boxes' ;;
		22) APP='vlc' ;;
		23) APP='eog' ;;
		24) APP='rhythmbox' ;;
		25) APP='firefox-i18n-es-es' ;;
		26) APP='brave-bin' ;;
		27) APP='google-chrome' ;;
		28) APP='opera' ;;
		29) APP='chromium' ;;
	esac
	echo "echo 'trizen --noconfirm -Sy $APP || exit 1' | su $USER || exit 1" | arch-chroot /mnt >>$SALIDA 2>&1
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
echo -e "\n>>Nombre del equipo: \c" && read NOMBRE
ROOT
echo -e "\n\n>>Nombre para el nuevo usuario: \c" && read USER
SUDO
SOFTWARE
HEAD

echo -e "\n>>Actualizando reloj\c"
timedatectl set-ntp true >>$SALIDA 2>&1 && DONE || ERROR

echo -e "\n>>Particionando disco\c"
ls /sys/firmware/efi/efivars >/dev/null 2>&1 && GRUB='uefi' || GRUB='bios'
case $GRUB in
	uefi) 
		(echo -e "g\nn\n1\n\n+512M\nn\n2\n\n\nt\n1\n1\nt\n2\n23\nw\n" | fdisk -w always $DISCO >>$SALIDA 2>&1) || STOP 
		yes | mkfs.fat -F32 $DISCO$(echo 1) >>$SALIDA 2>&1 || STOP
		yes | mkfs.ext4 $DISCO$(echo 2) >>$SALIDA 2>&1 || STOP
		mount $DISCO$(echo 2) /mnt >>$SALIDA 2>&1 || STOP 
		mkdir /mnt/boot >>$SALIDA 2>&1 || STOP
		mount $DISCO$(echo 1) /mnt/boot >>$SALIDA 2>&1 || STOP 
		DONE ;;
	bios) 
		(echo -e "o\nn\np\n1\n\n\nt\n3\n83\nw\n" | fdisk -w always $DISCO >>$SALIDA 2>&1) || STOP
		yes | mkfs.ext4 $DISCO$(echo 1) >>$SALIDA 2>&1 || STOP
		mount $DISCO$(echo 1) /mnt >>$SALIDA 2>&1 || STOP 
		DONE ;;
esac

echo -e "\n>>Instalando base del sistema\c"
pacstrap /mnt linux-zen linux-zen-headers linux-firmware base >>$SALIDA 2>&1 && DONE || STOP

echo -e "\n>>Instalando utilidades basicas\c"
(grep 'Intel' /proc/cpuinfo >/dev/null && CPU='intel-ucode') && (grep 'AMD' /proc/cpuinfo >/dev/null && CPU='amd-ucode') || CPU='amd-ucode intel-ucode'
echo "pacman --noconfirm -Sy nano man man-db man-pages man-pages-es bash-completion neovim neofetch networkmanager $CPU git base-devel sudo ntfs-3g || exit 1" | CHROOTF

echo -e "\n>>Generando archivo fstab\c"
genfstab -U /mnt >> /mnt/etc/fstab && DONE || STOP

echo -e "\n>>Configurando red\c"
echo "$NOMBRE" >/mnt/etc/hostname && echo -e "127.0.0.1	localhost\n::1		localhost\n127.0.1.1	$NOMBRE" >/mnt/etc/hosts && echo 'systemctl enable NetworkManager.service || exit 1' | CHROOT

echo -e "\n>>Creando usuario\c"
(echo "groupadd -g 513 sudo && useradd -m -s /bin/bash -g sudo $USER && (echo -e '$PASS\n$PASS1' | passwd $USER) || exit 1" | arch-chroot /mnt >>$SALIDA 2>&1) && echo -e "(echo -e '$SECRET\n$SECRET1' | passwd root) || exit 1" | CHROOT

echo -e "\n>>Instalando drivers graficos\c"
echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" >>/mnt/etc/pacman.conf
(lspci | grep VGA) | grep -o 'NVIDIA' >/dev/null && GPU='nvidia'
(lspci | grep VGA) | grep -o 'AMD' >/dev/null && GPU='amd'
(lspci | grep VGA) | grep -o 'Intel' >/dev/null && GPU='intel'
(lspci | grep VGA) | grep -o 'VMware' >/dev/null && GPU='vmware'
case $GPU in
	amd)
		echo "pacman --noconfirm -Sy xf86-video-vesa xf86-video-amdgpu lib32-mesa mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader || exit 1" | CHROOT ;;
	nvidia)
		echo "pacman --noconfirm -Sy xf86-video-vesa nvidia lib32-nvidia-utils nvidia-utils nvidia-settings nvidia-dkms vulkan-icd-loader lib32-vulkan-icd-loader || exit 1" | CHROOT ;;
	intel)
		echo "pacman --noconfirm -Sy xf86-video-vesa xf86-video-intel lib32-mesa mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader || exit 1" | CHROOT ;;
	vmware)
		echo "pacman --noconfirm -Sy virtualbox-guest-utils virtualbox-guest-utils-nox xf86-video-vesa xf86-video-vmware lib32-mesa mesa || exit 1" | CHROOT ;;
	*)
		echo "pacman --noconfirm -Sy xf86-video-vesa xf86-video-amdgpu lib32-mesa mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader nvidia lib32-nvidia-utils nvidia-utils nvidia-settings nvidia-dkms xf86-video-vmware || exit 1" | CHROOT ;;
esac

echo -e "\n>>Instalando entorno grafico\c"
echo "pacman --noconfirm -Sy gdm nautilus gnome-control-center gnome-tweaks && systemctl enable gdm.service || exit 1" | CHROOT

echo -e "\n>>Instalando grub\c"
case $GRUB in
	bios)
		echo "pacman --noconfirm -Sy grub && grub-install --target=i386-pc $DISCO || exit 1" | CHROOTF ;;
	uefi)
		echo "pacman --noconfirm -Sy grub efibootmgr && grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=COS || exit 1" | CHROOTF ;;
esac

echo -e "\n>>Instalando trizen\c"
echo -e "\n%sudo ALL=(ALL) NOPASSWD: ALL" >> /mnt/etc/sudoers
echo "echo 'cd /tmp && git clone https://aur.archlinux.org/trizen.git && cd trizen && makepkg --noconfirm -si || exit 1' | su $USER || exit 1" | CHROOT

echo -e "\n>>Instalando programas adicionales\c"
CONT='0'
while [$CONT < 35]
do
	echo $NUMBER,0. | grep $CONT[[:blank:][:punct:]] >/dev/null && INSTALL
	((CONT++))
done
DONE

echo -e "\n>>Activando zswap\c"
echo "systemctl enable zramd.service" | CHROOT

echo -e "\n>>Configurando sistema\c"
echo 'cd /tmp && git clone https://github.com/CambonOS/arch-distro.git && cp -r arch-distro/etc/* /etc && cp -r arch-distro/usr/* /usr' | arch-chroot /mnt >>$SALIDA 2>&1
echo 'cd /tmp && git clone https://github.com/CambonOS/arch-distro.git && bash arch-distro/cambonos.sh upgrade -b main && grub-mkconfig -o /boot/grub/grub.cfg' | arch-chroot /mnt >>$SALIDA 2>&1
echo "ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime && hwclock --systohc || exit 1" | CHROOT

echo -e "\n>>Terminando instalacion\c"
echo 'locale-gen' | CHROOT
