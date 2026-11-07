#!/bin/bash

##Definicion de grupos
STOP () {
	umount -R /mnt; rm -rf /mnt >>$SALIDA 2>&1; mkdir /mnt; exit
}

##Particionado
#!/bin/bash

SALIDA='/tmp/particionado.log'

clear
cat /etc/motd

echo "=== CambonOS Installer ==="
echo ""

echo ""
echo "1 - Instalación limpia (BORRA TODO EL DISCO)"
echo "2 - Instalación en espacio libre (DUAL BOOT)"
echo ""
read -p "Modo: " MODE

echo ""
lsblk -o NAME,SIZE,MODEL -d
echo ""
read -p "Disco destino (ej: sda, nvme0n1): " DISCO

echo ""
echo "Disco seleccionado: /dev/$DISCO"
echo ""

read -p "Confirmar (s/N): " CONF
[[ "$CONF" != "s" && "$CONF" != "S" && "$CONF" != "si" ]] && exit 0

# Detectar formato NVMe
echo "$DISCO" | grep nvme >/dev/null 2>&1 && DISCOP="${DISCO}p" || DISCOP="$DISCO"

# =========================
# PARTICIONADO
# =========================

if [[ "$MODE" == "1" ]]; then

    echo ">> BORRADO TOTAL DEL DISCO"

    fdisk /dev/$DISCO >>$SALIDA 2>&1 <<EOF
g
n


+1G
n



w
EOF

else
	ls /sys/firmware/efi/efivars >/dev/null 2>&1 || {
    	echo "Sistema no UEFI detectado. Abortando (solo UEFI soportado)."
    	exit 1
	}
    echo ">> INSTALACION EN ESPACIO LIBRE"

    fdisk /dev/$DISCO >>$SALIDA 2>&1 <<EOF
n


+1G
n



w
EOF

fi

# =========================
# DETECTAR PARTICIONES
# =========================

sleep 2

PARTS=($(lsblk -ln -o NAME /dev/$DISCO | grep -E "${DISCO}p|${DISCO}[0-9]"))

EFI="/dev/${PARTS[-2]}"
ROOT="/dev/${PARTS[-1]}"

echo "EFI:  $EFI"
echo "ROOT: $ROOT"

# =========================
# FORMATEO
# =========================

echo ">> Formateando..."

yes | mkfs.vfat -F32 $EFI >>$SALIDA 2>&1
yes | mkfs.ext4 $ROOT >>$SALIDA 2>&1

# =========================
# MONTAJE
# =========================

echo ">> Montando sistema..."

mount $ROOT /mnt || exit 1
mkdir -p /mnt/boot
mount $EFI /mnt/boot || exit 1

# =========================
# FINAL
# =========================

echo "$DISCO" >/tmp/disco

echo ""
echo "Particionado completado."
