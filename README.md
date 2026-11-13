# CambonOS
Distribución basada en Arch Linux con una instalación sencilla.

## Paquete `cambonos-installer`

El `PKGBUILD` construye el paquete Arch `cambonos-installer`. El ejecutable
`/usr/bin/cambonos-installer` contiene el flujo completo: selección de opciones,
particionado, instalación y configuración del sistema. La configuración base del
live se empaqueta directamente bajo `/usr/share/cambonos-installer/configs/` y
se incorpora al sistema sin una carpeta intermedia `cambonos-fs`.
Está destinado al entorno live de CambonOS y debe ejecutarse como root.

Al iniciar el instalador, se activa NetworkManager y se comprueba la conexión al
mirror geo de Arch. Tras cinco fallos se abre `nmtui` y se vuelve a intentar.
Después se ejecuta `pacman -Syu --noconfirm cambonos-installer` y se muestra su
salida; si falla, la instalación no continúa. Tras una actualización correcta,
el instalador se reinicia una vez para usar la versión instalada, incluso si no
había una versión nueva. La opción `--help` no realiza estas operaciones.

Permite una instalación limpia en BIOS o UEFI, o instalar en el mayor espacio
libre contiguo disponible en un disco GPT iniciado en modo UEFI. El modo de
espacio libre necesita una partición raíz de al menos 24 GiB y conserva las particiones existentes;
la instalación limpia elimina todas las particiones del disco seleccionado.
Revisa cuidadosamente el disco y el modo antes de confirmar.
En UEFI, el instalador recrea la entrada de CambonOS apuntando a la partición
EFI de la instalación actual y comprueba que la entrada haya quedado registrada.

El menú ofrece Cambon18/XFCE, Cambon18/Qtile y CambonOS/XFCE. Esta última opción
instala el metapaquete `cambonos-xfce` mediante Pacman y selecciona su sesión en
LightDM. Antes de particionar, comprueba que el paquete esté disponible en el
canal del paquete `cambonos-pacman` elegido para el sistema de destino. Las dos
opciones Cambon18 siguen requiriendo sus fuentes y `archie.sh` en el live.

Durante la instalación se solicita el nombre del usuario una sola vez. Ese
texto se conserva como nombre completo y se normaliza para el login: se pasa a
minúsculas y cada espacio se convierte en `-`. El login resultante debe tener
hasta 32 caracteres y usar solo letras ASCII, números, guiones o guiones bajos;
no puede comenzar por guion. La contraseña requiere al menos 8 caracteres,
una minúscula, una mayúscula, un número y un símbolo distinto de un espacio.

Durante la instalación, la barra muestra la etapa activa para que las
operaciones largas no parezcan detenidas. El porcentaje es orientativo y avanza
por etapas; no representa una medición continua del trabajo restante.

Para construirlo desde este repositorio en Arch Linux:

```sh
makepkg -si
```

# cambonos-upgrade
Script disponible una vez instalado CambonOS que permite actualizar de forma sencilla los paquetes del sistema incluyendo pacman y aur.

## CI entre repositorios

Los pushes a `dev` y `main` ejecutan los tests de este repositorio. Si pasan,
GitHub Actions envía a `cambonos-packages` el evento `external-package-updated`
con el repositorio, la rama y el commit como metadatos. El workflow receptor de
`cambonos-packages` debe aceptar ese evento para iniciar la reconstrucción.

Configura en este repositorio el secreto `CAMBONOS_PACKAGES_DISPATCH_TOKEN` con
un fine-grained personal access token limitado al repositorio
`CambonOS/cambonos-packages` y permiso `Contents: write`. Protege las ramas
`dev` y `main`; el token solo se utiliza en el paso de notificación, después de
que terminen los tests.
