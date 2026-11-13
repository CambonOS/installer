import os
import re
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class InstallerPackageTests(unittest.TestCase):
    def test_package_metadata_and_payload(self):
        build = (ROOT / "PKGBUILD").read_text()
        self.assertIn("pkgname=cambonos-installer", build)
        self.assertIn("pkgrel=2", build)
        self.assertIn("'curl'", build)
        self.assertIn("'networkmanager'", build)
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

    def test_desktop_menu_keeps_legacy_options_and_adds_cambonos_xfce(self):
        installer = ROOT / "files" / "bin" / "cambonos-installer"
        for selection, desktop in (("1", "xfce"), ("2", "qtile"), ("3", "cambonos-xfce")):
            with self.subTest(selection=selection):
                result = subprocess.run(
                    [
                        "bash", "-c",
                        'source "$1"; selection=$2; '
                        'dialog_input() { case "$*" in '
                        '*"Nombre del equipo"*) printf test-host ;; '
                        '*"Nombre del usuario"*) printf Testuser ;; '
                        '*--passwordbox*) printf "Password9!" ;; '
                        '*"Seleccione el entorno"*) '
                        '[[ "$*" == *"Cambon18/XFCE"* && "$*" == *"Cambon18/Qtile"* && "$*" == *"CambonOS/XFCE"* ]] || return 1; '
                        'printf "%s" "$selection" ;; '
                        '*"Modo de instalación"*) printf clean ;; '
                        '*) return 1 ;; esac; }; '
                        'dialog() { [[ "$*" != *"¿Desea instalar el servidor SSH?"* ]]; }; '
                        'choose_disk() { DISK=/dev/test; }; '
                        'collect_options; printf "%s\\n" "$DESKTOP"',
                        "menu-test", str(installer), selection,
                    ], capture_output=True, text=True,
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout.strip(), desktop)

    def test_cambonos_xfce_preflight_checks_the_destination_channel(self):
        installer = ROOT / "files" / "bin" / "cambonos-installer"
        for repository in ("cambonos", "cambonos-testing"):
            for available in ("yes", "no"):
                with self.subTest(repository=repository, available=available):
                    result = subprocess.run(
                        [
                            "bash", "-c",
                            'source "$1"; DESKTOP=cambonos-xfce; repository=$2; available=$3; '
                            'pacman() { case "$1" in '
                            '-Sp) [[ "$*" == "-Sp --nodeps --print-format %r cambonos-pacman" ]] || return 2; '
                            'printf "%s\\n" "$repository" ;; '
                            '-Si) [[ "$2" == "$repository/cambonos-xfce" && "$available" == yes ]] ;; '
                            '*) return 2 ;; esac; }; '
                            'check_desktop_source; printf "%s\\n" "$DESKTOP_REPOSITORY"',
                            "preflight-test", str(installer), repository, available,
                        ], capture_output=True, text=True,
                    )
                    self.assertEqual(result.returncode, 0 if available == "yes" else 1, result.stderr)
                    if available == "yes":
                        self.assertEqual(result.stdout.strip(), repository)
                    else:
                        self.assertIn("no está disponible", result.stderr)

    def test_legacy_desktop_preflight_requires_archie(self):
        installer = ROOT / "files" / "bin" / "cambonos-installer"
        with tempfile.TemporaryDirectory() as directory:
            for desktop in ("xfce", "qtile"):
                source = Path(directory) / desktop
                source.mkdir()
                for available in (False, True):
                    with self.subTest(desktop=desktop, available=available):
                        if available:
                            (source / "archie.sh").touch()
                        result = subprocess.run(
                            [
                                "bash", "-c",
                                'source "$1"; DESKTOP=$2; '
                                'pacman() { exit 99; }; check_desktop_source "$3"',
                                "legacy-preflight-test", str(installer), desktop, directory,
                            ], capture_output=True, text=True,
                        )
                        self.assertEqual(result.returncode, 0 if available else 1, result.stderr)
                        if not available:
                            self.assertIn("archie.sh", result.stderr)

    def test_cambonos_xfce_installation_and_failure(self):
        installer = ROOT / "files" / "bin" / "cambonos-installer"
        for repository in ("cambonos", "cambonos-testing"):
            for install_status in (0, 42):
                with self.subTest(repository=repository, install_status=install_status):
                    with tempfile.TemporaryDirectory() as directory:
                        result = subprocess.run(
                            [
                                "bash", "-c",
                                'source "$1"; DESKTOP=cambonos-xfce; DESKTOP_REPOSITORY=$2; install_status=$3; '
                                'run_chroot() { printf "%s\\n" "$*"; return "$install_status"; }; '
                                'cp() { exit 99; }; install_desktop "$4"',
                                "desktop-test", str(installer), repository, str(install_status), directory,
                            ], capture_output=True, text=True,
                        )
                        session = Path(directory) / "etc/lightdm/lightdm.conf.d/60-cambonos-xfce-session.conf"
                        self.assertEqual(result.returncode, install_status, result.stderr)
                        self.assertEqual(result.stdout.strip(), f"pacman -Syu --noconfirm {repository}/cambonos-xfce")
                        self.assertEqual(session.exists(), install_status == 0)
                        if install_status == 0:
                            self.assertEqual(session.read_text(), "[Seat:*]\nuser-session=cambonos-xfce\n")

    def test_legacy_desktop_installation_still_runs_archie(self):
        installer = ROOT / "files" / "bin" / "cambonos-installer"
        for desktop in ("xfce", "qtile"):
            with self.subTest(desktop=desktop):
                result = subprocess.run(
                    [
                        "bash", "-c",
                        'source "$1"; DESKTOP=$2; '
                        'cp() { printf "copy:%s\\n" "$*"; }; '
                        'rm() { printf "remove:%s\\n" "$*"; }; '
                        'run_chroot() { printf "chroot:%s\\n" "$*"; }; '
                        'install_desktop /temporary-target',
                        "legacy-desktop-test", str(installer), desktop,
                    ], capture_output=True, text=True,
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout.splitlines(), [
                    f"copy:-a /root/{desktop} /temporary-target/{desktop}",
                    f"chroot:chown -R updates:updates /{desktop}",
                    f"chroot:su -s /bin/bash updates -c cd /{desktop} && bash archie.sh",
                    f"remove:-rf -- /temporary-target/{desktop}",
                ])

    def test_network_retries_and_opens_nmtui(self):
        installer = ROOT / "files" / "bin" / "cambonos-installer"
        result = subprocess.run(
            [
                "bash", "-c",
                'source "$1"; checks=0; nmtui_calls=0; '
                'systemctl() { :; }; sleep() { :; }; dialog() { :; }; '
                'curl() { checks=$((checks + 1)); '
                '[[ "$*" == *https://geo.mirror.pkgbuild.com/core/os/x86_64/core.db* ]] && ((checks > 5)); }; '
                'nmtui() { nmtui_calls=$((nmtui_calls + 1)); }; '
                'prepare_network; test "$checks" -eq 6 && test "$nmtui_calls" -eq 1',
                "network-test", str(installer),
            ],
            capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_update_displays_output_and_preserves_pacman_status(self):
        installer = ROOT / "files" / "bin" / "cambonos-installer"
        for expected_status in (0, 42):
            with self.subTest(status=expected_status):
                result = subprocess.run(
                    [
                        "bash", "-c",
                        'source "$1"; simulated_status=$2; '
                        'dialog() { if [[ "$*" == *--programbox* ]]; then cat; fi; }; '
                        'pacman() { printf "pacman args: %s\\n" "$*"; printf "download progress\\n"; return "$simulated_status"; }; '
                        'show_error() { printf "ERROR: %s\\n" "$1"; }; '
                        'update_installer || result=$?; exit "${result:-0}"',
                        "update-test", str(installer), str(expected_status),
                    ],
                    capture_output=True, text=True,
                )
                self.assertEqual(result.returncode, expected_status, result.stderr)
                self.assertIn("pacman args: -Sy --noconfirm cambonos-installer", result.stdout)
                self.assertIn("download progress", result.stdout)
                self.assertEqual("ERROR:" in result.stdout, expected_status != 0)

    def test_update_failure_does_not_restart(self):
        installer = ROOT / "files" / "bin" / "cambonos-installer"
        result = subprocess.run(
            [
                "bash", "-c",
                'source "$1"; prepare_network() { :; }; update_installer() { return 42; }; '
                'exec() { printf "unexpected restart\\n"; exit 99; }; '
                'prepare_installer || exit "$?"',
                "failure-test", str(installer),
            ],
            capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 42, result.stderr)
        self.assertNotIn("unexpected restart", result.stdout)

    def test_update_reports_temporary_directory_failure(self):
        installer = ROOT / "files" / "bin" / "cambonos-installer"
        result = subprocess.run(
            [
                "bash", "-c",
                'source "$1"; mktemp() { return 1; }; '
                'show_error() { printf "ERROR: %s\\n" "$1"; }; '
                'pacman() { printf "unexpected pacman\\n"; }; '
                'update_installer || exit "$?"',
                "temporary-directory-test", str(installer),
            ],
            capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("directorio temporal", result.stdout)
        self.assertNotIn("unexpected pacman", result.stdout)

    def test_successful_update_restarts_once_and_clears_marker(self):
        installer = ROOT / "files" / "bin" / "cambonos-installer"
        with tempfile.TemporaryDirectory() as directory:
            replacement = Path(directory) / "replacement"
            replacement.write_text(
                '#!/bin/bash\n'
                'source "$INSTALLER_SOURCE"\n'
                'prepare_network() { exit 91; }\n'
                'update_installer() { exit 92; }\n'
                'prepare_installer "$@"\n'
                'printf "resumed:%s:%s\\n" "${CAMBONOS_INSTALLER_UPDATED-unset}" "$*"\n'
            )
            replacement.chmod(0o755)
            environment = os.environ.copy()
            environment.update(INSTALLER_SOURCE=str(installer), RESTART_TARGET=str(replacement))
            environment.pop("CAMBONOS_INSTALLER_UPDATED", None)
            result = subprocess.run(
                [
                    "bash", "-c",
                    'source "$INSTALLER_SOURCE"; '
                    'prepare_network() { printf "network\\n"; }; '
                    'update_installer() { printf "update\\n"; }; '
                    'exec() { printf "restart:%s\\n" "$1"; shift; builtin exec "$RESTART_TARGET" "$@"; }; '
                    'prepare_installer sample',
                ],
                env=environment, capture_output=True, text=True,
            )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.splitlines(), [
            "network", "update", "restart:/usr/bin/cambonos-installer", "resumed:unset:sample",
        ])

    def test_installation_flow_lives_in_the_single_entrypoint(self):
        installer = (ROOT / "files" / "bin" / "cambonos-installer").read_text()
        self.assertIn('readonly TITLE=" CambonOS Installer ${PACKAGE_VERSION} "', installer)
        self.assertIn('PACKAGE_VERSION=$(<"$VERSION_FILE")', installer)
        self.assertIn("collect_options()", installer)
        self.assertIn("create_partitions()", installer)
        self.assertIn("perform_installation()", installer)
        self.assertIn("configure_system()", installer)
        self.assertNotIn("installer/dialog.sh", installer)
        for path in ("dialog.sh", "parted.sh", "cambonos-install.sh"):
            self.assertFalse((ROOT / path).exists())

    def test_dialog_prompts_start_with_a_newline(self):
        installer = (ROOT / "files" / "bin" / "cambonos-installer").read_text()
        widgets = re.finditer(
            r"--(?:menu|inputbox|passwordbox|yesno|msgbox|infobox|programbox|gauge)\s+",
            installer,
        )
        count = 0
        for widget in widgets:
            count += 1
            with self.subTest(widget=widget.group().strip(), position=widget.start()):
                prompt = re.match(r"(['\"])(.*?)\1", installer[widget.end():])
                self.assertIsNotNone(prompt)
                self.assertTrue(prompt.group(2).startswith(r"\n"))
        self.assertGreater(count, 0)
        self.assertIn('confirmation="Equipo:', installer)
        self.assertIn('--yesno "\\n$confirmation"', installer)

    def test_progress_emits_gauge_messages_without_regressing(self):
        installer = ROOT / "files" / "bin" / "cambonos-installer"
        result = subprocess.run(
            [
                "bash",
                "-c",
                'source "$1"; exec 3>&1; '
                'progress 12 "Instalando paquetes"; '
                'progress 8 "Continua la instalacion"',
                "bash",
                str(installer),
            ],
            check=True,
            capture_output=True,
            text=True,
        )
        self.assertEqual(
            result.stdout.splitlines(),
            [
                "XXX",
                "12",
                "\\nInstalando paquetes",
                "XXX",
                "XXX",
                "12",
                "\\nContinua la instalacion",
                "XXX",
            ],
        )

    def test_uefi_boot_entry_parser_matches_cambonos_path_and_partition(self):
        installer = ROOT / "files" / "bin" / "cambonos-installer"
        result = subprocess.run(
            [
                "bash",
                "-c",
                'source "$1"; '
                'uefi_boot_entry_details "Boot0003* CambonOS HD(1,GPT,c5b92a8e-66b5-4175-89af-0a7ac23c31bd,0x800,0x200000)/File(\\EFI\\CambonOS\\grubx64.efi)"; '
                'uefi_boot_entry_details "Boot0004* CambonOS HD(1,GPT,c5b92a8e-4988-46fb-8d25-f07739faf453,0x800,0x200000)/File(\\EFI\\CambonOS\\grubx64.efi)"; '
                '! uefi_boot_entry_details "Boot0005* OtherOS HD(1,GPT,c5b92a8e-66b5-4175-89af-0a7ac23c31bd,0x800,0x200000)/File(\\EFI\\CambonOS\\grubx64.efi)"; '
                '! uefi_boot_entry_details "Boot0006* CambonOS HD(1,GPT,c5b92a8e-66b5-4175-89af-0a7ac23c31bd,0x800,0x200000)/File(\\EFI\\OtherOS\\grubx64.efi)"',
                "bash",
                str(installer),
            ],
            check=True,
            capture_output=True,
            text=True,
        )
        self.assertEqual(
            result.stdout.strip().splitlines(),
            [
                "0003 c5b92a8e-66b5-4175-89af-0a7ac23c31bd",
                "0004 c5b92a8e-4988-46fb-8d25-f07739faf453",
            ],
        )

    def test_uefi_boot_entry_replaces_stale_entry_and_verifies_new_partition(self):
        installer = ROOT / "files" / "bin" / "cambonos-installer"
        result = subprocess.run(
            [
                "bash",
                "-c",
                "source \"$1\"\n"
                "mount_point=$(mktemp -d)\n"
                "trap 'rm -rf \"$mount_point\"' EXIT\n"
                "mkdir -p \"$mount_point/boot/EFI/CambonOS\"\n"
                "touch \"$mount_point/boot/EFI/CambonOS/grubx64.efi\"\n"
                "EFI_PARTITION=/dev/sda1\nDISK=/dev/sda\n"
                "created=0\nexisting_valid=0\nactions=()\n"
                "backslash=$(printf '\\134')\n"
                "lsblk() { printf '1\\n'; }\n"
                "blkid() { printf 'c5b92a8e-66b5-4175-89af-0a7ac23c31bd\\n'; }\n"
                "run_chroot() {\n"
                "  if [[ \"$1 $2\" == 'efibootmgr -v' ]]; then\n"
                "    printf 'Boot0003* CambonOS HD(1,GPT,c5b92a8e-4988-46fb-8d25-f07739faf453,0x800,0x200000)/File(%sEFI%sCambonOS%sgrubx64.efi)\\n' \"$backslash\" \"$backslash\" \"$backslash\"\n"
                "    if ((created == 1 || existing_valid == 1)); then\n"
                "      printf 'Boot0004* CambonOS HD(1,GPT,c5b92a8e-66b5-4175-89af-0a7ac23c31bd,0x800,0x200000)/File(%sEFI%sCambonOS%sgrubx64.efi)\\n' \"$backslash\" \"$backslash\" \"$backslash\"\n"
                "    fi\n"
                "  elif [[ \"$2\" == '--bootnum' ]]; then\n"
                "    actions+=(\"delete:$3\")\n"
                "  elif [[ \"$2\" == '--create' ]]; then\n"
                "    actions+=(\"create:$4:$6\")\n"
                "    created=1\n"
                "  else\nreturn 1\nfi\n"
                "}\n"
                "ensure_uefi_boot_entry \"$mount_point\"\n"
                "[[ \"${actions[*]}\" == 'delete:0003 create:/dev/sda:1' ]]\n"
                "actions=()\ncreated=0\nexisting_valid=1\n"
                "ensure_uefi_boot_entry \"$mount_point\"\n"
                "[[ \"${actions[*]}\" == 'delete:0003' ]]\n",
                "bash",
                str(installer),
            ],
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")

    def test_account_name_normalization_and_password_requirements(self):
        installer = ROOT / "files" / "bin" / "cambonos-installer"
        result = subprocess.run(
            [
                "bash",
                "-c",
                'source "$1"; '
                'printf "%s\\n" "$(normalize_admin_user "Ana Maria Lopez")"; '
                'valid_admin_user "ana-maria-lopez"; '
                '! valid_admin_user "ana.lopez" || exit 1; '
                '! valid_admin_user "-ana" || exit 1; '
                '! valid_admin_user "abcdefghijklmnopqrstuvwxyz1234567" || exit 1; '
                'password_meets_requirements "Cambonos9!"; '
                '! password_meets_requirements "cambonos9!" || exit 1; '
                '! password_meets_requirements "Cambonos!" || exit 1; '
                '! password_meets_requirements "Cambonos9 " || exit 1; '
                '! password_meets_requirements "Cambonos9" || exit 1',
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

    def test_ci_notifies_packages_only_after_tests_pass(self):
        workflow = (ROOT / ".github" / "workflows" / "notify-packages.yml").read_text()
        self.assertIn("branches:\n      - dev\n      - main", workflow)
        test_step = workflow.index("python -m unittest discover -s tests -v")
        notify_step = workflow.index("Notify cambonos-packages")
        self.assertLess(test_step, notify_step)
        self.assertIn("secrets.CAMBONOS_PACKAGES_DISPATCH_TOKEN", workflow)
        self.assertIn("repos/CambonOS/cambonos-packages/dispatches", workflow)
        self.assertIn('event_type: "external-package-updated"', workflow)
        for field in ("repository", "branch", "commit"):
            with self.subTest(field=field):
                self.assertIn(f"{field}: ${field}", workflow)

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