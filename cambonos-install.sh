#!/bin/bash

##Definicion de variables
NOCOLOR='\033[0m'
RED='\033[1;31m'
GREEN='\033[1;32m'

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
	umount /mnt/boot >>$SALIDA 2>&1; umount /mnt/home >>$SALIDA 2>&1; umount /mnt >>$SALIDA 2>&1; rm -rf /mnt >>$SALIDA 2>&1; mkdir /mnt; exit
}

##Comprobacion de red
NETWORK () {
ping -c 3 google.com >/dev/null 2>&1 || \
(HEAD && \
echo '
Fallo en la conecxion a internet, selecciona opcion:

	1.Reintentar conexion
	2.Configurar wifi (2.4Ghz)
	3.Cancelar' && \
echo -e "\n(1,2,3): \c" && read OPTION
case $OPTION in
  1) sleep 5 && NETWORK ;;
  2) echo -e '\n>>Introduce el SSID: \c' && read SSID && \
  (iwctl station wlan0 connect-hidden $SSID 2>/dev/null|| iwctl station wlan0 connect $SSID 2>/dev/null)
  echo Connecting...
  sleep 5
  NETWORK ;;
  *) exit 1 ;;
esac)
}
NETWORK || exit

##Particionado
SALIDA='/tmp/particionado.log'
HEAD
ls /sys/firmware/efi/efivars >/dev/null 2>&1 && GRUB='uefi' || GRUB='bios'
case $GRUB in
	uefi)
		echo '
Bienvenido al instalador oficial de CambonOS!!!

Para continuar su intalacion escoga entre:

  1-Instalacion borrando todo el disco
  2-Instalar sistema en el espacio libre al final del disco
  3-Cancelar'
		echo -e "\n(1,2,3): \c" && read PART
		if [[ $PART != 1 ]] && [[ $PART != 2 ]]
		then exit
		fi
		echo -e "\n>>Listando discos\n" && lsblk -o NAME,SIZE,VENDOR,MODEL -d
		echo -e "\n>>En que disco desea instalar el sistema (sda,nvme0n1,...): \c" && read DISCO
		(echo $DISCO | grep nvme >>$SALIDA 2>&1) && DISCOP=$DISCO$(echo p) || DISCOP=$DISCO
		N=1 && LIBRE=0
		if [[ $PART = 2 ]]
		then
			fdisk -l /dev/$DISCO | grep gpt >>$SALIDA 2>&1 && TD=gpt || TD=mbr
			case $TD in
			mbr)
				echo -e "\n>>El disco NO esta en GPT\c"
				STOP
				;;
			gpt)
				while [[ $LIBRE = 0 ]]
				do 
					lsblk | grep $DISCOP$N >>$SALIDA 2>&1 && N=$(($N+1)) || LIBRE=1
				done
				echo -e "\n>>Particionando disco...\c"
				(echo -e "n\n\n\n+512M\nn\n\n\n+30G\nn\n\n\n\nw\n" | fdisk -w always /dev/$DISCO >>$SALIDA 2>&1) || STOP
				;;
			esac
		else 
			echo -e "\n>>Se eliminaran ${RED}todos los datos del disco${NOCOLOR}. Desea continuar? (s/N): \c"
			read ANS
			if [[ $ANS = s ]] || [[ $ANS = si ]] || [[ $ANS = Si ]] || [[ $ANS = S ]]
			then sleep 0
			else exit
			fi
			echo -e "\n>>Particionando disco...\c"
			(echo -e "g\nn\n\n\n+512M\nn\n\n\n+30G\nn\n\n\n\nw\n" | fdisk -w always /dev/$DISCO >>$SALIDA 2>&1) || STOP
		fi
		yes | mkfs.vfat -F 32 /dev/$DISCOP$N >>$SALIDA 2>&1 || STOP && N=$(($N+1))
		yes | mkfs.ext4 /dev/$DISCOP$N >>$SALIDA 2>&1 || STOP && N=$(($N+1))
		yes | mkfs.ext4 /dev/$DISCOP$N >>$SALIDA 2>&1 || STOP && N=$(($N-1))
		mount /dev/$DISCOP$N /mnt >>$SALIDA 2>&1 || STOP && N=$(($N-1))
		mkdir /mnt/boot >>$SALIDA 2>&1 || STOP
		mount /dev/$DISCOP$N /mnt/boot >>$SALIDA 2>&1 || STOP && N=$(($N+2))
		mkdir /mnt/home >>$SALIDA 2>&1 || STOP
		mount /dev/$DISCOP$N /mnt/home >>$SALIDA 2>&1 && DONE || STOP
		;;
	bios)
		echo -e "\nBienvenido al instalador oficial de CambonOS!!!\n\n>>Con el istalador arrancado en BIOS solo se puede instalar borrando todo el disco.\n\n>>Quiere continuar? (s/N): \c"
		read ANS
		if [[ $ANS = s ]] || [[ $ANS = si ]] || [[ $ANS = Si ]] || [[ $ANS = S ]]
		then
			echo -e "\n>>Listando discos\n" && lsblk -o NAME,SIZE,VENDOR,MODEL -d
			echo -e "\n>>En que disco desea instalar el sistema (sda,nvme0n1,...): \c" && read DISCO
			echo -e "\n>>Se eliminaran ${RED}todos los datos del disco${NOCOLOR}. Desea continuar? (s/N): \c"
			read ANS
			if [[ $ANS = s ]] || [[ $ANS = si ]] || [[ $ANS = Si ]] || [[ $ANS = S ]]
			then sleep 0
			else exit
			fi
		else 
			exit
		fi
		echo -e "\n>>Particionando disco...\c"
		(echo $DISCO | grep nvme >>$SALIDA 2>&1) && DISCOP=$DISCO$(echo p) || DISCOP=$DISCO
		(echo -e "o\nn\n\n\n\n+30G\nn\n\n\n\n\nw\n" | fdisk -w always /dev/$DISCO >>$SALIDA 2>&1) || STOP && N=1
		yes | mkfs.ext4 /dev/$DISCOP$N >>$SALIDA 2>&1 || STOP
		mount /dev/$DISCOP$N /mnt >>$SALIDA 2>&1 || STOP && N=$(($N+1))
		yes | mkfs.ext4 /dev/$DISCOP$N >>$SALIDA 2>&1 || STOP
		mkdir /mnt/home >>$SALIDA 2>&1 || STOP
		mount /dev/$DISCOP$N /mnt/home >>$SALIDA 2>&1 && DONE || STOP
		;;
