#!/bin/bash
while true
do
	# Ventana de entrada de nombre del equipo
	NOMBRE=$(dialog --stdout --title "CambonOS Installer" --inputbox "Nombre del equipo:" 20 80)
	
	# Ventana de entrada de nombre para el nuevo usuario
	USERNAME=$(dialog --stdout --title "CambonOS Installer" --inputbox "Nombre para el nuevo usuario:" 20 80)
	USER=$(echo $USERNAME | awk '{print tolower($0)}')
	
	# Función para solicitar contraseña del usuario
	function SUDO {
	    PASS=$(dialog --stdout --title "CambonOS Installer" --passwordbox "Contraseña del usuario:" 20 80)
	    PASS1=$(dialog --stdout --title "CambonOS Installer" --passwordbox "Repetir contraseña:" 20 80)
	    if [[ $PASS != $PASS1 ]]
	    then
	        dialog --title "CambonOS Installer" --msgbox "Las contraseñas no coinciden. Inténtelo de nuevo." 20 80
	        SUDO
	    fi
	}
	SUDO
	
	# Ventana de selección de instalación de controladores gráficos
	DG=$(dialog --stdout --title "CambonOS Installer" --yesno "Desea instalar los drivers gráficos?" 20 80 && echo "Si" || echo "No")
	
	# Ventana de selección de instalación de servidor SSH
	SSH=$(dialog --stdout --title "CambonOS Installer" --yesno "Desea instalar servidor SSH?" 20 80 && echo "Si" || echo "No")
	
	# Ventana de selección de actualizacion automatica
	UPGRADE=$(dialog --stdout --title "CambonOS Installer" --yesno "Desea que los paquetes del sistema se actualicen automáticamente??" 20 80 && echo "Si" || echo "No")
	
	# Ventana de selección de entorno de escritorio
	ESCRITORIO=$(dialog --stdout --title "CambonOS Installer" --menu "Qué entorno de escritorio desea instalar?" 20 80 15 \
	        1 "Cambon18/XFCE (Recomendado)" \
	        2 "Cambon18/XFCE (Gaming)" \
	        3 "Cambon18/Qtile" \
	        4 "No instalar interfaz gráfica")
	
	# Disco de instalación
	DISCO=$1
	
	# Ventana de confirmación opciones	
	dialog --title "CambonOS Installer" --yesno "Por favor, confirme que las opciones seleccionadas son correctas:\n\nNombre del equipo: $NOMBRE\nNombre para el nuevo usuario: $USERNAME\nContraseña del usuario: ********\nInstalar los drivers gráficos: $DG\nInstalar servidor SSH: $SSH\nActualización automatica: $UPGRADE\nEntorno de escritorio seleccionado: $ESCRITORIO" 20 80 && break
done

# Ejecucion del script de instalación
sh installer/cambonos-install.sh $NOMBRE $USERNAME $PASS $DG $SSH $UPGRADE $ESCRITORIO $DISCO | pv -n -i 1 -t -B 1 | dialog --title "CambonOS Installer" --gauge "Instalando sistema:" 20 80

# Mensaje final instalación
dialog --title "CambonOS Installer" --msgbox "La instalación se ha completado. Retire el USB y pulse enter." 20 80 && reboot
