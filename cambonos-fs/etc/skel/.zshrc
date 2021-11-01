autoload -U compinit promptinit
compinit
promptinit
zstyle ':completion:*' menu select
[[ -n "${key[PageUp]}"   ]]  && bindkey  "${key[PageUp]}"    history-beginning-search-backward
[[ -n "${key[PageDown]}" ]]  && bindkey  "${key[PageDown]}"  history-beginning-search-forward
prompt oliver