esac

##Preguntas para la instalacion
HEAD
echo -e "\n>>Nombre del equipo: \c" && read NOMBRE
echo -e "\n>>Nombre para el nuevo usuario: \c" && read USERNAME
USER=$(echo $USERNAME | awk '{print tolower($0)}')
SUDO () {
echo -e "\n>>Contraseña del usuario: \c" && read -s PASS
echo -e "\n\n>>Repetir contraseña: \c" && read -s PASS1
if [[ $PASS = $PASS1 ]]
  then sleep 0
  else echo && SUDO
fi
}
SUDO
echo -e "\n\n>>Desea instalar los drivers graficos? (s/N): \c" && read DG
echo -e "\n>>Desea instalar servidor SSH? (s/N): \c" && read SSH
echo -e "\n>>Que entorno de encritorio desea instalar:\n\n       1-CambonOS/XFCE(Recomendado)\n\n       2-CambonOS/Qtile\n\n       3-ManuCr19/i3wm"
echo -e "\n>>Seleccione uno, varios separados por espacios o ninguno: \c" && read ESCRITORIO
echo -e "\n>>Desea unirse a un dominio LDAP? (s/N): \c" && read ANS
if [[ $ANS = s ]] || [[ $ANS = si ]] || [[ $ANS = Si ]] || [[ $ANS = S ]]
  then LDAP=true
  echo -e "\n>>Base DN (dc=example,dc=local): \c" && read BASEDN
  echo -e "\n>>Bind DN (cn=admin,dc=example,dc=local): \c" && read BINDDN
  echo -e "\n>>Uri (ldap://192.168.1.5): \c" && read URI
  echo -e "\n>>Bind PW (secret): \c" && read BINDPW
  else LDAP=false
fi

