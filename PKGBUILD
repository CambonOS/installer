pkgname=cambonos-installer
pkgver=0.1.0
pkgrel=1
pkgdesc="CambonOS live system installer"
arch=('any')
url="https://github.com/CambonOS/installer"
license=('GPL-3.0-only')
depends=('arch-install-scripts' 'bash' 'coreutils' 'dialog' 'dosfstools'
         'e2fsprogs' 'gawk' 'pacman' 'pciutils' 'reflector' 'systemd'
         'util-linux')

package() {
  local data_dir="$pkgdir/usr/share/cambonos-installer/installer"

  install -Dm644 "$startdir/LICENSE" \
    "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
  install -Dm755 "$startdir/cambonos-installer" \
    "$pkgdir/usr/bin/cambonos-installer"
  install -Dm644 "$startdir/dialog.sh" "$data_dir/dialog.sh"
  install -Dm644 "$startdir/parted.sh" "$data_dir/parted.sh"
  install -Dm644 "$startdir/cambonos-install.sh" "$data_dir/cambonos-install.sh"
  cp -a "$startdir/cambonos-fs" "$data_dir/cambonos-fs"
}