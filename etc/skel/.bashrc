gsettings set org.gnome.desktop.wm.preferences button-layout :minimize,maximize,close
gsettings set org.gnome.desktop.background picture-uri file:///usr/share/backgrounds/cambonos.jpg

echo '
PS1="\u@\h:\w\$ "
neofetch' >/home/$USER/.bashrc
