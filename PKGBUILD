pkgname=cambonos-installer
pkgver=0.1.5
pkgrel=1
pkgdesc="CambonOS live system installer"
arch=('any')
url="https://github.com/CambonOS/installer"
license=('GPL-3.0-only')
depends=('arch-install-scripts' 'bash' 'coreutils' 'dialog' 'dosfstools'
         'e2fsprogs' 'gawk' 'pacman' 'parted' 'pciutils' 'reflector'
         'systemd' 'util-linux')

package() {
  local data_dir="$pkgdir/usr/share/cambonos-installer/configs"

  install -Dm644 "$startdir/LICENSE" \
    "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
  install -Dm755 "$startdir/files/bin/cambonos-installer" \
    "$pkgdir/usr/bin/cambonos-installer"
  install -d "$data_dir"
  cp -a "$startdir/files/configs/." "$data_dir/"
}