#!/bin/bash

##Definicion de grupos
ARCH () {
	arch-chroot /mnt
}

STOP () {
	echo ""
	echo "##################################"
	echo "### ERROR EN LA INSTALACION!!! ###"
	echo "##################################"
	echo ""
	echo "##################################"
	echo "### Pulse ENTER para continuar ###"
	echo "##################################"
	echo ""
	umount -R /mnt
	rm -rf /mnt/*
	exit 1
}

##Definicion variables
NOMBRE=$1
USERNAME=$2
USER=$(echo $USERNAME | awk '{print tolower($0)}')
PASS=$3
DG=$4
SSH=$5
UPGRADE=$6
ESCRITORIO=$7
DISCO=$8

# Mensaje final instalacion
echo ""
echo "#################################"
echo "### ¡¡INICIANDO INSTALACION!! ###"
echo "#################################"
echo ""
echo "#################################"
echo "### No pulse ninguna tecla    ###"
echo "### hasta que se termine.     ###"
echo "#################################"
echo ""

# Habilitar NTP
timedatectl set-ntp true

# Generar lista de mirrors
reflector -l 10 -f 5 --save /etc/pacman.d/mirrorlist

# Actualizacion de las claves de Arch Linux
pacman --noconfirm -Sy archlinux-keyring

# Creacion de la raiz del sistema
pacstrap /mnt linux-zen linux-zen-headers linux-firmware base || STOP

# Generar fichero fstab del sistema
genfstab -U /mnt >> /mnt/etc/fstab || STOP

# Modificar configuraciones de root
echo "usermod -s /bin/zsh root" | ARCH # Cambio shell
cp -rv installer/cambonos-fs/etc/skel/.config /mnt/root # Carpeta .config del skel
cp -v installer/cambonos-fs/etc/skel/.* /mnt/root/ # Ficheros del skel

# Definicion de los paquetes microcode CPU
(grep 'Intel' /proc/cpuinfo >/dev/null && CPU='intel-ucode') || (grep 'AMD' /proc/cpuinfo >/dev/null && CPU='amd-ucode') || CPU='amd-ucode intel-ucode'

# Instalacion paquetes basicos
echo "pacman --noconfirm -Sy lsb-release tree htop xclip micro vim man man-db man-pages man-pages-es bash-completion networkmanager ntp systemd-resolvconf $CPU git wget base-devel sudo ntfs-3g || exit 1" | ARCH || STOP

# Habilitar repositorios multilib
echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" >>/mnt/etc/pacman.conf

# Instalacion drivers graficos
if [[ $DG = s ]] || [[ $DG = S ]] || [[ $DG = si ]] || [[ $DG = Si ]]
then
	GPU='DESCONOCIDA'
	(lspci | grep VGA) | grep -o 'VMware' >/dev/null && GPU='vmware'
	(lspci | grep VGA) | grep -o 'Intel' >/dev/null && GPU='intel'
	(lspci | grep VGA) | grep -o 'AMD' >/dev/null && GPU='amd'
	(lspci | grep VGA) | grep -o 'NVIDIA' >/dev/null && GPU='nvidia'
	(lspci | grep "3D controller") | grep -o 'VMware' >/dev/null && GPU='vmware'
	(lspci | grep "3D controller") | grep -o 'Intel' >/dev/null && GPU='intel'
	(lspci | grep "3D controller") | grep -o 'AMD' >/dev/null && GPU='amd'
	(lspci | grep "3D controller") | grep -o 'NVIDIA' >/dev/null && GPU='onvidia'
	case $GPU in
		amd)
			echo "pacman --noconfirm -Sy xf86-video-vesa xf86-video-amdgpu lib32-mesa mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader || exit 1" | ARCH ;;
		nvidia)
			echo "pacman --noconfirm -Sy xf86-video-vesa nvidia lib32-nvidia-utils nvidia-utils nvidia-settings nvidia-dkms vulkan-icd-loader lib32-vulkan-icd-loader || exit 1" | ARCH ;;
  		onvidia)
			echo "pacman --noconfirm -Sy xf86-video-vesa nvidia lib32-nvidia-utils nvidia-utils nvidia-settings nvidia-dkms vulkan-icd-loader lib32-vulkan-icd-loader optimus-manager optimus-manager-qt || exit 1" | ARCH ;;
  		intel)
			echo "pacman --noconfirm -Sy xf86-video-vesa xf86-video-intel lib32-mesa mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader || exit 1" | ARCH ;;
		vmware)
			echo "pacman --noconfirm -Sy virtualbox-guest-utils xf86-video-vesa xf86-video-vmware lib32-mesa mesa || exit 1" | ARCH ;;
		*)
			echo "pacman --noconfirm -Sy xf86-video-vesa lib32-mesa mesa vulkan-icd-loader lib32-vulkan-icd-loader || exit 1" | ARCH ;;
	esac
fi

# Instalacion GRUB
ls /sys/firmware/efi/efivars >/dev/null 2>&1 && GRUB='uefi' || GRUB='bios'
case $GRUB in
	uefi)
		echo "pacman --noconfirm -Sy grub efibootmgr os-prober grub-theme-vimix && grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=COS || exit 1" | ARCH || STOP
		;;
	bios)
		echo "pacman --noconfirm -Sy grub os-prober grub-theme-vimix && grub-install --target=i386-pc /dev/$DISCO || exit 1" | ARCH || STOP
		;;
esac

# Configuraciones de Red
cp /etc/NetworkManager/system-connections/* /mnt/etc/NetworkManager/system-connections
sed -i /interface/d /mnt/etc/NetworkManager/system-connections/*
echo "$NOMBRE" >/mnt/etc/hostname
echo -e "127.0.0.1	localhost\n::1		localhost\n127.0.1.1	$NOMBRE" >/mnt/etc/hosts
echo 'systemctl enable NetworkManager.service && systemctl enable ntpd.service && systemctl enable systemd-resolved.service || exit 1' | ARCH

# Instalacion de yay
echo "useradd -m -d /home/.updates -u 999 updates && passwd --lock updates || exit 1" | ARCH
echo -e "\n%updates ALL=(ALL) NOPASSWD: ALL" >> /mnt/etc/sudoers
echo "echo 'cd /tmp && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg --noconfirm -si || exit 1' | su updates || exit 1" | ARCH

# Instalacion de utilidades adicionales
echo "echo 'yay --noconfirm -Sy neofetch zsh zsh-completions zsh-autosuggestions zsh-syntax-highlighting zsh-theme-powerlevel10k ttf-meslo-nerd-font-powerlevel10k xdg-user-dirs zramd || exit 1' | su updates || exit 1" | ARCH
echo "systemctl enable zramd.service || exit 1" | ARCH
if [[ $GPU = vmware ]]
then echo "echo 'yay --noconfirm -Sy virtualbox-guest-utils || exit 1' | su updates || exit 1" | ARCH && echo "systemctl enable vboxservice.service" | ARCH
fi

# Instalacion XFCE
echo $ESCRITORIO | grep "1" >/dev/nul && INSTALL=true || INSTALL=false
if [[ $INSTALL = true ]]
then	
	echo 'echo "cd /tmp; git clone https://github.com/Cambon18/xfce && cd xfce && bash archie.sh" | su updates' | ARCH
fi

# Instalacion XFCE(gaming)
echo $ESCRITORIO | grep "2" >/dev/nul && GAMING=true || GAMING=false
if [[ $GAMING = true ]]
then	
	echo 'echo "cd /tmp; git clone https://github.com/Cambon18/xfce && cd xfce && bash archie.sh" | su updates' | ARCH
	echo "echo 'yay --noconfirm -Sy steam || exit 1' | su updates || exit 1" | ARCH
	echo "groupadd -r autologin || exit 1" | ARCH
	sed -i "s/#autologin-user=/autologin-user=$USER/" /mnt/etc/lightdm/lightdm.conf
	echo "nm-online && steam -gamepadui &" >/mnt/etc/skel/.xprofile
fi

# Instalacion Qtile
echo $ESCRITORIO | grep "3" >/dev/nul && INSTALL=true || INSTALL=false
if [[ $INSTALL = true ]]
then
	echo 'echo "cd /tmp; git clone https://github.com/Cambon18/qtile && cd qtile && bash archie.sh" | su updates' | ARCH
fi

# Instalacion ssh
if [[ $SSH = s ]] || [[ $SSH = si ]] || [[ $SSH = S ]] || [[ $SSH = Si ]]
then
	echo "pacman --noconfirm -Sy openssh && sed -i s/#X11Forwarding\ no/X11Forwarding\ yes/ /etc/ssh/sshd_config; systemctl enable sshd.service || exit 1" | ARCH
fi

# Configuraciones CambonOS
cp -rv installer/cambonos-fs/* /mnt

# Configuracion hora
echo "ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime && hwclock --systohc" | ARCH

# Creacion usuario
echo "useradd -m -c $USERNAME -s /bin/zsh -g wheel -G users,rfkill,sys $USER && (echo -e '$PASS\n$PASS' | passwd $USER)" | ARCH
if [[ $GPU = vmware ]]
then echo "usermod -aG vboxsf $USER" | ARCH
fi
if [[ $GAMING = true ]]
then echo "usermod -aG autologin $USER" | ARCH
fi

# Configuracion cambonos-upgrade
chmod 4750 /mnt/usr/bin/cambonos-upgrade
echo "chown updates:wheel /usr/bin/cambonos-upgrade" | ARCH
echo "chsh -s /usr/bin/nologin updates" | ARCH
if [[ $UPGRADE = s ]] || [[ $UPGRADE = si ]] || [[ $UPGRADE = S ]] || [[ $UPGRADE = Si ]]
then
	echo "systemctl enable cambonos-upgrade.service || exit 1" | ARCH
fi

# Generacion locales
echo "locale-gen" | ARCH

# Actualizacion del equipo, eliminacion de paquetes huerfanos y actualizacion configuracion GRUB
echo "cambonos-upgrade" | ARCH

# Mensaje final instalacion
echo ""
echo "##################################"
echo "### ¡¡¡INSTALACION COMPLETA!!! ###"
echo "##################################"
echo ""
echo "##################################"
echo "### Pulse ENTER para continuar ###"
echo "##################################"
echo ""