##Paquetes basicos y drivers
SALIDA='/tmp/system-base.log'
HEAD
echo -e "\n>>Instalando base del sistema\c"
(pacstrap /mnt linux-zen linux-zen-headers linux-firmware base >>$SALIDA 2>&1 && \
genfstab -U /mnt >> /mnt/etc/fstab && \
echo "usermod -s /bin/zsh root" | ARCH && \
cp -r archie/cambonos-fs/etc/skel/.config /mnt/root && \
cp archie/cambonos-fs/etc/skel/.* /mnt/root/ 2>/dev/null) && DONE || STOP

SALIDA='/tmp/packages-base'
echo -e "\n>>Instalando paquetes basicos\c"
(grep 'Intel' /proc/cpuinfo >/dev/null && CPU='intel-ucode') || (grep 'AMD' /proc/cpuinfo >/dev/null && CPU='amd-ucode') || CPU='amd-ucode intel-ucode'
echo "pacman --noconfirm -Sy lsb-release tree neovim xclip micro man man-db man-pages man-pages-es bash-completion networkmanager $CPU git base-devel sudo ntfs-3g || exit 1" | ARCH && DONE || STOP

SALIDA='/tmp/video-drivers.log'
if [[ $DG = s ]] || [[ $DG = S ]] || [[ $DG = si ]] || [[ $DG = Si ]]
then
	echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" >>/mnt/etc/pacman.conf && GRUB="DESCONOCIDA"
	GPUINSTALL () {
	case $GPU in
		amd)
			echo -e "\n>>Instalando drivers graficos de AMD\c"
			echo "pacman --noconfirm -Sy xf86-video-vesa xf86-video-amdgpu lib32-mesa mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader || exit 1" | ARCH && DONE || ERROR ;;
		nvidia)
			echo -e "\n>>Instalando drivers graficos de Nvidia\c"
			echo "pacman --noconfirm -Sy xf86-video-vesa nvidia lib32-nvidia-utils nvidia-utils nvidia-settings nvidia-dkms vulkan-icd-loader lib32-vulkan-icd-loader || exit 1" | ARCH && DONE || ERROR ;;
  		intel)
  			echo -e "\n>>Instalando drivers graficos Intel\c"
			echo "pacman --noconfirm -Sy xf86-video-vesa xf86-video-intel lib32-mesa mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader || exit 1" | ARCH && DONE || ERROR ;;
		vmware)
			echo -e "\n>>Instalando drivers graficos para maquinas virtuales\c"
			echo "pacman --noconfirm -Sy virtualbox-guest-utils xf86-video-vesa xf86-video-vmware lib32-mesa mesa || exit 1" | ARCH && DONE || ERROR ;;
		*)
			echo -e "\n>>Instalando drivers graficos\c"
			echo "pacman --noconfirm -Sy xf86-video-vesa xf86-video-amdgpu lib32-mesa mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader nvidia lib32-nvidia-utils nvidia-utils nvidia-settings nvidia-dkms xf86-video-vmware || exit 1" | ARCH && DONE || ERROR ;;
	esac
	}
	(lspci | grep VGA) | grep -o 'AMD' >/dev/null && GPU='amd' && GPUINSTALL
	(lspci | grep VGA) | grep -o 'Intel' >/dev/null && GPU='intel' && GPUINSTALL
	(lspci | grep VGA) | grep -o 'VMware' >/dev/null && GPU='vmware' && GPUINSTALL
	(lspci | grep VGA) | grep -o 'NVIDIA' >/dev/null && GPU='nvidia' && GPUINSTALL
fi

SALIDA='/tmp/grub.log'
echo -e "\n>>Instalando grub\c"
ls /sys/firmware/efi/efivars >/dev/null 2>&1 && GRUB='uefi' || GRUB='bios'
case $GRUB in
	uefi)
		echo "pacman --noconfirm -Sy grub efibootmgr os-prober && grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=COS || exit 1" | ARCH && DONE || STOP
		;;
	bios)
		echo "pacman --noconfirm -Sy grub os-prober && grub-install --target=i386-pc /dev/$DISCO || exit 1" | ARCH && DONE || STOP
		;;
esac

SALIDA='/tmp/network.log'
echo -e "\n>>Configurando red\c"
echo "$NOMBRE" >/mnt/etc/hostname && echo -e "127.0.0.1	localhost\n::1		localhost\n127.0.1.1	$NOMBRE" >/mnt/etc/hosts && echo 'systemctl enable NetworkManager.service || exit 1' | ARCH && DONE || ERROR

