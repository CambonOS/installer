import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class InstallerPackageTests(unittest.TestCase):
    def test_package_metadata_and_payload(self):
        build = (ROOT / "PKGBUILD").read_text()
        self.assertIn("pkgname=cambonos-installer", build)
        self.assertIn("/usr/share/cambonos-installer/installer", build)
        self.assertIn('cp -a "$startdir/cambonos-fs"', build)
        self.assertTrue((ROOT / "cambonos-fs").is_dir())
        self.assertTrue((ROOT / "LICENSE").is_file())

    def test_entrypoints_have_valid_bash_syntax(self):
        for path in (
            ROOT / "PKGBUILD",
            ROOT / "cambonos-installer",
            ROOT / "dialog.sh",
            ROOT / "parted.sh",
            ROOT / "cambonos-install.sh",
        ):
            with self.subTest(path=path.name):
                subprocess.run(["bash", "-n", str(path)], check=True)

    def test_launcher_preserves_relative_script_layout(self):
        launcher = (ROOT / "cambonos-installer").read_text()
        self.assertIn("cd /usr/share/cambonos-installer", launcher)
        self.assertIn("installer/dialog.sh", launcher)


if __name__ == "__main__":
    unittest.main()