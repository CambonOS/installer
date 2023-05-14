#!/bin/bash

# Ejecucion del script de particionado
sh installer/parted.sh

while true
do
	# Ventana de entrada de nombre del equipo
	NOMBRE=$(dialog --stdout --title " CambonOS Installer " --inputbox "\nNombre del equipo:" 10 80)
	NOMBRE=$(echo $NOMBRE | awk '{print tolower($0)}')
	
	
	# Función para solicitar contraseña del usuario
	function is_secure_password {
	    local password="$1"
	    local has_uppercase=$(echo "$password" | grep -c "[A-Z]")
	    local has_lowercase=$(echo "$password" | grep -c "[a-z]")
	    local has_number=$(echo "$password" | grep -c "[0-9]")
	    local has_special=$(echo "$password" | grep -c "[!@#\$%\^&\*\-\+\=\.]")
	    if [[ $has_uppercase -gt 0 && $has_lowercase -gt 0 && $has_number -gt 0 && $has_special -gt 0 && ${#password} -ge 12 ]]
	    then
	        return 0
	    else
	        return 1
	    fi
	}
	
	function SUDO {
	    PASS=$(dialog --stdout --title " CambonOS Installer " --passwordbox "\nContraseña del usuario:" 10 80)
	    PASS1=$(dialog --stdout --title " CambonOS Installer " --passwordbox "\nRepetir contraseña:" 10 80)
	    if [[ $PASS != $PASS1 ]]
	    then
	        dialog --title " CambonOS Installer " --msgbox "\nLas contraseñas no coinciden. Inténtelo de nuevo." 7 80
	        SUDO
            else
			if ! is_secure_password "$PASS"
	    		then
	        		dialog --title " CambonOS Installer " --msgbox "\nLa contraseña no cumple con los criterios de seguridad. Debe contener al menos 12 caracteres, una letra mayúscula, una letra minúscula, un número y un carácter especial." 7 80
	        		SUDO
            		else
				echo $PASS
	    		fi
            fi
	}
	
	# Ventana de entrada de nombre para el nuevo usuario administrador
	ADMINNAME=$(dialog --stdout --title " CambonOS Installer " --inputbox "\nNombre para el usuario administrador:" 10 80 "Administrador")
	ADMINPASS=$(SUDO)
	
	# Ventana de entrada de nombre para el nuevo usuario sin privilegios
       	USERNAME=$(dialog --stdout --title " CambonOS Installer " --inputbox "\nNombre para el nuevo usuario sin privilegios:" 10 80)
	USERPASS=$(SUDO)

	# Ventana de selección de instalación de controladores gráficos
	DG=$(dialog --stdout --title " CambonOS Installer " --yesno "\nDesea instalar los drivers gráficos?" 7 80 && echo "Si" || echo "No")
	
	# Ventana de selección de instalación de servidor SSH
	SSH=$(dialog --stdout --title " CambonOS Installer " --yesno "\nDesea instalar servidor SSH?" 7 80 && echo "Si" || echo "No")
	
	# Ventana de selección de actualizacion automatica
	UPGRADE=$(dialog --stdout --title " CambonOS Installer " --yesno "\nDesea que los paquetes del sistema se actualicen automáticamente?" 7 80 && echo "Si" || echo "No")
	
	# Ventana de selección de entorno de escritorio
	ESCRITORIO=$(dialog --stdout --title " CambonOS Installer " --menu "\nQué entorno de escritorio desea instalar?\n" 15 80 10 \
	        1 "Cambon18/XFCE (Recomendado)" \
	        2 "Cambon18/Qtile" \
	        3 "No instalar interfaz gráfica")
	
	# Disco de instalación
	DISCO=$(cat /tmp/disco)
	
	# Ventana de confirmación opciones	
	dialog --title " CambonOS Installer " --yesno "\nPor favor, confirme que las opciones seleccionadas son correctas:\n\nNombre del equipo: $NOMBRE\nNombre para el administrador: $ADMINNAME\nNombre para el nuevo usuario: $USERNAME\nInstalar los drivers gráficos: $DG\nInstalar servidor SSH: $SSH\nActualización automatica: $UPGRADE\nEntorno de escritorio seleccionado: $ESCRITORIO" 15 80 && break
done

# Ejecucion del script de instalación
sh installer/cambonos-install.sh $NOMBRE $ADMINNAME $ADMINPASS $USERNAME $USERPASS $DG $SSH $UPGRADE $ESCRITORIO $DISCO >/tmp/install 2>&1 &

# Monitorizacion del script de instalación
echo "0" >/tmp/PRG
(while [[ $(cat /tmp/PRG) -ne 100 ]]; do sleep 1; cat /tmp/PRG; done) | dialog --title " CambonOS Installer " --gauge "Instalando..." 7 80 0

