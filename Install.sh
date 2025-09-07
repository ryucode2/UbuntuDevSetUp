#!/usr/bin/env bash
set -e

###############################################################################
# Ubuntu Dev Setup Installer (with zsh plugins + prompt fixes)
###############################################################################

skip_system_packages="${1}"
os_type="$(uname -s)"
config_dir="${HOME}/.config/UbuntuDevSetUp"

# Core system packages (added zsh-autosuggestions + zsh-syntax-highlighting)
apt_packages="curl git iproute2 python3 python3-pip cmake ripgrep tmux zsh \
ninja-build gettext libtool libtool-bin autoconf automake g++ pkg-config unzip \
doxygen gpg gawk tree eza zsh-autosuggestions zsh-syntax-highlighting"

# Optional system packages
apt_packages_optional="gnupg htop npm rsync fonts-firacode"

###############################################################################
# Helpers
###############################################################################
function no_system_packages() {
  cat <<EOF
This script will ONLY install Neovim, Zsh, Tmux if system packages are skipped.
EOF
  exit 1
}

function apt_install_packages {
  sudo apt-get update && sudo apt-get install -y ${apt_packages} ${apt_packages_optional}
}

###############################################################################
# OS Detection
###############################################################################
case "${os_type}" in
Linux*)
  os_type="Linux"
  if [ ! -f "/etc/debian_version" ]; then
    [ -z "${skip_system_packages}" ] && no_system_packages
  fi
  ;;
Darwin*) os_type="macOS" ;;
*)
  os_type="Other"
  [ -z "${skip_system_packages}" ] && no_system_packages
  ;;
esac

###############################################################################
# Ensure Zsh installed
###############################################################################
if ! command -v zsh &>/dev/null; then
  echo "⚠️ Zsh not found. Installing..."
  if [ "${os_type}" == "Linux" ]; then
    sudo apt-get update && sudo apt-get install -y zsh
  elif [ "${os_type}" == "macOS" ] && command -v brew &>/dev/null; then
    brew install zsh
  else
    echo "❌ Could not install zsh. Install manually."
    exit 1
  fi
else
  echo "✅ Zsh already installed: $(command -v zsh)"
fi

###############################################################################
# Install system packages
###############################################################################
if [ -z "${skip_system_packages}" ]; then
  echo "The following system packages will be installed:"
  echo "${apt_packages} ${apt_packages_optional}"
  while true; do
    read -rp "Proceed? (y/n) " yn
    case "${yn}" in
    [Yy]*)
      apt_install_packages
      break
      ;;
    [Nn]*) exit 0 ;;
    *) echo "Please answer y or n" ;;
    esac
  done
else
  echo "Skipping system package installation."
fi

###############################################################################
# Clone or update UbuntuDevSetUp repo
###############################################################################
if [ ! -d "${config_dir}" ]; then
  git clone https://github.com/ryucode2/UbuntuDevSetUp.git "${config_dir}"
else
  echo "Updating repo: ${config_dir}"
  git -C "${config_dir}" pull --ff-only
fi

###############################################################################
# Normalize repo dirs
###############################################################################
for d in Zsh zsh Tmux tmux Nvim nvim; do
  if [ -d "${config_dir}/${d}" ]; then
    lower=$(echo "$d" | tr '[:upper:]' '[:lower:]')
    if [ "$d" != "$lower" ]; then
      mv "${config_dir}/${d}" "${config_dir}/${lower}"
    fi
  fi
done

###############################################################################
# Ensure configs exist & symlink
###############################################################################
mkdir -p "${config_dir}/zsh"

# Default .zshrc
cat >"${config_dir}/zsh/.zshrc" <<'EOF'
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
PROMPT=$'%F{green}──(%n㉿%m)-[%~]\n└─>>>> %f'
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
EOF

[ ! -f "${config_dir}/zsh/.aliases" ] && echo "# Default .aliases" >"${config_dir}/zsh/.aliases"

ln -fs "${config_dir}/zsh/.zshrc" "${HOME}/.zshrc"
ln -fs "${config_dir}/zsh/.aliases" "${HOME}/.aliases"

# Tmux
mkdir -p "${config_dir}/tmux"
[ ! -f "${config_dir}/tmux/.tmux.conf" ] && echo "# Default .tmux.conf" >"${config_dir}/tmux/.tmux.conf"
ln -fs "${config_dir}/tmux/.tmux.conf" "${HOME}/.tmux.conf"

# Neovim
mkdir -p "${config_dir}/nvim"
ln -fs "${config_dir}/nvim" "${HOME}/.config/nvim"

###############################################################################
# Install NVIM from source (if missing)
###############################################################################
if ! command -v nvim &>/dev/null; then
  git clone https://github.com/neovim/neovim
  cd neovim && make && sudo make install
  cd .. && rm -rf neovim
else
  echo "✅ Neovim already installed: $(nvim --version | head -n 1)"
fi

###############################################################################
# LazyVim config
###############################################################################
rm -rf "${HOME}/.config/nvim"
git clone https://github.com/LazyVim/starter "${HOME}/.config/nvim"

###############################################################################
# Tmux plugin manager
###############################################################################
rm -rf "${HOME}/.tmux/plugins/tpm"
git clone --depth 1 https://github.com/tmux-plugins/tpm "${HOME}/.tmux/plugins/tpm"
"${HOME}/.tmux/plugins/tpm/bin/install_plugins" || true

###############################################################################
# fzf
###############################################################################
rm -rf "${HOME}/.local/share/fzf"
git clone --depth 1 https://github.com/junegunn/fzf.git "${HOME}/.local/share/fzf"
yes | "${HOME}/.local/share/fzf/install" --bin --no-update-rc

###############################################################################
# Set zsh as default shell
###############################################################################
if [ "${SHELL}" != "$(command -v zsh)" ]; then
  chsh -s "$(command -v zsh)" || echo "⚠️ Could not change shell automatically."
fi

###############################################################################
# Reboot Countdown
###############################################################################
echo -e "\n⚡ System will reboot in 30 seconds to apply changes..."
echo "   Press CTRL+C to cancel."
for i in {15..1}; do
  echo -ne "   Rebooting in $i seconds...\r"
  sleep 1
done

sudo reboot

###############################################################################
# Done (only shown if user cancels reboot with CTRL+C)
###############################################################################
echo -e "\n✅ Setup complete! Please restart your terminal or run: exec zsh"
