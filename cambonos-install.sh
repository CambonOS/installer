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
ESCRITORIO=$4
SSH=$5
DISCO=$6

# Habilitar NTP
timedatectl set-ntp true
echo "1" >/tmp/PRG

# Generar lista de mirrors
reflector -l 10 -f 5 --save /etc/pacman.d/mirrorlist
echo "3" >/tmp/PRG

# Actualizacion de las claves de Arch Linux
pacman --noconfirm -Sy archlinux-keyring
echo "4" >/tmp/PRG

# Creacion de la raiz del sistema
pacstrap /mnt linux linux-headers linux-firmware base || STOP
echo "7" >/tmp/PRG

# Generar fichero fstab del sistema
dd if=/dev/zero of=/mnt/swapfile bs=1M count=4k status=progress
chmod 0600 /mnt/swapfile
mkswap -U clear /mnt/swapfile
swapon /mnt/swapfile
genfstab -U /mnt >> /mnt/etc/fstab || STOP
echo "8" >/tmp/PRG

# Modificar configuraciones de root
echo "usermod -s /bin/zsh root" | ARCH # Cambio shell
cp -rv installer/cambonos-fs/etc/skel/.config /mnt/root # Carpeta .config del skel
cp -v installer/cambonos-fs/etc/skel/.* /mnt/root/ # Ficheros del skel
echo "passwd --lock root" | ARCH
echo "9" >/tmp/PRG

# Instalacion paquetes basicos
(grep 'Intel' /proc/cpuinfo >/dev/null && CPU='intel-ucode') || (grep 'AMD' /proc/cpuinfo >/dev/null && CPU='amd-ucode') || CPU='amd-ucode intel-ucode'
packages="lsb-release tree htop xclip micro vim man man-db man-pages man-pages-es bash-completion networkmanager ntp systemd-resolvconf $CPU git wget base-devel sudo ntfs-3g dosfstools exfat-utils cpupower rsync plymouth accountsservice"
read -r -a pkg_array <<< "$packages"
n=${#pkg_array[@]}
i=0
for pkg in "${pkg_array[@]}"; do
    i=$((i + 1))
    echo "pacman --noconfirm -Sy $pkg" | ARCH || STOP
    progress=$((9 + ($i * 9 / $n)))
    echo "$progress" > /tmp/PRG
done
echo 'systemctl enable cpupower.service ; systemctl enable accounts-daemon.service || exit 1' | ARCH

# Habilitar repositorios multilib
echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" >>/mnt/etc/pacman.conf
echo "19" >/tmp/PRG

# Instalacion drivers graficos
# Detectar GPU
GPU=$(lspci | grep -E "VGA|3D" | grep -oE "NVIDIA|AMD|Intel" | head -n1 | tr '[:upper:]' '[:lower:]')
# Detectar GPU híbrida (Intel + Nvidia → Optimus)
if lspci | grep -E "VGA|3D" | grep -q "NVIDIA" && lspci | grep -q "Intel"; then
	GPU="nvidia-hybrid"
fi
case $GPU in
	amd)
		packages="mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader"
		;;
	nvidia|nvidia-hybrid)
		packages="nvidia nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader"
		;;
	intel)
		packages="mesa lib32-mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader"
		;;
	*)
		packages="mesa lib32-mesa vulkan-icd-loader lib32-vulkan-icd-loader"
		;;
esac
read -r -a pkg_array <<< "$packages"
n=${#pkg_array[@]}
i=0
for pkg in "${pkg_array[@]}"; do
    i=$((i + 1))
    echo "pacman --noconfirm -Sy $pkg" | ARCH
    progress=$((19 + ($i * 5 / $n)))
    echo "$progress" > /tmp/PRG
done

# Instalacion GRUB
ls /sys/firmware/efi/efivars >/dev/null 2>&1 && GRUB='uefi' || GRUB='bios'
case $GRUB in
	uefi)
		echo "pacman --noconfirm -Sy grub efibootmgr os-prober grub-theme-vimix && grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=CambonOS || exit 1" | ARCH || STOP
		;;
	bios)
		echo "pacman --noconfirm -Sy grub os-prober grub-theme-vimix && grub-install --target=i386-pc /dev/$DISCO || exit 1" | ARCH || STOP
		;;
esac
echo "27" >/tmp/PRG

