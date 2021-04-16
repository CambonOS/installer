#!/bin/bash
if [[ $EUID -ne 0 ]]
then 
	echo -e "Debese ejecutar como usuario con privilejios"
	exit 1
fi

cd /tmp/Scripts

cp ./camboniso.sh /usr/bin/cambonos-iso

cp ./actualizar.sh /usr/bin/cambonos-update
