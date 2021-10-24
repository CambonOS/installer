#!/bin/bash

NETWORK () {
ping -c 3 google.com >/dev/null 2>&1 || \
(clear && cat /etc/motd && \
echo 'Fallo en la conecxion a internet, selecciona opcion:

1.Reintentar conecxion cableada
2.Configurar wifi
3.Cancelar' && \
echo -e "\n(1,2,3): \c" && read OPTION
case $OPTION in
  1) sleep 1 && NETWORK;;
  2) echo -e '\n>>Introduce el SSID: \c' && read SSID && \
  (iwctl station wlan0 connect-hidden $SSID 2>/dev/null|| iwctl station wlan0 connect $SSID 2>/dev/null)
  echo Connecting...
  sleep 2
  NETWORK;;
  3) exit;;
esac)
}

NETWORK
clear && cat /etc/motd
echo '
Bienbenido al instalador oficial de CambonOS!!!

Para continuar su intalacion escoga entre:

  1-CambonOS Archie
  2-CambonOS Debbie
  3-Cancelar'
echo -e "\n(1,2,3): \c" && read OPTION
case $OPTION in
  1) bash linux/cambonos-archie.sh;;
  2) bash linux/cambonos-debbie.sh;;
  3) exit;;
esac
