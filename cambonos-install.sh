#!/bin/bash

##Definicion de variables
NOCOLOR='\033[0m'
RED='\033[1;31m'
GREEN='\033[1;32m'
SALIDA='/tmp/salida'

##Definicion de grupos
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

##Comprobacion de red
NETWORK () {
HEAD
ping -c 3 google.com >/dev/null 2>&1 || \
(clear && cat /etc/motd && \
echo 'Fallo en la conecxion a internet, selecciona opcion:
1.Reintentar conecxion cableada
2.Configurar wifi
3.Cancelar' && \
echo -e "\n(1,2,3): \c" && read OPTION
case $OPTION in
  1) sleep 1 && NETWORK ;;
  2) echo -e '\n>>Introduce el SSID: \c' && read SSID && \
  (iwctl station wlan0 connect-hidden $SSID 2>/dev/null|| iwctl station wlan0 connect $SSID 2>/dev/null)
  echo Connecting...
  sleep 2
  NETWORK ;;
  3) exit ;;
esac)
}
NETWORK

##Preguntas para la instalacion
HEAD
echo -e "\n>>Nombre del equipo: \c" && read NOMBRE
echo -e "\n>>Nombre para el nuevo usuario: \c" && read USER
echo -e "\n>>Contraseña del usuario: \c" && read -s PASS
echo -e "\n\n>>Repetir contraseña: \c" && read -s PASS1
if [[ $PASS = $PASS1 ]]
  then sleep 0
  else echo && SUDO
fi
echo -e "\n>>Listando discos\n" && lsblk -o NAME,SIZE,VENDOR,MODEL -d
echo -e "\n>>En que disco quieres instalar el sistema(sda,nvme0n1): \c" && read DISCO
echo -e "\n>>Instalar en el espacio libre al final del disco(1) o borrar todo el disco e instalar(2):\c"
read PART
echo -e "\n\n>>Desea unirse a un dominio LDAP? [s/N]: \c"
read ANS
if [[ $ANS = s ]] || [[ $ANS = si ]] || [[ $ANS = Si ]] || [[ $ANS = S ]]
  then LDAP=true
  echo -e "\n>>Base DN (dc=example,dc=local): \c" && read BASEDN
  echo -e "\n>>Bind DN (cn=admin,dc=example,dc=local): \c" && read BINDDN
  echo -e "\n>>Uri (ldap://192.168.1.5): \c" && read URI
  echo -e "\n>>Bind PW (secret): \c" && read BINDPW
  else LDAP=false
fi

##Particionado
HEAD
echo -e "\n>>Particionando disco\c"
ls /sys/firmware/efi/efivars >/dev/null 2>&1 && GRUB='uefi' || GRUB='bios'
(echo $DISCO | grep nvme) && DISCOP=$(echo /dev/)$DISCO$(echo p) || DISCOP=$(echo /dev/)$DISCO
N=1 && LIBRE=0
while [ $LIBRE -eq 0 ]
do 
  lsblk | grep $DISCO$N && N=$(($N+1)) || LIBRE=1
done
if [ $PART -eq 1 ]
then PART='n'
else PART='g\nn'
case $GRUB in
	uefi) 
		(echo -e "$PART\n\n\n+512M\nn\n\n\n+50G\nn\n\n\n\nw\n" | fdisk -w always $DISCO >>$SALIDA 2>&1) || STOP 
		yes | mkfs.vfat -F32 $DISCOP$N >>$SALIDA 2>&1 || STOP && N=$(($N+1))
		yes | mkfs.ext4 $DISCOP$N >>$SALIDA 2>&1 || STOP && N=$(($N+1))
    yes | mkfs.ext4 $DISCOP$N >>$SALIDA 2>&1 || STOP && N=$(($N-1))
		mount $DISCOP$N /mnt >>$SALIDA 2>&1 || STOP && N=$(($N-1))
		mkdir /mnt/boot >>$SALIDA 2>&1 || STOP
		mount $DISCOP$N /mnt/boot >>$SALIDA 2>&1 || STOP && N=$(($N+2))
    mkdir /mnt/home >>$SALIDA 2>&1 || STOP
    mount $DISCOP$N /mnt/home >>$SALIDA 2>&1 || STOP
		DONE ;;
	bios) 
		(echo -e "$PART\n\n\n+50G\nn\n\n\n\nw\n" | fdisk -w always $DISCO >>$SALIDA 2>&1) || STOP
		yes | mkfs.ext4 $DISCOP$N >>$SALIDA 2>&1 || STOP
		mount $DISCOP$N /mnt >>$SALIDA 2>&1 || STOP && N=$(($N+1))
    yes | mkfs.ext4 $DISCOP$N >>$SALIDA 2>&1 || STOP
    mkdir /mnt/home >>$SALIDA 2>&1 || STOP
    mount $DISCOP$N /mnt/home >>$SALIDA 2>&1 || STOP
		DONE ;;
