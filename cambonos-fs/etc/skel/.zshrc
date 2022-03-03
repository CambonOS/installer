##Completado de ZSH
setopt autocd
setopt correct
autoload -U compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion::complete:*' gain-privileges 1

##Flechas para recorrer historial
[[ -n "${key[PageUp]}"   ]]  && bindkey  "${key[PageUp]}"    history-beginning-search-backward
[[ -n "${key[PageDown]}" ]]  && bindkey  "${key[PageDown]}"  history-beginning-search-forward

##Historial de ZSH
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000

##Alias
alias ls="ls --color=auto"
alias untar="tar -xvf"

##Variables
export EDITOR="nvim"

##Tema y plugins
source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-sudo/sudo.plugin.zsh

##Prompt ZSH
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

##Comandos a ejecutar al abrir un ZSH
neofetch
