# =========================
# Environment
# =========================
export TERM=xterm-256color
[ -f ~/.aliases ] && source ~/.aliases
export KITTY_SHELL_INTEGRATION="no-cursor"


# ==============================================================
# Environment
# ==============================================================

export PATH="$HOME/.npm-global/bin:$PATH"

# Cache directories (safe if already exist)
mkdir -p ~/.zsh/cache ~/.cache

# =========================
# Zsh Options
# =========================

setopt autocd interactivecomments promptsubst
setopt hist_ignore_dups hist_ignore_space hist_expire_dups_first
setopt append_history inc_append_history
unsetopt share_history          # avoid corruption
setopt auto_pushd

WORDCHARS=${WORDCHARS//\/}
export PROMPT_EOL_MARK=""


# =========================
# Keybindings
# =========================
bindkey -e
bindkey ' ' magic-space
bindkey '^[[3;5~' kill-word
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[5~' beginning-of-buffer-or-history
bindkey '^[[6~' end-of-buffer-or-history
bindkey '^[[Z' undo


# ==============================================================
# Completion System
# ==============================================================

zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' rehash true

fpath+=(/usr/share/zsh/vendor-completions)
autoload -Uz compinit
compinit -d ~/.cache/zcompdump   # security ON


# =========================
# History
# =========================
HISTFILE=~/.zsh_history
HISTSIZE=5000
SAVEHIST=5000
alias history="history 0"

# =========================
# Aliases
# =========================
alias ls='eza --icons'
alias ll='eza -l --icons'
alias lt='eza --tree --icons'

unalias la 2>/dev/null
la() {
    eza -la --icons=always --group-directories-first "$@"
}

alias clear='printf "\033c"'

# =========================
# Clear Screen Widget
# =========================
zle_clear_screen() {
  printf "\033c"
  zle reset-prompt
}
zle -N clear-screen zle_clear_screen

# =========================
# Nerd Font Prompt (green symbols/brackets, blue letters/icons)
# =========================
setopt promptsubst

prompt_dir() {
    if [[ "$PWD" == "$HOME" ]]; then
        echo ""        # Home icon blue in prompt below
    else
        echo " ${PWD##*/}" # Folder icon blue
    fi
}

PROMPT=$'%F{green}┌─[%B%F{blue}%n%m%b%F{green}]-[%F{blue}$(prompt_dir)%F{green}]%f
%F{green}└─%F{yellow}>>>> %f'

RPROMPT=$'%(?.. %F{red}%? ⨯%f)'

# =========================
# Zsh Plugins
# =========================
if [ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#888'
fi

if [ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# =========================
# Last Directory Tracking
# =========================
LASTDIR_FILE="$HOME/.last_dir"
if [[ -f "$LASTDIR_FILE" ]]; then
    cd "$(cat "$LASTDIR_FILE")" || true
fi
precmd() { pwd >| "$LASTDIR_FILE" }

# =========================
# TMUX Ephemeral Sessions
# Each terminal gets fresh session, auto-killed on close
# =========================
if [[ -o interactive ]] && command -v tmux &>/dev/null && [ -z "$TMUX" ]; then
    SESSION="term_$RANDOM"
    tmux new-session -d -s "$SESSION"
    tmux attach-session -t "$SESSION"
fi

#==============================================================
# Directory Icons (longest match wins)
# ==============================================================

typeset -A DIR_ICONS=(
  "$HOME/Documents" "\uF0F6"
  "$HOME/Music"     "\uF001"
  "$HOME/Videos"   "\uF03D"
  "$HOME/nvim"     "\uE7C5"
  "$HOME"          "\uF015"
)

get_dir_icon() {
  local key
  for key in ${(oL)${(k)DIR_ICONS}}; do
    [[ $PWD == $key* ]] && { print -n ${DIR_ICONS[$key]}; return; }
  done
  print -n "\uF07C"
}
