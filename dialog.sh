#!/bin/bash

sh installer/parted.sh

while true
do
	# Ventana de entrada de nombre del equipo
	NOMBRE=$(dialog --stdout --title " CambonOS Installer " --inputbox "\nNombre del equipo:" 10 80)
	
	# Ventana de entrada de nombre para el nuevo usuario
	USERNAME=$(dialog --stdout --title " CambonOS Installer " --inputbox "\nNombre para el nuevo usuario:" 10 80)
	USER=$(echo $USERNAME | awk '{print tolower($0)}')
	
	# Función para solicitar contraseña del usuario
	function SUDO {
	    PASS=$(dialog --stdout --title " CambonOS Installer " --passwordbox "\nContraseña del usuario:" 10 80)
	    PASS1=$(dialog --stdout --title " CambonOS Installer " --passwordbox "\nRepetir contraseña:" 10 80)
	    if [[ $PASS != $PASS1 ]]
	    then
	        dialog --title " CambonOS Installer " --msgbox "\n\nLas contraseñas no coinciden. Inténtelo de nuevo." 10 80
	        SUDO
	    fi
	}
	SUDO
	
	# Ventana de selección de instalación de controladores gráficos
	DG=$(dialog --stdout --title " CambonOS Installer " --yesno "\n\nDesea instalar los drivers gráficos?" 10 80 && echo "Si" || echo "No")
	
	# Ventana de selección de instalación de servidor SSH
	SSH=$(dialog --stdout --title " CambonOS Installer " --yesno "\n\nDesea instalar servidor SSH?" 10 80 && echo "Si" || echo "No")
	
	# Ventana de selección de actualizacion automatica
	UPGRADE=$(dialog --stdout --title " CambonOS Installer " --yesno "\n\nDesea que los paquetes del sistema se actualicen automáticamente??" 10 80 && echo "Si" || echo "No")
	
	# Ventana de selección de entorno de escritorio
	ESCRITORIO=$(dialog --stdout --title " CambonOS Installer " --menu "\n\nQué entorno de escritorio desea instalar?\n" 20 80 15 \
	        1 "Cambon18/XFCE (Recomendado)" \
	        2 "Cambon18/XFCE (Gaming)" \
	        3 "Cambon18/Qtile" \
	        4 "No instalar interfaz gráfica")
	
	# Disco de instalación
	DISCO=$(cat /tmp/disco)
	
	# Ventana de confirmación opciones	
	dialog --title " CambonOS Installer " --yesno "\nPor favor, confirme que las opciones seleccionadas son correctas:\n\nNombre del equipo: $NOMBRE\nNombre para el nuevo usuario: $USERNAME\nContraseña del usuario: ********\nInstalar los drivers gráficos: $DG\nInstalar servidor SSH: $SSH\nActualización automatica: $UPGRADE\nEntorno de escritorio seleccionado: $ESCRITORIO" 20 80 && break
done

# Ejecucion del script de instalación
sh installer/cambonos-install.sh $NOMBRE $USERNAME $PASS $DG $SSH $UPGRADE $ESCRITORIO $DISCO >/tmp/install 2>&1 &
dialog --no-cancel --title " CambonOS Installer " --tailbox /tmp/install 20 80