##Instalacion de trizen
SALIDA='/tmp/trizen.log'
echo -e "\n>>Instalando trizen\c"
echo "groupadd -g 513 sudo && useradd -m -s /bin/bash -g sudo $USER && (echo -e '$PASS\n$PASS1' | passwd $USER) || exit 1" | ARCH
echo -e "\n%sudo ALL=(ALL) NOPASSWD: ALL" >> /mnt/etc/sudoers
echo "echo 'cd /tmp && git clone https://aur.archlinux.org/trizen.git && cd trizen && makepkg --noconfirm -si || exit 1' | su $USER || exit 1" | ARCH && DONE || ERROR

##Instalacion XFCE
SALIDA='/tmp/xfce.log'
echo $ESCRITORIO | grep "1" >/dev/nul && INSTALL=true || INSTALL=false
if [[ $INSTALL = true ]]
then	
	echo -e "\n>>Instalando Xfce\c"
	echo 'echo "cd /tmp; git clone https://github.com/CambonOS/xfce && cd xfce && bash archie.sh" | su $USER' | ARCH && DONE || ERROR
fi

##Instalacion Qtile
SALIDA='/tmp/qtile.log'
echo $ESCRITORIO | grep "2" >/dev/nul && INSTALL=true || INSTALL=false
if [[ $INSTALL = true ]]
then
	echo -e "\n>>Instalando Qtile\c"
	echo 'echo "cd /tmp; git clone https://github.com/CambonOS/qtile && cd qtile && bash archie.sh" | su $USER' | ARCH && DONE || ERROR
fi

##Instalacion I3
SALIDA='/tmp/i3.log'
echo $ESCRITORIO | grep "3" >/dev/nul && INSTALL=true || INSTALL=false
if [[ $INSTALL = true ]]
then
	echo -e "\n>>Instalando I3wm\c"
	echo 'echo "cd /tmp; git clone -b beta https://github.com/ManuCr19/i3wm && cd i3wm && bash archie.sh" | su $USER' | ARCH && DONE || ERROR
fi

##Instalacion ssh
SALIDA='/tmp/ssh.log'
if [[ $SSH = s ]] || [[ $SSH = si ]] || [[ $SSH = S ]] || [[ $SSH = Si ]]
then
	echo -e "\n>>Instalando SSH server\c"
	echo "pacman --noconfirm -Sy openssh && sed -i s/#X11Forwarding\ no/X11Forwarding\ yes/ /etc/ssh/sshd_config; systemctl enable sshd.service || exit 1" | ARCH && DONE || ERROR
fi

##Instalacion de utilidades adicionales
SALIDA='/tmp/aditional-packages.log'
echo -e "\n>>Instalando utilidades adicionales\c"
echo "echo 'trizen --noconfirm -Sy neofetch zsh zsh-completions zsh-autosuggestions zsh-syntax-highlighting zsh-theme-powerlevel10k ttf-meslo-nerd-font-powerlevel10k xdg-user-dirs zramd || exit 1' | su $USER || exit 1" | ARCH
echo "systemctl enable zramd.service || exit 1" | ARCH && DONE || ERROR
if [[ $GPU = vmware ]]
then echo "echo 'trizen --noconfirm -Sy virtualbox-guest-utils || exit 1' | su $USER || exit 1" | ARCH && echo "systemctl enable vboxservice.service" | ARCH
fi

##Configuracion CambonOS
SALIDA='/tmp/system-configuration.log'
echo -e "\n>>Configurando el sistema\c"
cp -r archie/cambonos-fs/* /mnt && \
chmod 775 /mnt/usr/bin/cambonos* && \
mkdir /mnt/media && \
echo "ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime && hwclock --systohc" | ARCH
echo "userdel -r $USER && useradd -m -c $USERNAME -s /bin/zsh -g sudo -G rfkill,wheel,video,audio,storage $USER && (echo -e '$PASS\n$PASS1' | passwd $USER)" | ARCH
if [[ $GPU = vmware ]]
then echo "usermod -aG vboxsf $USER" | ARCH
fi
echo "locale-gen" | ARCH && \
echo "cambonos-upgrade" | ARCH && DONE || ERROR

##Dominio LDAP
SALIDA='/tmp/ldap.log'
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
fi
