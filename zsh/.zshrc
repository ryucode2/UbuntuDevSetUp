# ~/.zshrc for system-wide plugins (Debian/Ubuntu apt)

export TERM=xterm-256color
[ -f ~/.aliases ] && source ~/.aliases

# Options
setopt autocd interactivecomments promptsubst
setopt hist_ignore_dups hist_ignore_space hist_expire_dups_first

WORDCHARS=${WORDCHARS//\/}
export PROMPT_EOL_MARK=""

# Keybindings
bindkey -e
bindkey ' ' magic-space
bindkey '^[[3;5~' kill-word
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[5~' beginning-of-buffer-or-history
bindkey '^[[6~' end-of-buffer-or-history
bindkey '^[[Z' undo

# Completion
fpath+=(/usr/share/zsh/vendor-completions)
autoload -Uz compinit
compinit -u -d ~/.cache/zcompdump
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# History
HISTFILE=~/.zsh_history
HISTSIZE=5000
SAVEHIST=5000
alias history="history 0"

# Prompt
PROMPT=$'%F{green}┌─[%B%F{blue}%n%m%b%F{green}]-[%~]%f
%F{green}└─%F{yellow}>>>> %f'
RPROMPT=$'%(?.. %? %F{red}%B⨯%b%F{reset})%(1j. %j %F{yellow}%B⚙%b%F{reset}.)'

# Plugins (system-wide from /usr/share)
if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  . /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#888'
fi

if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  . /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Aliases
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias ls='eza --icons --group-directories-first'

# Clear screen with reset prompt
alias clear='printf "\033c"'
zle_clear_screen() {
  printf "\033c"
  zle reset-prompt
}
zle -N clear-screen zle_clear_screen
