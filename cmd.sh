#!/bin/bash
if [[ $EUID -ne 0 ]]
then 
	echo -e "Debese ejecutar como usuario con privilejios"
	exit
fi

cd /tmp/Scripts

cp ./CambonISO.sh /usr/bin/camboniso
chown root:root /usr/bin/camboniso
chmod 755 /usr/bin/camboniso

cp ./Actualizar.sh /usr/bin/actualizar
chown root:root /usr/bin/actualizar
chmod 755 /usr/bin/actualizar

cp ./git-Cambon.sh /usr/bin/git-cambon
chown root:root /usr/bin/git-cambon
chmod 755 /usr/bin/git-cambon
