# CambonOS
Distribución basada en Arch Linux con una instalación sencilla.

## Paquete `cambonos-installer`

El `PKGBUILD` construye el paquete Arch `cambonos-installer`. El ejecutable
`/usr/bin/cambonos-installer` contiene el flujo completo: selección de opciones,
particionado, instalación y configuración del sistema. La configuración base del
live se empaqueta directamente bajo `/usr/share/cambonos-installer/configs/` y
se incorpora al sistema sin una carpeta intermedia `cambonos-fs`.
Está destinado al entorno live de CambonOS y debe ejecutarse como root.

Permite una instalación limpia en BIOS o UEFI, o instalar en el mayor espacio
libre contiguo disponible en un disco GPT iniciado en modo UEFI. El modo de
espacio libre necesita una partición raíz de al menos 24 GiB y conserva las particiones existentes;
la instalación limpia elimina todas las particiones del disco seleccionado.
Revisa cuidadosamente el disco y el modo antes de confirmar.

Durante la instalación se solicita el nombre del usuario una sola vez. Ese
texto se conserva como nombre completo y se normaliza para el login: se pasa a
minúsculas y cada espacio se convierte en `-`. El login resultante debe tener
hasta 32 caracteres y usar solo letras ASCII, números, guiones o guiones bajos;
no puede comenzar por guion. La contraseña requiere al menos 8 caracteres,
una minúscula, una mayúscula, un número y un símbolo distinto de un espacio.

Para construirlo desde este repositorio en Arch Linux:

```sh
makepkg -si
```

# cambonos-upgrade
Script disponible una vez instalado CambonOS que permite actualizar de forma sencilla los paquetes del sistema incluyendo pacman y aur.
