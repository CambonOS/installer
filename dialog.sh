#!/bin/bash

# Ignorar señal suspension TTY
set -o ignoreeof

# Ejecucion del script de particionado
sh installer/parted.sh

while true
do
	# Ventana de entrada de nombre del equipo
	NOMBRE=$(dialog --no-cancel --stdout --title " CambonOS Installer " --inputbox "\nNombre del equipo:" 10 80)
	
	# Ventana de entrada de nombre para el nuevo usuario
	USERNAME=$(dialog --no-cancel --stdout --title " CambonOS Installer " --inputbox "\nNombre para el nuevo usuario:" 10 80)
	USER=$(echo $USERNAME | awk '{print tolower($0)}')
	
	# Función para solicitar contraseña del usuario
	function SUDO {
	    PASS=$(dialog --no-cancel --stdout --title " CambonOS Installer " --passwordbox "\nContraseña del usuario:" 10 80)
	    PASS1=$(dialog --no-cancel --stdout --title " CambonOS Installer " --passwordbox "\nRepetir contraseña:" 10 80)
	    if [[ $PASS != $PASS1 ]]
	    then
	        dialog --no-cancel --title " CambonOS Installer " --msgbox "\nLas contraseñas no coinciden. Inténtelo de nuevo." 7 80
	        SUDO
	    fi
	}
	SUDO
	
	# Ventana de selección de instalación de controladores gráficos
	DG=$(dialog --no-cancel --stdout --title " CambonOS Installer " --yesno "\nDesea instalar los drivers gráficos?" 7 80 && echo "Si" || echo "No")
	
	# Ventana de selección de instalación de servidor SSH
	SSH=$(dialog --no-cancel --stdout --title " CambonOS Installer " --yesno "\nDesea instalar servidor SSH?" 7 80 && echo "Si" || echo "No")
	
	# Ventana de selección de actualizacion automatica
	UPGRADE=$(dialog --no-cancel --stdout --title " CambonOS Installer " --yesno "\nDesea que los paquetes del sistema se actualicen automáticamente?" 7 80 && echo "Si" || echo "No")
	
	# Ventana de selección de entorno de escritorio
	ESCRITORIO=$(dialog --no-cancel --stdout --title " CambonOS Installer " --menu "\nQué entorno de escritorio desea instalar?\n" 15 80 10 \
	        1 "Cambon18/XFCE (Recomendado)" \
	        2 "Cambon18/XFCE (Gaming)" \
	        3 "Cambon18/Qtile" \
	        4 "No instalar interfaz gráfica")
	
	# Disco de instalación
	DISCO=$(cat /tmp/disco)
	
	# Ventana de confirmación opciones	
	dialog --no-cancel --title " CambonOS Installer " --yesno "\nPor favor, confirme que las opciones seleccionadas son correctas:\n\nNombre del equipo: $NOMBRE\nNombre para el nuevo usuario: $USERNAME\nContraseña del usuario: ********\nInstalar los drivers gráficos: $DG\nInstalar servidor SSH: $SSH\nActualización automatica: $UPGRADE\nEntorno de escritorio seleccionado: $ESCRITORIO" 15 80 && break
done

# Ejecucion del script de instalación
sh installer/cambonos-install.sh $NOMBRE $USERNAME $PASS $DG $SSH $UPGRADE $ESCRITORIO $DISCO >/tmp/install 2>&1 &

# Monitorizacion del script de instalación
dialog --no-cancel --no-mouse --title " CambonOS Installer " --tailbox /tmp/install 25 80
echo $?
#dialog --no-cancel --title " CambonOS Installer " --msgbox "\n\nSe ha completado la instalacion de CambonOS.\nRetira el USB y pulsa enter." 7 80 && reboot
