#!/usr/bin/env bash
set -e

###############################################################################
# Ubuntu Dev Setup Installer
# - Installs dev tools (Zsh, Tmux, Neovim, etc.)
# - Installs Nerd Fonts and configures GNOME Terminal to use them
# - Symlinks configs from your UbuntuDevSetUp repo
# - Switches default shell to Zsh
###############################################################################

skip_system_packages="${1}"
os_type="$(uname -s)"
config_dir="${HOME}/.config/UbuntuDevSetUp"

# Core system packages
apt_packages="curl git iproute2 python3 python3-pip cmake ripgrep tmux zsh \
ninja-build gettext libtool libtool-bin autoconf automake g++ pkg-config unzip \
doxygen gpg gawk tree eza zsh-autosuggestions zsh-syntax-highlighting fontconfig"

# Optional packages
apt_packages_optional="gnupg htop npm rsync"

###############################################################################
# Helpers
###############################################################################
function no_system_packages() {
  echo "This script will ONLY install Neovim, Tmux if system packages are skipped."
  exit 1
}

function apt_install_packages {
  sudo apt-get update && sudo apt-get install -y ${apt_packages} ${apt_packages_optional}
}

function install_nerd_font() {
  echo "📦 Installing FiraCode Nerd Font..."
  mkdir -p ~/.local/share/fonts
  curl -L -o /tmp/FiraCode.zip \
    "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"
  unzip -o /tmp/FiraCode.zip -d ~/.local/share/fonts >/dev/null 2>&1
  fc-cache -fv
  echo "✅ FiraCode Nerd Font installed"
}

function set_gnome_terminal_font() {
  if command -v gsettings &>/dev/null; then
    profile=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d \')
    if [ -n "$profile" ]; then
      dconf write /org/gnome/terminal/legacy/profiles:/:$profile/use-system-font false
      dconf write /org/gnome/terminal/legacy/profiles:/:$profile/font "'FiraCode Nerd Font Mono 12'"
      echo "✅ GNOME Terminal font set to 'FiraCode Nerd Font Mono 12'"
    else
      echo "⚠️ Could not detect GNOME Terminal profile. Please set the font manually."
    fi
  else
    echo "⚠️ gsettings not found — skipping GNOME Terminal font configuration."
  fi
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
# Install system packages
###############################################################################
if [ -z "${skip_system_packages}" ]; then
  echo "The following system packages will be installed:"
  echo "${apt_packages} ${apt_packages_optional}"
  read -rp "Proceed? (y/n) " yn
  [[ "$yn" =~ [Yy] ]] && apt_install_packages || exit 0
else
  echo "Skipping system package installation."
fi

###############################################################################
# Nerd Fonts install + apply to terminal
###############################################################################
install_nerd_font
set_gnome_terminal_font

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
    [ "$d" != "$lower" ] && mv "${config_dir}/${d}" "${config_dir}/${lower}"
  fi
done

###############################################################################
# Zsh config (symlink only, no overwrites)
###############################################################################
mkdir -p "${config_dir}/zsh"
[ ! -f "${config_dir}/zsh/.zshrc" ] && echo "# Default .zshrc" >"${config_dir}/zsh/.zshrc"
ln -fs "${config_dir}/zsh/.zshrc" "${HOME}/.zshrc"

###############################################################################
# Tmux config
###############################################################################
mkdir -p "${config_dir}/tmux"
[ ! -f "${config_dir}/tmux/.tmux.conf" ] && echo "# Default .tmux.conf" >"${config_dir}/tmux/.tmux.conf"
ln -fs "${config_dir}/tmux/.tmux.conf" "${HOME}/.tmux.conf"

###############################################################################
# Neovim config
###############################################################################
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
# Switch default shell to Zsh
###############################################################################
if [ "$SHELL" != "$(which zsh)" ]; then
  echo "🔄 Switching default shell to Zsh..."
  chsh -s "$(which zsh)"
  echo "✅ Default shell changed to Zsh. Restart terminal or log out/in to apply."
fi

###############################################################################
# Final message
###############################################################################
echo
echo "⚡ Setup Complete!"
echo "👉 Your terminal font has been set to 'FiraCode Nerd Font Mono 12'."
echo "👉 Your default shell is now Zsh."
echo "👉 Restart your terminal to see icons working properly."
echo
