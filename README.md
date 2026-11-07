# CambonOS
Distribución basada en Arch Linux con una instalación sencilla.

## Paquete `cambonos-installer`

El `PKGBUILD` de este repositorio construye el paquete Arch `cambonos-installer`.
Instala el launcher `/usr/bin/cambonos-installer` y conserva los scripts y el
árbol `cambonos-fs/` bajo `/usr/share/cambonos-installer/installer/`. Está
destinado al entorno live de CambonOS; no debe ejecutarse como instalador de un
sistema ya instalado.

Para construirlo desde este repositorio en Arch Linux:

```sh
makepkg -si
```

La lógica existente de instalación se conserva. El launcher cambia al directorio
de datos para que las rutas relativas `installer/...` sigan resolviendo.

# cambonos-install.sh
Script de instalación que se ejecuta desde la ISO del realese e instala CambonOS en el disco seleccionado borrando todo el contenido del mismo, o bien en el espacio libre al final del disco siempre que este este en formato gpt y la iso se arranque mediante efi.

# cambonos-upgrade
Script disponible una vez instalado CambonOS que permite actualizar de forma sencilla los paquetes del sistema incluyendo pacman y aur.
