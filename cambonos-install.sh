#!/bin/bash

##Definicion de grupos
ARCH () {
	arch-chroot /mnt
}

STOP () {
	echo "100" >/tmp/PRG
	echo "1" >/tmp/FIN_ERR
	umount -R /mnt
	rm -rf /mnt/*
	exit 1
}

##Definicion variables
echo "0" >/tmp/FIN_ERR
NOMBRE=$1
ADMINNAME=$2
ADMINUSER=$(echo $ADMINNAME | awk '{print tolower($0)}')
ADMINPASS=$3
USERNAME=$4
USERUSER=$(echo $USERNAME | awk '{print tolower($0)}')
USERPASS=$5
DG=$6
SSH=$7
UPGRADE=$8
ESCRITORIO=$9
DISCO=${10}

# Habilitar NTP
timedatectl set-ntp true
echo "2" >/tmp/PRG

# Generar lista de mirrors
reflector -l 10 -f 5 --save /etc/pacman.d/mirrorlist
echo "10" >/tmp/PRG

# Actualizacion de las claves de Arch Linux
pacman --noconfirm -Sy archlinux-keyring
echo "15" >/tmp/PRG

# Creacion de la raiz del sistema
pacstrap /mnt linux-zen linux-zen-headers linux-firmware base || STOP
echo "30" >/tmp/PRG

# Generar fichero fstab del sistema
dd if=/dev/zero of=/mnt/swapfile bs=1M count=4k status=progress
chmod 0600 /mnt/swapfile
mkswap -U clear /mnt/swapfile
swapon /mnt/swapfile
genfstab -U /mnt >> /mnt/etc/fstab || STOP
echo "33" >/tmp/PRG

# Modificar configuraciones de root
echo "usermod -s /bin/zsh root" | ARCH # Cambio shell
cp -rv installer/cambonos-fs/etc/skel/.config /mnt/root # Carpeta .config del skel
cp -v installer/cambonos-fs/etc/skel/.* /mnt/root/ # Ficheros del skel
echo "passwd --lock root" | ARCH
echo "35" >/tmp/PRG

# Definicion de los paquetes microcode CPU
(grep 'Intel' /proc/cpuinfo >/dev/null && CPU='intel-ucode') || (grep 'AMD' /proc/cpuinfo >/dev/null && CPU='amd-ucode') || CPU='amd-ucode intel-ucode'
echo "37" >/tmp/PRG

# Instalacion paquetes basicos
echo "pacman --noconfirm -Sy lsb-release tree htop xclip micro vim man man-db man-pages man-pages-es bash-completion networkmanager ntp systemd-resolvconf $CPU git wget base-devel sudo ntfs-3g dosfstools exfat-utils || exit 1" | ARCH || STOP
echo "45" >/tmp/PRG

# Habilitar repositorios multilib
echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" >>/mnt/etc/pacman.conf
echo "47" >/tmp/PRG

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
echo "55" >/tmp/PRG

# Configuraciones de Red
cp /etc/NetworkManager/system-connections/* /mnt/etc/NetworkManager/system-connections
sed -i /interface/d /mnt/etc/NetworkManager/system-connections/*
echo "$NOMBRE" >/mnt/etc/hostname
echo -e "127.0.0.1	localhost\n::1		localhost\n127.0.1.1	$NOMBRE" >/mnt/etc/hosts
echo 'systemctl enable NetworkManager.service && systemctl enable ntpd.service && systemctl enable systemd-resolved.service || exit 1' | ARCH
echo "60" >/tmp/PRG

# Instalacion de yay
echo "groupadd -g 777 updates" | ARCH
echo "useradd -m -d /home/.updates -g updates -u 777 updates && passwd --lock updates || exit 1" | ARCH
echo -e "\n%updates ALL=(ALL) NOPASSWD: ALL" >> /mnt/etc/sudoers
echo "echo 'cd /tmp && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg --noconfirm -si || exit 1' | su updates || exit 1" | ARCH
echo "65" >/tmp/PRG

# Instalacion de utilidades adicionales
echo "echo 'yay --noconfirm -Sy neofetch zsh zsh-completions zsh-autosuggestions zsh-syntax-highlighting zsh-theme-powerlevel10k-bin-git ttf-meslo-nerd-font-powerlevel10k xdg-user-dirs libpwquality || exit 1' | su updates || exit 1" | ARCH
if [[ $GPU = vmware ]]
then echo "echo 'yay --noconfirm -Sy virtualbox-guest-utils || exit 1' | su updates || exit 1" | ARCH && echo "systemctl enable vboxservice.service" | ARCH
fi
echo "70" >/tmp/PRG

# Instalacion XFCE
echo $ESCRITORIO | grep "1" >/dev/nul && INSTALL=true || INSTALL=false
if [[ $INSTALL = true ]]
then	
	echo 'echo "cd /tmp; git clone https://github.com/Cambon18/xfce && cd xfce && bash archie.sh" | su updates' | ARCH
fi

# Instalacion Qtile
echo $ESCRITORIO | grep "2" >/dev/nul && INSTALL=true || INSTALL=false
if [[ $INSTALL = true ]]
then
	echo 'echo "cd /tmp; git clone https://github.com/Cambon18/qtile && cd qtile && bash archie.sh" | su updates' | ARCH
fi
echo "85" >/tmp/PRG

# Configuraciones CambonOS
cp -rv installer/cambonos-fs/* /mnt
echo "90" >/tmp/PRG

# Configuracion del firewall
echo -e "*filter\n:INPUT DROP [0:0]\n:FORWARD DROP [0:0]\n:OUTPUT ACCEPT [0:0]\n-A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT\n-A INPUT -s 127.0.0.1 -j ACCEPT\nCOMMIT" >/mnt/etc/iptables/iptables.rules
echo "systemctl enable iptables.service || exit 1" | ARCH
echo "91" >/tmp/PRG

# Instalacion ssh
if [[ $SSH = s ]] || [[ $SSH = si ]] || [[ $SSH = S ]] || [[ $SSH = Si ]]
then
	echo "pacman --noconfirm -Sy openssh && sed -i s/#X11Forwarding\ no/X11Forwarding\ yes/ /etc/ssh/sshd_config; systemctl enable sshd.service || exit 1" | ARCH
	echo -e "*filter\n:INPUT DROP [0:0]\n:FORWARD DROP [0:0]\n:OUTPUT ACCEPT [0:0]\n-A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT\n-A INPUT -s 127.0.0.1 -j ACCEPT\n-A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT\nCOMMIT" >/mnt/etc/iptables/iptables.rules
fi

# Configuracion hora
echo "ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime && hwclock --systohc" | ARCH
echo "92" >/tmp/PRG

# Creacion usuario
echo "useradd -m -c $ADMINNAME -s /bin/zsh -g users -G wheel,rfkill,sys $ADMINUSER && (echo -e '$ADMINPASS\n$ADMINPASS' | passwd $ADMINUSER)" | ARCH
echo "useradd -m -c $USERNAME -s /bin/zsh -g users -G rfkill,sys $USERUSER && (echo -e '$USERPASS\n$USERPASS' | passwd $USERUSER)" | ARCH
if [[ $GPU = vmware ]]
then 
	echo "usermod -aG vboxsf $ADMINUSER" | ARCH
	echo "usermod -aG vboxsf $USERUSER" | ARCH
fi
echo "94" >/tmp/PRG

# Configuracion cambonos-upgrade
echo "chown updates:wheel /usr/bin/cambonos-upgrade; chmod 750 /usr/bin/cambonos-upgrade" | ARCH
echo "chsh -s /usr/bin/nologin updates" | ARCH
if [[ $UPGRADE = s ]] || [[ $UPGRADE = si ]] || [[ $UPGRADE = S ]] || [[ $UPGRADE = Si ]]
then
	echo "systemctl enable cambonos-upgrade.service || exit 1" | ARCH
fi
echo "96" >/tmp/PRG

# Generacion locales
echo "locale-gen" | ARCH
echo "98" >/tmp/PRG

# Generacion configuracion grub
echo "grub-mkconfig -o /boot/grub/grub.cfg" | ARCH
echo "100" >/tmp/PRG
