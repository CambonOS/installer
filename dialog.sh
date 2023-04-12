#!/bin/bash

# Ventana de entrada de nombre del equipo
NOMBRE=$(dialog --stdout --title "CambonOS Installer" --inputbox "Nombre del equipo:" 0 0)

# Ventana de entrada de nombre para el nuevo usuario
USERNAME=$(dialog --stdout --title "CambonOS Installer" --inputbox "Nombre para el nuevo usuario:" 0 0)
USER=$(echo $USERNAME | awk '{print tolower($0)}')

# Función para solicitar contraseña del usuario
function SUDO {
    PASS=$(dialog --stdout --title "CambonOS Installer" --passwordbox "Contraseña del usuario:" 0 0)
    PASS1=$(dialog --stdout --title "CambonOS Installer" --passwordbox "Repetir contraseña:" 0 0)
    if [[ $PASS != $PASS1 ]]
    then
        dialog --title "CambonOS Installer" --msgbox "Las contraseñas no coinciden. Inténtelo de nuevo." 0 0
        SUDO
    fi
}

# Llamada a la función SUDO para solicitar la contraseña del usuario
SUDO

# Ventana de selección de instalación de controladores gráficos
DG=$(dialog --stdout --title "CambonOS Installer" --yesno "Desea instalar los drivers gráficos?" 0 0 && echo "Si" || echo "No")

# Ventana de selección de instalación de servidor SSH
SSH=$(dialog --stdout --title "CambonOS Installer" --yesno "Desea instalar servidor SSH?" 0 0 && echo "Si" || echo "No")

# Ventana de selección de entorno de escritorio
ESCRITORIO=$(dialog --stdout --title "CambonOS Installer" --menu "Qué entorno de escritorio desea instalar?" 0 0 0 \
        1 "Cambon18/XFCE (Recomendado)" \
        2 "Cambon18/XFCE (Gaming)" \
        3 "Cambon18/Qtile" \
        4 "No instalar interfaz gráfica")
        
dialog --title "CambonOS Installer" --yesno "Por favor, confirme que las opciones seleccionadas son correctas:\n\nNombre del equipo: $NOMBRE\nNombre para el nuevo usuario: $USERNAME\nContraseña del usuario: ********\nInstalar los drivers gráficos: $DG\nInstalar servidor SSH: $SSH\nEntorno de escritorio seleccionado: $ESCRITORIO" 0 0

# Salida de resultados
echo "cambonos-install $NOMBRE $USERNAME $PASS $DG $SSH $ESCRITORIO"
