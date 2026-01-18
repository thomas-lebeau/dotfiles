[ -r ~/.bash_profile ] && source ~/.bash_profile

alias reload='. ~/.zshrc'

# prompt (pure)
BREW_PREFIX="$(brew --prefix)"
fpath+=("${BREW_PREFIX}/share/zsh/site-functions")
autoload -Uz compinit; compinit
autoload -U promptinit; promptinit
prompt pure


source "${BREW_PREFIX}/share/zsh-you-should-use/you-should-use.plugin.zsh"
source "${BREW_PREFIX}/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh"


if type brew &>/dev/null; then
  FPATH="${BREW_PREFIX}/share/zsh-completions:$FPATH"

  autoload -Uz compinit
  compinit
fi

zstyle ':autocomplete:*' ignored-input '*'
zstyle ':autocomplete:*' widget-style menu-select

bindkey '\t' menu-select "$terminfo[kcbt]" menu-select
bindkey -M menuselect '\t' menu-complete "$terminfo[kcbt]" reverse-menu-complete
bindkey -M menuselect '^[' undo

export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#8d949e"
source "${BREW_PREFIX}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "${BREW_PREFIX}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
