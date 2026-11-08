import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class InstallerPackageTests(unittest.TestCase):
    def test_package_metadata_and_payload(self):
        build = (ROOT / "PKGBUILD").read_text()
        self.assertIn("pkgname=cambonos-installer", build)
        self.assertIn("pkgrel=5", build)
        self.assertIn("'parted'", build)
        self.assertIn("/usr/share/cambonos-installer/installer", build)
        self.assertIn('cp -a "$startdir/cambonos-fs"', build)
        self.assertTrue((ROOT / "cambonos-fs").is_dir())
        self.assertTrue((ROOT / "LICENSE").is_file())

    def test_entrypoints_have_valid_bash_syntax(self):
        for path in (
            ROOT / "PKGBUILD",
            ROOT / "cambonos-installer",
        ):
            with self.subTest(path=path.name):
                subprocess.run(["bash", "-n", str(path)], check=True)

    def test_installation_flow_lives_in_the_single_entrypoint(self):
        installer = (ROOT / "cambonos-installer").read_text()
        self.assertIn("collect_options()", installer)
        self.assertIn("create_partitions()", installer)
        self.assertIn("perform_installation()", installer)
        self.assertIn("configure_system()", installer)
        self.assertNotIn("installer/dialog.sh", installer)
        for path in ("dialog.sh", "parted.sh", "cambonos-install.sh"):
            self.assertFalse((ROOT / path).exists())

    def test_sudoers_mode_is_fixed_before_validation(self):
        installer = (ROOT / "cambonos-installer").read_text()
        set_mode = 'chmod 440 "$MOUNT_POINT/etc/sudoers"'
        self.assertIn(set_mode, installer)
        self.assertLess(installer.index(set_mode), installer.index("run_chroot visudo -c"))

    def test_help_does_not_start_the_installer(self):
        result = subprocess.run(
            ["bash", str(ROOT / "cambonos-installer"), "--help"],
            check=True,
            capture_output=True,
            text=True,
        )
        self.assertIn("sistema live", result.stdout)

    def test_unknown_argument_is_rejected(self):
        result = subprocess.run(
            ["bash", str(ROOT / "cambonos-installer"), "--invalid"],
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 2)


if __name__ == "__main__":
    unittest.main()