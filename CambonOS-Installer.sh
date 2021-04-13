#!/bin/bash
#
SALIDA="/tmp/salida"
clear
echo "*******************************************************************************************************"
echo "********************************* CAMBON OS INSTALLER *************************************************"
echo "*******************************************************************************************************"

echo -e "\n>>Iniciando instalacion"
loadkeys es && ping -c 4 archlinux.org >$SALIDA 2>&1 || echo "NON HAY CONECXION A INTERNET"

echo -e "\n>>Tipo de arranque?(uefi/bios) \c" && read GRUB
echo -e "\n\n>>Listando discos\n" && lsblk
echo -e "\n>>En que disco quieres instalar el sistema? \c" && read -e -i "/dev/sd" DISCO
echo -e "\n\n>>Formato del disco?(mbr/gpt) \c" && read TDISCO
echo -e "\n\n>>Nombre del equipo? \c" && read NOMBRE
echo -e "\n\n>>Dominio? \c" && read -e -i "$NOMBRE.cambon.local" DOMINIO
echo -e "\n\n>>Procesador?(intel/amd) \c" && read CPU
echo -e "\n\n>>Graficos?(nvidia/amd/vmware) \c" && read GPU
echo -e "\n\n>>Entorno grafico?(terminal/gnome) \c" && read GDM
echo -e "\n\n>>Contraseña del root? \c" && read -s PASS

1="1" ; 2="2" ; 3="3" ; 4="4"
BOOT="$DISCO$1"
SWAP="$DISCO$2"
RAIZ="$DISCO$3"
HOME="$DISCO$4"
OUEFI="o\nn\np\n1\n\n+512M\nn\np\n2\n\n+4G\nn\np\n3\n\n+40G\nn\np\n4\n\n\nt\n1\nEF\nt\n2\n82\nt\n3\n83\nt\n4\n83\nw\n"
OBIOS="o\nn\np\n1\n\n+512M\nn\np\n2\n\n+4G\nn\np\n3\n\n+40G\nn\np\n4\n\n\nt\n1\n83\nt\n2\n82\nt\n3\n83\nt\n4\n83\nw\n"
GUEFI="g\nn\n1\n\n+512M\nn\n2\n\n+4G\nn\n3\n\n+40G\nn\n4\n\n\nt\n1\n1\nt\n2\n19\nt\n3\n23\nt\n4\n28\nw\n"
GBIOS="g\nn\n1\n\n+512M\nn\n2\n\n+4G\nn\n3\n\n+40G\nn\n4\n\n\nt\n1\n4\nt\n2\n19\nt\n3\n23\nt\n4\n28\nw\n"

clear

echo -e "\n>>Actualizando reloj"
timedatectl set-ntp true >>$SALIDA 2>&1 

echo -e "\n>>Particionando disco"
case $TDISCO in
	gpt) 
		case $GRUB in
			uefi) 
				echo -e $GUEFI | fdisk -w always $DISCO >>$SALIDA 2>&1
			;; 
			bios) 
				echo -e $GBIOS | fdisk -w always $DISCO >>$SALIDA 2>&1
			;;
		esac
	;;
	mbr) 
		case $GRUB in
			uefi) 
				echo -e $OUEFI | fdisk -w always $DISCO >>$SALIDA 2>&1
			;;
			bios)
				echo -e $OBIOS | fdisk -w always $DISCO >>$SALIDA 2>&1
			;;
		esac
	;;
esac

echo -e "\n>>Formateando y montando sistemas de archivos"
case $GRUB in
	bios) 
		mkfs.ext4 $BOOT >>$SALIDA 2>&1
	;;
	uefi) 
		mkfs.fat -F32 $BOOT >>$SALIDA 2>&1
	;;
esac

mkswap $SWAP >>$SALIDA 2>&1 
mkfs.ext4 $RAIZ >>$SALIDA 2>&1 
mkfs.ext4 $HOME >>$SALIDA 2>&1 
swapon $SWAP >>$SALIDA 2>&1 
mount $RAIZ /mnt >>$SALIDA 2>&1 
mkdir /mnt/home >>$SALIDA 2>&1 
mount $HOME /mnt/home >>$SALIDA 2>&1 
mkdir /mnt/boot >>$SALIDA 2>&1 
mount $BOOT /mnt/boot >>$SALIDA 2>&1 

echo -e "\n>>Configurando pacman.conf"
echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n\nColor\nCheckSpace\nTotalDownload\nILoveCandy\n" >>/etc/pacman.conf

echo -e "\n>>Seleccionando replicas"
reflector --contry Spain --sort rate --save /etc/pacman.d/mirrorlist >>$SALIDA 2>&1 

