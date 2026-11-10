import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class InstallerPackageTests(unittest.TestCase):
    def test_package_metadata_and_payload(self):
        build = (ROOT / "PKGBUILD").read_text()
        self.assertIn("pkgname=cambonos-installer", build)
        self.assertIn("pkgrel=1", build)
        self.assertIn("'parted'", build)
        self.assertIn("/usr/share/cambonos-installer/configs", build)
        self.assertIn("printf '%s-%s\\n' \"$pkgver\" \"$pkgrel\"", build)
        self.assertIn('/usr/share/cambonos-installer/version', build)
        self.assertIn('cp -a "$startdir/files/configs/."', build)
        self.assertTrue((ROOT / "files" / "configs" / "etc").is_dir())
        self.assertTrue((ROOT / "files" / "configs" / "usr").is_dir())
        self.assertTrue((ROOT / "LICENSE").is_file())

    def test_entrypoints_have_valid_bash_syntax(self):
        for path in (
            ROOT / "PKGBUILD",
            ROOT / "files" / "bin" / "cambonos-installer",
        ):
            with self.subTest(path=path.name):
                subprocess.run(["bash", "-n", str(path)], check=True)

    def test_installation_flow_lives_in_the_single_entrypoint(self):
        installer = (ROOT / "files" / "bin" / "cambonos-installer").read_text()
        self.assertIn('readonly TITLE="CambonOS Installer ${PACKAGE_VERSION}"', installer)
        self.assertIn('PACKAGE_VERSION=$(<"$VERSION_FILE")', installer)
        self.assertIn("collect_options()", installer)
        self.assertIn("create_partitions()", installer)
        self.assertIn("perform_installation()", installer)
        self.assertIn("configure_system()", installer)
        self.assertNotIn("installer/dialog.sh", installer)
        for path in ("dialog.sh", "parted.sh", "cambonos-install.sh"):
            self.assertFalse((ROOT / path).exists())

    def test_account_name_normalization_and_password_requirements(self):
        installer = ROOT / "files" / "bin" / "cambonos-installer"
        result = subprocess.run(
            [
                "bash",
                "-c",
                'source "$1"; '
                'printf "%s\\n" "$(normalize_admin_user "Ana Maria Lopez")"; '
                'valid_admin_user "ana-maria-lopez"; '
                '! valid_admin_user "ana.lopez"; '
                '! valid_admin_user "-ana"; '
                '! valid_admin_user "abcdefghijklmnopqrstuvwxyz1234567"; '
                'password_meets_requirements "Cambonos9!"; '
                '! password_meets_requirements "cambonos9!"; '
                '! password_meets_requirements "Cambonos!"; '
                '! password_meets_requirements "Cambonos9 "; '
                '! password_meets_requirements "Cambonos9"',
                "bash",
                str(installer),
            ],
            check=True,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.stdout.strip(), "ana-maria-lopez")

        source = installer.read_text()
        self.assertEqual(source.count("Nombre del usuario (se usará también para iniciar sesión):"), 1)
        self.assertNotIn("Usuario administrador (login):", source)

    def test_base_and_grub_packages_replace_individual_dependencies(self):
        installer = (ROOT / "files" / "bin" / "cambonos-installer").read_text()
        bootstrap_packages = installer.split("base_packages=(", 1)[1].split(")", 1)[0].split()
        system_packages = installer.split("system_packages=(", 1)[1].split(")", 1)[0].split()

        self.assertEqual(
            bootstrap_packages,
            ["base", "linux", "linux-firmware", "cambonos-keyring", "cambonos-pacman"],
        )
        self.assertIn("cambonos-base", system_packages)
        self.assertIn("cambonos-grub", system_packages)
        for package in (
            "cambonos-release",
            "cambonos-branding",
            "cambonos-fastfetch",
            "cambonos-shell-prompt",
            "cambonos-zsh",
            "grub",
            "os-prober",
        ):
            with self.subTest(package=package):
                self.assertNotIn(package, bootstrap_packages)
                self.assertNotIn(package, system_packages)
        for package in system_packages:
            with self.subTest(installed_after_pacstrap=package):
                self.assertNotIn(package, bootstrap_packages)
        self.assertIn('"${system_packages[@]}"', installer)
        self.assertIn('run_chroot pacman -Syu --noconfirm', installer)

    def test_sudoers_mode_is_fixed_before_validation(self):
        installer = (ROOT / "files" / "bin" / "cambonos-installer").read_text()
        set_mode = 'chmod 440 "$MOUNT_POINT/etc/sudoers"'
        self.assertIn(set_mode, installer)
        self.assertLess(installer.index(set_mode), installer.index("run_chroot visudo -c"))

    def test_help_does_not_start_the_installer(self):
        result = subprocess.run(
            ["bash", str(ROOT / "files" / "bin" / "cambonos-installer"), "--help"],
            check=True,
            capture_output=True,
            text=True,
        )
        self.assertIn("sistema live", result.stdout)

    def test_unknown_argument_is_rejected(self):
        result = subprocess.run(
            ["bash", str(ROOT / "files" / "bin" / "cambonos-installer"), "--invalid"],
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 2)


if __name__ == "__main__":
    unittest.main()