# Configuraciones de Red
cp /etc/NetworkManager/system-connections/* /mnt/etc/NetworkManager/system-connections
sed -i /interface/d /mnt/etc/NetworkManager/system-connections/*
echo "$NOMBRE" >/mnt/etc/hostname
echo -e "127.0.0.1	localhost\n::1		localhost\n127.0.1.1	$NOMBRE" >/mnt/etc/hosts
sed -i 's/^#MulticastDNS=yes/MulticastDNS=no/' /mnt/etc/systemd/resolved.conf
sed -i 's/^use-ipv6=yes/use-ipv6=no/' /mnt/etc/avahi/avahi-daemon.conf
echo 'systemctl enable NetworkManager.service ; systemctl enable ntpd.service ; systemctl enable systemd-resolved.service ; systemctl enable avahi-daemon.service ; systemctl enable systemd-homed.service || exit 1' | ARCH
echo "31" >/tmp/PRG

# Instalacion de yay
echo "groupadd -g 777 updates" | ARCH
echo "useradd -m -d /home/.updates -g updates -u 777 updates && passwd --lock updates || exit 1" | ARCH
echo -e "\n%updates ALL=(ALL) NOPASSWD: ALL" >> /mnt/etc/sudoers
echo "echo 'cd /tmp && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg --noconfirm -si || exit 1' | su updates || exit 1" | ARCH
echo "33" >/tmp/PRG

# Instalacion de utilidades adicionales
if [[ $GPU = nvidia-hybrid ]]
then 
	packages="neofetch zsh zsh-completions zsh-autosuggestions zsh-syntax-highlighting zsh-theme-powerlevel10k-bin-git ttf-meslo-nerd-font-powerlevel10k xdg-user-dirs libpwquality optimus-manager optimus-manager-qt"
else
	packages="neofetch zsh zsh-completions zsh-autosuggestions zsh-syntax-highlighting zsh-theme-powerlevel10k-bin-git ttf-meslo-nerd-font-powerlevel10k xdg-user-dirs libpwquality"
fi
read -r -a pkg_array <<< "$packages"
n=${#pkg_array[@]}
i=0
for pkg in "${pkg_array[@]}"; do
    i=$((i + 1))
    echo -e "echo \"yay --noconfirm -Sy $pkg\" | su updates" | ARCH
    progress=$((33 + ($i * 8 / $n)))
    echo "$progress" > /tmp/PRG
done

# Instalacion XFCE
(sleep 2; while [[ $(cat /mnt/tmp/PRG) -ne 88 ]]; do cp /mnt/tmp/PRG /tmp/PRG; sleep 1; done) &
case "$ESCRITORIO" in
    1)
        # Instalación XFCE
		cp -r /root/xfce /mnt/xfce
        echo 'chown -R updates:updates /xfce; echo "cd /xfce && bash archie.sh" | su updates' | ARCH
		rm -rf /mnt/xfce
        ;;
    2)
        # Instalación Qtile
		cp -r /root/qtile /mnt/qtile
        echo 'chown -R updates:updates /qtile; echo "cd /qtile && bash archie.sh" | su updates' | ARCH
		rm -rf /mnt/qtile
        ;;
esac

# Configuraciones CambonOS
cp -rv installer/cambonos-fs/* /mnt
sed -i 's/base udev/base udev plymouth sleep/' /mnt/etc/mkinitcpio.conf
echo 'plymouth-set-default-theme -R cambonos || exit 1' | ARCH
cp /mnt/etc/cambonos-release/* /mnt/etc/
echo "89" >/tmp/PRG

# Configuracion del firewall
echo -e "*filter\n:INPUT DROP [0:0]\n:FORWARD DROP [0:0]\n:OUTPUT ACCEPT [0:0]\n-A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT\n-A INPUT -s 127.0.0.1 -j ACCEPT\n-A INPUT -p udp --dport 5353 -j ACCEPT\nCOMMIT" >/mnt/etc/iptables/iptables.rules
echo "systemctl enable iptables.service || exit 1" | ARCH
echo "90" >/tmp/PRG

# Instalacion ssh
if [[ $SSH = s ]] || [[ $SSH = si ]] || [[ $SSH = S ]] || [[ $SSH = Si ]]
then
	echo "pacman --noconfirm -Sy openssh && sed -i s/#X11Forwarding\ no/X11Forwarding\ yes/ /etc/ssh/sshd_config; systemctl enable sshd.service || exit 1" | ARCH
	echo -e "*filter\n:INPUT DROP [0:0]\n:FORWARD DROP [0:0]\n:OUTPUT ACCEPT [0:0]\n-A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT\n-A INPUT -s 127.0.0.1 -j ACCEPT\n-A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT\n-A INPUT -p udp --dport 5353 -j ACCEPT\nCOMMIT" >/mnt/etc/iptables/iptables.rules
fi
echo "91" >/tmp/PRG

# Configuracion hora
echo "ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime && hwclock --systohc" | ARCH
echo "92" >/tmp/PRG

# Creacion usuario
echo "useradd -m -c $ADMINNAME -s /bin/zsh -g users -G wheel,rfkill,sys,lp $ADMINUSER && (echo -e '$ADMINPASS\n$ADMINPASS' | passwd $ADMINUSER)" | ARCH
echo "93" >/tmp/PRG

# Configuracion cambonos-upgrade
echo "chown updates:wheel /usr/bin/cambonos-upgrade; chmod 750 /usr/bin/cambonos-upgrade" | ARCH
echo "chsh -s /usr/bin/nologin updates" | ARCH
echo "systemctl enable cambonos-upgrade.timer || exit 1" | ARCH
echo "94" >/tmp/PRG

# Generacion locales
echo "locale-gen" | ARCH
echo "98" >/tmp/PRG

# Generacion configuracion grub
echo "grub-mkconfig -o /boot/grub/grub.cfg" | ARCH
echo "100" >/tmp/PRG
