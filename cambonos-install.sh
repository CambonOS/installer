#!/bin/bash
#
NOCOLOR='\033[0m'
RED='\033[1;31m'
GREEN='\033[1;32m'
SALIDA='/tmp/salida'
DM='false'

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
	umount /mnt/boot >>$SALIDA 2>&1; umount /mnt >>$SALIDA 2>&1; rm -rf /mnt >>$SALIDA 2>&1; mkdir /mnt; exit
}

SOFTWARE () {
	HEAD
	echo -e "
	****** Software a instalar ******

 Entorno de escritorio:
  1-Xfce		2-KDE			3-Gnome
  4-Mate		5-Cinnamon		6-LXDE

 Suite ofimatica:
  7-LibreOffice		8-OpenOffice		9-Calligra

 Editor de texto adicional:
  10-Neovim		11-Sublime text		12-Notepad++

 Gaming:
  13-GameHub		14-Steam		15-Chiaki
  16-Lutris

 Virtualizacion:
  19-VirtualBox		20-Gnome Boxes

 Musica:
  22-Spotify		23-Apple music		24-Rhythmbox

 Navegadores:
  25-Firefox		26-Brave		27-Chrome
  28-Opera		29-Chromiun

 Escribir los numeros separados: \c" && read NUMBER
}