esac

##Paquetes basicos y drivers
echo -e "\n>>Instalando base del sistema\c"
(pacstrap /mnt linux-zen linux-zen-headers linux-firmware base >>$SALIDA 2>&1 && genfstab -U /mnt >> /mnt/etc/fstab) && DONE || STOP

echo -e "\n>>Instalando paquetes basicos\c"
(grep 'Intel' /proc/cpuinfo >/dev/null && CPU='intel-ucode') || (grep 'AMD' /proc/cpuinfo >/dev/null && CPU='amd-ucode') || CPU='amd-ucode intel-ucode'
echo "pacman --noconfirm -Sy xorg tree neovim man man-db man-pages man-pages-es bash-completion neofetch networkmanager $CPU git base-devel sudo ntfs-3g || exit 1" | ARCH && DONE || STOP

echo -e "\n>>Instalando drivers graficos\c"
echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" >>/mnt/etc/pacman.conf && GRUB="DESCONOCIDA"
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
ls /sys/firmware/efi/efivars >/dev/null 2>&1 && GRUB='uefi' || GRUB='bios'
case $GRUB in
	bios)
		echo "pacman --noconfirm -Sy grub os-prober && grub-install --target=i386-pc $DISCO || exit 1" | ARCH && DONE || STOP ;;
	uefi)
		echo "pacman --noconfirm -Sy grub efibootmgr os-prober && grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=COS || exit 1" | ARCH && DONE || STOP ;;
esac

echo -e "\n>>Configurando red\c"
echo "$NOMBRE" >/mnt/etc/hostname && echo -e "127.0.0.1	localhost\n::1		localhost\n127.0.1.1	$NOMBRE" >/mnt/etc/hosts && echo 'systemctl enable NetworkManager.service || exit 1' | ARCH && DONE || ERROR

##Instalacion de trizen
echo -e "\n>>Instalando trizen\c"
echo "groupadd -g 513 sudo && useradd -m -s /bin/bash -g sudo $USER && (echo -e '$PASS\n$PASS1' | passwd $USER) || exit 1" | ARCH
echo -e "\n%sudo ALL=(ALL) NOPASSWD: ALL" >> /mnt/etc/sudoers
echo "echo 'cd /tmp && git clone https://aur.archlinux.org/trizen.git && cd trizen && makepkg --noconfirm -si || exit 1' | su $USER || exit 1" | ARCH && DONE || ERROR

