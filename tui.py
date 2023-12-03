"""
Este código es parte del repositorio de GitHub
    https://github.com/cambonos/installer
Distribuido bajo licencia GPL-3.0
    https://www.gnu.org/licenses/gpl-3.0.html

Programa en python que utiliza el comando dialog mediante la libreria manucr19_py_lib,
para desarrollar la tui que ofrece el instalador.
"""
# Importaciones de módulos
import sys
import re
from subprocess import run
from manucr19_py_lib import tui

# Definición de funciones
def parted_dialog():
    """Dialogo que incluye todo el proceso relacionado con la particion del disco"""
    title = "CambonOS Installer"
    option = tui.menu(
        title,
        "Para comenzar la instalacion escoga una opcion:",
        [
            ("1.", "Borrando todo el disco"),
            ("2.", "Espacio libre al final del disco"),
            ("3.", "Salir del instalador")
        ]
    )
    if option == "1.":
        if tui.yesno(title, "Se eliminaran todos los datos del disco.\n\n¿Desea continuar?"):
            parted_type = "full"
        else:
            return parted_dialog()
    elif option == "2.":
        parted_type = "end-space"
    elif option == "3.":
        run("clear", check=False)
        sys.exit()
    comando = "lsblk -o NAME,MODEL,SIZE -d"
    salida = run(comando.split(), capture_output = True, check=False)
    txt = salida.stdout.decode()
    disco = tui.inputbox(title, txt, init = "/dev/sda")
    return parted_type, disco

def is_secure_password(password):
    """Comprueba la seguridad de la contraseña que acepta como parametro"""
    has_uppercase = bool(re.search(r"[A-Z]", password))
    has_lowercase = bool(re.search(r"[a-z]", password))
    has_number = bool(re.search(r"[0-9]", password))
    has_special = bool(re.search(r"[!@#\$%\^&\*\-\+\=\.]", password))
    if has_uppercase and has_lowercase and has_number and has_special and len(password) >= 12:
        return True
    return False

def passwd_dialog():
    """Conjunto de input para introducir contraseña dos veces y validar que coindide"""
    title = "CambonOS Installer"
    input1 = tui.inputbox(title, "Contraseña del usuario:")
    input2 = tui.inputbox(title, "Repetir contraseña:")
    if input1 != input2:
        tui.infobox(title,"Las contraseñas introducidas no coinciden.")
        return passwd_dialog()
    if is_secure_password(input1) is False:
        tui.infobox(title, "La contraseña introducida no es segura, prueba de nuevo.")
        return passwd_dialog()
    return input1

def escritorio_dialog():
    """Menu de seleccion de escritorios"""
    title = "CambonOS Installer"
    option = tui.menu(
        title,
        "Selecciona una de las siguientes opciones de escritorio:",
        [
            ("1.", "Cambon18/XFCE (Recomendado)"),
            ("2.", "Cambon18/Qtile"),
            ("3.", "No instalar interfaz gráfica")
        ]
    )
    return option

def user_dialog(add):
    """Dialogo para obtener nombre de usuario y contraseña"""
    title = "CambonOS Installer"
    text = "Nombre del usuario "+str(add)+":"
    user = tui.inputbox(title, text)
    password = passwd_dialog()
    return user, password

def main():
    """Ejecucion principal de la tui"""
    title = "CambonOS Intaller"
    # Pantalla bienvenida
    tui.msgbox(title, "Bienvenido al intalador de CambonOS\n\nGracias por elegirnos :)")
    # Particionado disco
    parted_type, disco = parted_dialog()
    run(["sh", "./parted.sh", disco, parted_type], check=False)
    # Nombre del equipo
    hostname = tui.inputbox(title, "Nombre del equipo:")
    hostname = hostname.lower()
    # Usuarios
    admin_user, admin_pass = user_dialog("administrador")
    username, user_pass = user_dialog("sin privilegios")
    # Drivers graficos
    drivers_gx = tui.yesno(title, "Desea instalar los drivers gráficos?")
    # Servidor ssh
    ssh = tui.yesno(title, "Desea instalar servidor SSH?")
    # Seleccionar auto actualizaciones
    upgrade = tui.yesno(title, "Desea que los paquetes del sistema se actualicen automáticamente?")
    # Seleccionar escritorios
    escritorio = escritorio_dialog()
    # Lanzar el installer con los parametros
    cmd = [
        "sh"
        "./cambonos-install.sh",
        hostname,
        admin_user,
        admin_pass,
        username,
        user_pass,
        str(drivers_gx),
        str(ssh),
        str(upgrade),
        escritorio,
        disco,
        "&"
    ]
    run(cmd, check=False)

# Ejecución del programa
if __name__ == "__main__":
    main()
