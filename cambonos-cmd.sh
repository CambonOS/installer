#!/bin/bash
NOCOLOR='\033[0m'
RED='\033[1;31m'
GREEN='\033[1;32m'

ERROR () {
	echo -e "${RED}[ERROR]${NOCOLOR}"
	exit
}

cd /tmp/arch-distro || ERROR

sudo cp ./cambonos-iso.sh /usr/bin/cambonos-iso || ERROR
sudo chmod 755 /usr/bin/cambonos-iso || ERROR

sudo cp ./cambonos.sh /usr/bin/cambonos || ERROR
sudo chmod 755 /usr/bin/cambonos || ERROR

echo -e "${GREEN}[DONE]${NOCOLOR}"