##Instalacion LightDM
echo -e "\n>>Instalando LightDM\c"
echo "echo 'trizen --noconfirm -Sy papirus-icon-theme papirus-folders light-locker lightdm lightdm-settings lightdm-slick-greeter numlockx || exit 1' | su $USER || exit 1" | ARCH
cp -r share/* /mnt/usr/share
echo "papirus-folders -t Papirus-Dark -C green" | ARCH
echo "echo 'trizen --noconfirm -Rns papirus-folders || exit 1' | su $USER || exit 1" | ARCH

##Instalando mezclador de audio
echo "echo 'trizen --noconfirm -Sy pulseaudio pulseaudio-jack pulseaudio-bluetooth pavucontrol || exit 1' | su $USER || exit 1" | ARCH


##Instalacion XFCE
echo -e "\n>>Instalando XFCE\c"
echo "echo 'trizen --noconfirm -Sy xfce4-whiskermenu-plugin xfce4-session xfce4-panel xfce4-power-manager xfce4-settings  xfce4-screenshooter xfconf xfdesktop xfwm4 network-manager-applet xfce4-pulseaudio-plugin menulibre mugshot || exit 1' | su $USER || exit 1" | ARCH

##Instalacion Qtile
echo -e "\n>>Instalando Qtile\c"
echo "echo 'trizen --noconfirm -Sy qtile rofi feh ttf-dejavu ttf-liberation noto-fonts brightnessctl volumeicon cbatticon xorg-xinit kvantum || exit 1' | su $USER || exit 1" | ARCH

##Instalacion Apps
echo -e "\n>>Instalando aplicaciones\c"
echo "echo 'trizen --noconfirm -Sy thunar xdg-user-dirs gvfs gvfs-smb thunar-volman thunar-archive-plugin file-roller gnome-disk-utility mousepad vlc atril ristretto galculator alacritty steam virtualbox virtualbox-guest-iso virtualbox-ext-oracle gnome-mines gnome-mahjongg gnome-sudoku mgba-qt libreoffice-fresh brave-bin || exit 1' | su $USER || exit 1" | ARCH

##Configuracion CambonOS
echo "echo 'trizen --noconfirm -Sy cups system-config-printer blueberry zramd || exit 1' | su $USER || exit 1" | ARCH && \
echo "systemctl enable zramd.service && systemctl enable lightdm.service && systemctl enable cups.service && systemctl enable bluetooth.service || exit 1" | ARCH
cp -r linux/cambonos-fs/* /mnt && \
chmod 775 /mnt/usr/bin/cambonos* && \
mkdir /mnt/media && \
echo "ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime && hwclock --systohc" | ARCH && \
echo "userdel -r $USER && useradd -m -s /bin/bash -g sudo -G rfkill,wheel,video,audio,storage $USER && (echo -e '$PASS\n$PASS1' | passwd $USER)" | ARCH && \
echo "locale-gen" | ARCH && \
echo "cambonos-upgrade" | ARCH && DONE || ERROR

##Dominio LDAP
if [[ $LDAP = true ]]
then 
	echo -e "\n>>Uniendose al dominio LDAP\c"
	echo "pacman --noconfirm -Sy openldap nss-pam-ldapd || exit 1" | ARCH && \
	sed -i "/#BASE/c BASE $BASEDN" /mnt/etc/openldap/ldap.conf && \
	sed -i "/#URI/c URI $URI" /mnt/etc/openldap/ldap.conf && \
	sed -i '/passwd\|group\|shadow/s/$/\ ldap/' /mnt/etc/nsswitch.conf && \
	sed -i "/^uri/c uri $URI" /mnt/etc/nslcd.conf && \
	sed -i "/^base/c base $BASEDN" /mnt/etc/nslcd.conf && \
	sed -i "/^#binddn/c binddn $BINDDN" /mnt/etc/nslcd.conf && \
	sed -i "/^#bindpw/c bindpw $BINDPW" /mnt/etc/nslcd.conf && \
	echo 'chown nslcd /etc/nslcd.conf || exit 1' | ARCH && \
	chmod 0600 /mnt/etc/nslcd.conf && \
	echo 'systemctl enable nslcd.service || exit 1' | ARCH && \
	sed -i '/auth.*pam_unix/i auth   sufficient   pam_ldap.so' /mnt/etc/pam.d/system-auth && \
	sed -i '/account.*pam_unix/i account   sufficient   pam_ldap.so' /mnt/etc/pam.d/system-auth && \
	sed -i '/password.*pam_unix/i password   sufficient   pam_ldap.so' /mnt/etc/pam.d/system-auth && \
	sed -i '/session.*pam_unix/a session   optional   pam_ldap.so' /mnt/etc/pam.d/system-auth && \
	sed -i '/auth.*pam_rootok/a auth   sufficient   pam_ldap.so' /mnt/etc/pam.d/su && \
	sed -i '/auth.*pam_rootok/a auth   sufficient   pam_ldap.so' /mnt/etc/pam.d/su-l && \
	sed -i '/pam_cracklib/i password   sufficient   pam_ldap.so' /mnt/etc/pam.d/passwd && \
	sed -i '/session/i session   required   pam_mkhomedir.so   skel=/etc/skel   umask=0077' /mnt/etc/pam.d/su && \
	sed -i '/session/i session   required   pam_mkhomedir.so   skel=/etc/skel   umask=0077' /mnt/etc/pam.d/su-l && \
	sed -i '/pam_env/a session   required   pam_mkhomedir.so   skel=/etc/skel   umask=0077' /mnt/etc/pam.d/system-login && \
	DONE || ERROR
else 
	sleep 0
fi
