#!/bin/bash

cd /tmp

git clone https://github/CambonOS/Scripts.git
cd Scripts

cp ./CambonISO.sh /usr/bin/camboniso
chown root:root /usr/bin/camboniso
chmod 755 /usr/bin/camboniso

cp ./Actualizar.sh /usr/bin/actualizar
chown root:root /usr/bin/actualizar
chmod 755 /usr/bin/actualizar

cp ./cmd.sh /usr/bin/actualizarcmd
chown root:root /usr/bin/actualizarcmd
chmod 755 /usr/bin/actualizarcmd
