#!/bin/bash
NOCOLOR='\033[0m'
RED='\033[1;31m'
GREEN='\033[1;32m'

ERROR () {
	echo -e "${RED} [ERROR] ${NOCOLOR}"
	exit
}

cd /tmp/Scripts || ERROR

sudo cp ./camboniso.sh /usr/bin/cambonos-iso || ERROR
sudo chmod 755 /usr/bin/cambonos-iso || ERROR

sudo cp ./actualizar.sh /usr/bin/cambonos-upgrade || ERROR
sudo chmod 755 /usr/bin/cambonos-upgrade || ERROR

echo -e "${GREEN} [DONE] ${NOCOLOR}"
