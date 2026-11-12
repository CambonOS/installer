pkgname=cambonos-installer
pkgver=0.1.7
pkgrel=1
pkgdesc="CambonOS live system installer"
arch=('any')
url="https://github.com/CambonOS/cambonos-installer"
license=('GPL-3.0-only')
depends=('arch-install-scripts' 'bash' 'coreutils' 'curl' 'dialog' 'dosfstools'
         'e2fsprogs' 'gawk' 'networkmanager' 'pacman' 'parted' 'pciutils' 'reflector'
         'systemd' 'util-linux')

package() {
  local data_dir="$pkgdir/usr/share/cambonos-installer/configs"
  local version_file="$pkgdir/usr/share/cambonos-installer/version"

  install -Dm644 "$startdir/LICENSE" \
    "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
  install -Dm755 "$startdir/files/bin/cambonos-installer" \
    "$pkgdir/usr/bin/cambonos-installer"
  install -d "$data_dir"
  cp -a "$startdir/files/configs/." "$data_dir/"
  printf '%s-%s\n' "$pkgver" "$pkgrel" > "$version_file"
}