DM () {
	if [[ $DM = false ]]
	then
		echo -e "\n>>Instalando display manager\c"
		echo "echo 'trizen --noconfirm -Sy xorg-server lightdm lightdm-settings numlockx' | su $USER && systemctl enable lightdm.service" | ARCH && DONE || ERROR
		cp -r arch-distro/configs/lightdm/* /mnt
		cp -r share/* /mnt/usr/share
		DM='true'
	fi
}

INSTALL () {
	case $CONT in
		1) AL='Xfce'; APP='xfce4-appfinder xfce4-panel xfce4-power-manager xfce4-session xfce4-settings xfce4-screensaver xfconf xfdesktop xfwm4 network-manager-applet system-config-printer blueberry qt5-connectivity bluez bluez-hid2hci bluez-libs bluez-plugins bluez-qt bluez-tools bluez-utils bluez-cups nautilus gnome-disk-utility alacritty mousepad vlc epdfview ristretto galculator xfce4-pulseaudio-plugin pulseaudio pulseaudio-jack pulseaudio-bluetooth pavucontrol menulibre' && DM ;;
		2) AL='KDE'; APP='plasma' && DM ;;
		3) AL='Gnome'; APP='gnome' && DM ;;
		4) AL='Mate'; APP='mate' && DM ;;
		5) AL='Cinnamon'; APP='cinnamon' && DM ;;
		6) AL='LXDE'; APP='lxde-gtk3' && DM ;;
		7) AL='LibreOffice'; APP='libreoffice-fresh libreoffice-fresh-es' ;;
		8) AL='OpenOffice'; APP='openoffice-bin' ;;
		9) AL='Calligra'; APP='calligra' ;;
		10) AL='Neovim'; APP='neovim' ;;
		11) AL='Sublime text'; APP='sublime-text-3' ;;
		12) AL='Notepad++'; APP='notepadqq' ;;
		13) AL='Gamehub'; APP='gamehub wine-staging' ;;
		14) AL='Steam'; APP='steam wine-staging' ;;
		15) AL='Chiaki'; APP='chiaki' ;;
		16) AL='Lutris'; APP='lutris wine-staging' ;;
		19) AL='VirtualBox'; APP='virtualbox virtualbox-guest-iso virtualbox-ext-oracle' ;;
		20) AL='Gnome box'; APP='gnome-boxes' ;;
		22) AL='Spotify'; APP='spotify-snap' ;;
		23) AL='Apple Music'; APP='apple-music-electron' ;;
		24) AL='Rhythmbox'; APP='rhythmbox' ;;
		25) AL='Firefox'; APP='firefox-i18n-es-es' ;;
		26) AL='Brave'; APP='brave-bin' ;;
		27) AL='Chrome'; APP='google-chrome' ;;
		28) AL='Opera'; APP='opera' ;;
		29) AL='Chromium'; APP='chromium' ;;
		69) AL='paquetes del sistema'; APP='zramd xdg-user-dirs' ;;
	esac
	echo -e "\n>>Instalando $AL\c"
	echo "echo 'trizen --noconfirm -Sy $APP || exit 1' | su $USER || exit 1" | ARCH && DONE || ERROR
	case $CONT in
		1) cp -r arch-distro/configs/xfce/* /mnt; echo "systemctl enable bluetooth.service" | ARCH ;;
		2) echo "pacman --noconfirm -Rns xf86-video-intel" | ARCH ;;
		5) echo "pacman --noconfirm -Rns xf86-video-intel" | ARCH ;;
		9) cp arch-distro/configs/desktop/org.kde.karbon.desktop /mnt/usr/share/applications ;;
		10) cp arch-distro/configs/desktop/nvim.desktop /mnt/usr/share/applications ;;
		12) cp arch-distro/configs/desktop/notepadqq.desktop /mnt/usr/share/applications ;;
		14) rm /mnt/usr/share/applications/steam.desktop && cp arch-distro/configs/desktop/steam.desktop /mnt/usr/share/applications ;;
		19) cp arch-distro/configs/desktop/virtualbox.desktop /mnt/usr/share/applications ;;
		20) cp arch-distro/configs/desktop/org.gnome.Boxes.desktop /mnt/usr/share/applications ;;
		69)
			echo -e "\n>>Configurando CambonOS\c"
			echo "systemctl enable zramd.service; systemctl enable xdg-user-dirs-update.service; systemctl enable cups.service" | ARCH
			cp -r grub/* /mnt/boot/grub
			cp -r arch-distro/configs/cambonos/* /mnt && chmod 775 /mnt/usr/bin/cambonos
			echo "ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime && hwclock --systohc" | ARCH
			echo "userdel -r $USER && useradd -m -s /bin/bash -g sudo -G lp,rfkill $USER && (echo -e '$PASS\n$PASS1' | passwd $USER)" | ARCH
			echo "locale-gen" | ARCH
			echo "cambonos upgrade" | ARCH
			DONE ;;
	esac
}

SUDO () {
	echo -e "\n>>Contraseña del usuario: \c" && read -s PASS
	echo -e "\n\n>>Repetir contraseña: \c" && read -s PASS1
	if [[ $PASS = $PASS1 ]]
	then sleep 0
	else echo && SUDO
	fi
}

ROOT () {
	echo -e "\n>>Contraseña del usuario administrador (root): \c" && read -s SECRET
	echo -e "\n\n>>Repetir contraseña: \c" && read -s SECRET1
	if [[ $SECRET = $SECRET1 ]]
	then sleep 0
	else echo && ROOT
	fi
}

############################################################################################################
############################################################################################################
############################################################################################################

HEAD
echo -e "\n>>Listando discos\n" && lsblk -o NAME,SIZE,VENDOR,MODEL -d
echo -e "\n>>En que disco quieres instalar el sistema: \c" && read -e -i "/dev/sd" DISCO
echo -e "\n>>Nombre del equipo: \c" && read NOMBRE
ROOT
echo -e "\n\n>>Nombre para el nuevo usuario: \c" && read USER
SUDO
SOFTWARE
HEAD

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
(pacstrap /mnt linux-zen linux-zen-headers linux-firmware base >>$SALIDA 2>&1 && genfstab -U /mnt >> /mnt/etc/fstab) && DONE || STOP

echo -e "\n>>Instalando paquetes basicos\c"
(grep 'Intel' /proc/cpuinfo >/dev/null && CPU='intel-ucode') || (grep 'AMD' /proc/cpuinfo >/dev/null && CPU='amd-ucode') || CPU='amd-ucode intel-ucode'
echo "pacman --noconfirm -Sy nano man man-db man-pages man-pages-es bash-completion neofetch networkmanager $CPU git base-devel sudo ntfs-3g || exit 1" | ARCH && DONE || STOP

echo -e "\n>>Configurando red\c"
echo "$NOMBRE" >/mnt/etc/hostname && echo -e "127.0.0.1	localhost\n::1		localhost\n127.0.1.1	$NOMBRE" >/mnt/etc/hosts && echo 'systemctl enable NetworkManager.service || exit 1' | ARCH && DONE || ERROR

echo -e "\n>>Instalando drivers graficos\c"
echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" >>/mnt/etc/pacman.conf
(lspci | grep VGA) | grep -o 'NVIDIA' >/dev/null && GPU='nvidia'
(lspci | grep VGA) | grep -o 'AMD' >/dev/null && GPU='amd'
(lspci | grep VGA) | grep -o 'Intel' >/dev/null && GPU='intel'
(lspci | grep VGA) | grep -o 'VMware' >/dev/null && GPU='vmware'
case $GPU in
	amd)
		echo "pacman --noconfirm -Sy xf86-video-vesa xf86-video-amdgpu lib32-mesa mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader || exit 1" | ARCH && DONE || ERROR ;;
	nvidia)
		echo "pacman --noconfirm -Sy xf86-video-vesa nvidia lib32-nvidia-utils nvidia-utils nvidia-settings nvidia-dkms vulkan-icd-loader lib32-vulkan-icd-loader || exit 1" | ARCH && DONE || ERROR ;;
	intel)
		echo "pacman --noconfirm -Sy xf86-video-vesa xf86-video-intel lib32-mesa mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader || exit 1" | ARCH && DONE || ERROR ;;
	vmware)
		echo "pacman --noconfirm -Sy virtualbox-guest-utils xf86-video-vesa xf86-video-vmware lib32-mesa mesa || exit 1" | ARCH && DONE || ERROR ;;
	*)
		echo "pacman --noconfirm -Sy xf86-video-vesa xf86-video-amdgpu lib32-mesa mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader nvidia lib32-nvidia-utils nvidia-utils nvidia-settings nvidia-dkms xf86-video-vmware || exit 1" | ARCH && DONE || ERROR ;;
esac

echo -e "\n>>Instalando grub\c"
case $GRUB in
	bios)
		echo "pacman --noconfirm -Sy grub && grub-install --target=i386-pc $DISCO || exit 1" | ARCH && DONE || STOP ;;
	uefi)
		echo "pacman --noconfirm -Sy grub efibootmgr && grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=COS || exit 1" | ARCH && DONE || STOP ;;
esac

echo -e "\n>>Configurando usuarios\c"
(echo "groupadd -g 513 sudo && useradd -m -s /bin/bash -g sudo $USER && (echo -e '$PASS\n$PASS1' | passwd $USER) || exit 1" | ARCH) && echo -e "(echo -e '$SECRET\n$SECRET1' | passwd root) || exit 1" | ARCH && DONE || ERROR

echo -e "\n>>Instalando trizen\c"
echo -e "\n%sudo ALL=(ALL) NOPASSWD: ALL" >> /mnt/etc/sudoers
echo "echo 'cd /tmp && git clone https://aur.archlinux.org/trizen.git && cd trizen && makepkg --noconfirm -si || exit 1' | su $USER || exit 1" | ARCH && DONE || ERROR

CONT='1'
while [ $CONT -lt 70 ]
do
	echo .$NUMBER,69. | grep [[:blank:][:punct:]]$CONT[[:blank:][:punct:]] >/dev/null && INSTALL
	((CONT++))
done