echo -e "\n>>Instalando base del sistema"
pacstrap /mnt linux-zen linux-zen-headers linux-firmware base nano man man-db man-pages man-pages-es bash-completion neovim neofetch networkmanager grub $CPU-ucode git base-devel >>$SALIDA 2>&1 
case $GRUB in
	uefi)
		pacstrap /mnt efibootmgr >>$SALIDA 2>&1
	;;
	bios)
	;;
esac

echo -e "\n>>Instalando drivers graficos"
case $GPU in
	amd) 
		pacstrap /mnt xf86-video-vesa xf86-video-amdgpu lib32-mesa mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader >>$SALIDA 2>&1
	;;
	nvidia) 
		pacstrap /mnt xf86-video-vesa nvidia lib32-nvidia-utils nvidia-utils nvidia-settings nvidea-dkms vulkan-icd-loader lib32-vulkan-icd-loader >>$SALIDA 2>&1
	;;
	intel) 
		pacstrap /mnt xf86-video-vesa xf86-video-intel lib32-mesa mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader >>$SALIDA 2>&1
	;;
	vmware) 
		pacstrap /mnt xf86-video-vesa xf86-video-vmware lib32-mesa mesa >>$SALIDA 2>&1
	;;
esac

echo -e "\n>>Instalando entorno grafico seleccionado"
case $GDM in
	terminal) 
	;;
	gnome) 
		pacstrap /mnt gdm nautilus alacritty gedit gnome-calculator gnome-control-center gnome-tweak-tool >>$SALIDA 2>&1
	;;
esac

echo -e "\n>>Generando archivo fstab"
genfstab -U /mnt >> /mnt/etc/fstab

echo "
	echo -e '\n>>Estableciendo zona horaria'
	ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime
	hwclock --systohc
	
	echo -e '\n>>Cambiando idioma del sistema'
	echo 'es_ES.UTF-8 UTF-8\nen_US.UTF-8 UTF-8' >> /etc/locale.gen
	locale-gen  >>$SALIDA 2>&1
	echo -e 'LANG=es_ES.UTF-8\nLANGUAGE=es_ES.UTF-8\nLC_ALL=en_US.UTF-8' >/etc/locale.conf
	echo -e 'KEYMAP=es' >/etc/vconsole.conf
	
	echo -e '\n>>Creando archivos host'
	echo -e '$NOMBRE' >/etc/hostname
	echo -e '127.0.0.1	localhost\n::1		localhost\n127.0.1.1	$DOMINIO $NOMBRE' >/etc/hosts
	
	echo -e '\n>>Configurando red'
	systemctl enable NetworkManager.service >>$SALIDA 2>&1
	
	echo -e '\n>>Configurando grub'
	case $GRUB in
		bios) 
			grub-install --target=i386-pc $DISCO >>$SALIDA 2>&1 
		;;
		uefi) 
			grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB >>$SALIDA 2>&1
		;;
	esac
	grub-mkconfig -o /boot/grub/grub.cfg >>$SALIDA 2>&1 	
	echo -e '\n>>Activando entorno grafico'
	case $GDM in
		terminal) 
		;;
		gnome) 
			systemctl enable gdm.service >>$SALIDA 2>&1
		;;
	esac

	echo -e '\n>>Configurando root'
	echo -e '$PASS\n$PASS' | passwd
	
	echo -e '\n>>Editando skel'
	echo -e '\nneofetch' >/etc/skel/.bashrc

	echo -e '\n>>Creando grupo sudo'
	groupadd -g 513 sudo
	cp /etc/sudoers /etc/sudoers.bk
	echo '%sudo ALL=(ALL) ALL' >>/etc/sudoers.bk
	echo '%sudo ALL=(ALL) NOPASSWD: ALL' >>/etc/sudoers
	useradd -m -s /bin/bash -g sudo sysop
	
	echo -e '\n>>Instalando trizen'
	echo '
		cd /tmp
		git clone https://aur.archlinux.org/trizen.git >>$SALIDA 2>&1 
		cd trizen
		makepkg -si >>$SALIDA 2>&1 
		exit
	' | su - sysop
	
	usedel -r sysop >>$SALIDA 2>&1 
	mv /etc/sudoers.bk /etc/sudoers

	exit
" | arch-chroot /mnt

echo -e "\n>>Ejecutando el script cmd de https://github.com/cambonos/cmd.sh"
cd /tmp
git clone https://github.com/CambonOS/Scripts.git
bash Scripts/cmd.sh

echo -e "\n*******************************************************************************************************"
echo "************************************** INSTALLED ******************************************************"
echo "*******************************************************************************************************"
