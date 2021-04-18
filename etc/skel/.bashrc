BLUE='\033[1;34m'
GREEN='\033[1;32m'
WHITE='\033[0m'
PS1='${GREEN}\u@\h${WHITE}:${BLUE}\w/${WHITE}\$ '

#Alias
alias cambonos-install="trizen -S"
alias cambonos-remove="trizen -Rns"
alias cambonos-clone="rm-rf Arch-Distro && git clone https://github.com/CambonOS/Arch-Distro.git"
alias cambonos-push="git add * && EDITOR=nvim git commit -a && git push"

neofetch
