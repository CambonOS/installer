#!/bin/bash

# Ejecucion del script de dialog
pacman -Sy --no-confirm
pacman -S python-pip --no-confirm
pip install git+https://github.com/manucr19/py_lib.git
python3 installer/tui.py

# Monitorizacion del script de instalación
echo "0" >/tmp/PRG
(while [[ $(cat /tmp/PRG) -ne 100 ]]; do sleep 1; cat /tmp/PRG; done) | dialog --title " CambonOS Installer " --gauge "Instalando..." 7 80 0
