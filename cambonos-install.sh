#!/bin/bash

clear && cat /etc/motd
echo '
Bienbenido al instalador oficial de CambonOS!!!

Para continuar su intalacion escoga entre:

  1-CambonOS Archie
  2-CambonOS Debbie
  3-Cancelar'
echo -e "\n(1,2,3): \c" && read OPTION
case $OPTION in
  1) bash cambonos-archie.sh;;
  2) bash cambonos-debbie.sh;;
  3) exit;;
esac
