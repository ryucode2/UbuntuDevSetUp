#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Cross-Distro Linux Dev Setup (Zsh + Tmux + Neovim + GNOME Theming)
###############################################################################

os_type="$(uname -s)"
config_dir="${HOME}/.config/UbuntuDevSetUp"
log_file="${HOME}/UbuntuDevSetup.log"

# Core packages
base_packages="curl git python3 python3-pip cmake ripgrep tmux zsh \
ninja-build gettext libtool autoconf automake g++ pkg-config unzip \
doxygen gpg gawk tree eza fontconfig build-essential"

# Optional packages
optional_packages="htop npm rsync fonts-firacode wget curl git dconf-cli unzip"

###############################################################################
# Helpers
###############################################################################
function log() {
  echo -e "$1" | tee -a "$log_file"
}

function require_non_root() {
  if [ "$(id -u)" -eq 0 ]; then
    log "❌ Do not run this script as root. Use a normal user with sudo."
    exit 1
  fi
}

function detect_package_manager() {
  if command -v apt-get &>/dev/null; then
    PKG="apt-get"
    INSTALL="sudo apt-get install -y"
    UPDATE="sudo apt-get update"
  elif command -v dnf &>/dev/null; then
    PKG="dnf"
    INSTALL="sudo dnf install -y"
    UPDATE="sudo dnf check-update || true"
  elif command -v pacman &>/dev/null; then
    PKG="pacman"
    INSTALL="sudo pacman -S --noconfirm --needed"
    UPDATE="sudo pacman -Sy"
  else
    log "❌ No supported package manager found (apt, dnf, pacman)."
    exit 1
  fi
  log "✅ Using package manager: $PKG"
}

function install_packages() {
  log "📦 Installing required system packages..."
  $UPDATE
  $INSTALL $base_packages $optional_packages
}

function safe_symlink() {
  local src=$1
  local dest=$2
  if [ -f "$dest" ] && [ ! -L "$dest" ]; then
    log "⚠️  Skipping $dest (real file exists)"
  else
    ln -sfn "$src" "$dest"
    log "✅ Linked $dest → $src"
  fi
}

###############################################################################
# Fonts
###############################################################################
function install_nerd_font() {
  log "📦 Installing FiraCode Nerd Font..."
  mkdir -p ~/.local/share/fonts
  cd ~/.local/share/fonts
  if [ ! -f "FiraCodeNerdFontMono-Regular.ttf" ]; then
    curl -fLo "FiraCode.zip" https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip
    unzip -o FiraCode.zip -d FiraCode
    mv FiraCode/*.ttf .
    rm -rf FiraCode FiraCode.zip
    fc-cache -fv
    log "✅ FiraCode Nerd Font installed."
  else
    log "✅ FiraCode Nerd Font already installed."
  fi
}

###############################################################################
# GNOME Terminal Theme
###############################################################################
function set_gnome_terminal_theme() {
  if ! command -v gsettings &>/dev/null; then
    log "⚠️ gsettings not found — skipping GNOME Terminal theme."
    return
  fi

  log "🎨 Installing GNOME Terminal theme (TokyoNight) with transparency..."

  # Ensure dependencies
  if [ "$PKG" = "apt-get" ]; then
    sudo apt-get install -y dconf-cli wget curl git
  elif [ "$PKG" = "dnf" ]; then
    sudo dnf install -y dconf wget curl git
  elif [ "$PKG" = "pacman" ]; then
    sudo pacman -S --noconfirm dconf wget curl git
  fi

  # Export terminal type so Gogh doesn’t complain
  export TERMINAL=gnome-terminal

  # Run Gogh installer (TokyoNight preset)
  bash -c "$(wget -qO- https://git.io/vQgMr)" || {
    log "❌ Gogh installer failed!"
    return
  }

  # Apply transparency (15%)
  PROFILE=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d \')
  if [ -n "$PROFILE" ]; then
    log "⚡ Applying transparency..."
    dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE/use-transparent-background true
    dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE/background-transparency-percent 15
    log "✅ GNOME Terminal set to TokyoNight theme with 15% transparency"
  else
    log "⚠️ Could not detect GNOME Terminal profile. Please set transparency manually."
  fi
}

###############################################################################
# GNOME Extensions
###############################################################################
function install_gnome_extensions() {
  if ! command -v gnome-shell &>/dev/null; then
    log "⚠️ GNOME Shell not detected — skipping extensions."
    return
  fi

  log "✨ Installing GNOME Extensions for transparency (Blur & Transparent Window)..."

  if [ "$PKG" = "apt-get" ]; then
    sudo apt-get install -y gnome-shell-extensions gnome-shell-extension-prefs \
      gnome-shell-extension-manager unzip
  elif [ "$PKG" = "dnf" ]; then
    sudo dnf install -y gnome-extensions-app gnome-shell-extension-appindicator unzip
  elif [ "$PKG" = "pacman" ]; then
    sudo pacman -S --noconfirm gnome-shell-extensions gnome-shell-extension-manager unzip
  fi

  EXT_DIR="${HOME}/.local/share/gnome-shell/extensions"
  mkdir -p "$EXT_DIR"

  # Transparent Window
  if [ ! -d "$EXT_DIR/transparent-window@linuxdeepin.com" ]; then
    log "📦 Installing Transparent Window extension..."
    wget -qO /tmp/transparent-window.zip \
      https://extensions.gnome.org/extension-data/transparent-windowlinuxdeepin.com.v9.shell-extension.zip
    unzip -o /tmp/transparent-window.zip -d "$EXT_DIR/transparent-window@linuxdeepin.com"
    rm -f /tmp/transparent-window.zip
  fi

  # Blur My Shell
  if [ ! -d "$EXT_DIR/blur-my-shell@aunetx" ]; then
    log "📦 Installing Blur My Shell extension..."
    wget -qO /tmp/blur-my-shell.zip \
      https://extensions.gnome.org/extension-data/blur-my-shell@aunetx.v43.shell-extension.zip
    unzip -o /tmp/blur-my-shell.zip -d "$EXT_DIR/blur-my-shell@aunetx"
    rm -f /tmp/blur-my-shell.zip
  fi

  gnome-extensions enable transparent-window@linuxdeepin.com || true
  gnome-extensions enable blur-my-shell@aunetx || true

  log "✅ GNOME Extensions installed and enabled: Transparent Window + Blur My Shell"
  log "👉 Restart GNOME Shell (Alt+F2 → r) or reboot to apply."
}

###############################################################################
# Zsh default shell
###############################################################################
function set_default_shell_to_zsh() {
  ZSH_PATH="$(command -v zsh || true)"
  if [ -z "$ZSH_PATH" ]; then
    log "❌ Zsh not found. Installing..."
    $INSTALL zsh
    ZSH_PATH="$(command -v zsh)"
  fi

  log "👉 Setting Zsh as the default shell..."
  if chsh -s "$ZSH_PATH" "$(whoami)" 2>/dev/null; then
    log "✅ Default shell changed with chsh."
  elif sudo usermod --shell "$ZSH_PATH" "$(whoami)" 2>/dev/null; then
    log "✅ Default shell changed with usermod."
  else
    log "❌ Failed to change default shell."
  fi
}

###############################################################################
# Main Setup
###############################################################################
require_non_root
detect_package_manager
install_packages

# Clone repo
if [ ! -d "${config_dir}" ]; then
  git clone https://github.com/ryucode2/UbuntuDevSetUp.git "${config_dir}"
else
  log "🔄 Updating repo..."
  git -C "${config_dir}" pull --ff-only
fi

# Normalize dirs
for d in Zsh zsh Tmux tmux Nvim nvim; do
  if [ -d "${config_dir}/${d}" ]; then
    lower=$(echo "$d" | tr '[:upper:]' '[:lower:]')
    [ "$d" != "$lower" ] && mv "${config_dir}/${d}" "${config_dir}/${lower}"
  fi
done

# Configs
mkdir -p "${config_dir}/zsh" "${config_dir}/tmux"
[ ! -f "${config_dir}/zsh/.zshrc" ] && echo "# Default .zshrc" > "${config_dir}/zsh/.zshrc"
[ ! -f "${config_dir}/tmux/.tmux.conf" ] && echo "# Default .tmux.conf" > "${config_dir}/tmux/.tmux.conf"

safe_symlink "${config_dir}/zsh/.zshrc" "${HOME}/.zshrc"
safe_symlink "${config_dir}/tmux/.tmux.conf" "${HOME}/.tmux.conf"

# Tmux plugin manager
if [ ! -d "${HOME}/.tmux/plugins/tpm" ]; then
  git clone https://github.com/tmux-plugins/tpm "${HOME}/.tmux/plugins/tpm"
  log "✅ TPM installed."
else
  log "✅ TPM already installed."
fi

# Neovim
if ! command -v nvim &>/dev/null; then
  log "📦 Installing Neovim from source..."
  git clone https://github.com/neovim/neovim
  cd neovim && make CMAKE_BUILD_TYPE=Release && sudo make install
  cd .. && rm -rf neovim
else
  log "✅ Neovim already installed: $(nvim --version | head -n 1)"
fi

NVIM_CONFIG="${HOME}/.config/nvim"
if [ ! -d "$NVIM_CONFIG" ] || [ -z "$(ls -A "$NVIM_CONFIG")" ]; then
  log "📦 Installing LazyVim config..."
  rm -rf "$NVIM_CONFIG"
  git clone https://github.com/LazyVim/starter "$NVIM_CONFIG"
  rm -rf "$NVIM_CONFIG/.git"
else
  log "✅ Neovim config already exists."
fi
[ -f "${HOME}/.config/nvim/init.vim" ] && rm -f "${HOME}/.config/nvim/init.vim"

log "⚡ Bootstrapping LazyVim plugins..."
nvim --headless "+Lazy! sync" +qa || true

# Fonts + GNOME theming + shell
install_nerd_font
set_gnome_terminal_theme
install_gnome_extensions
set_default_shell_to_zsh

###############################################################################
# Finish
###############################################################################
log ""
log "⚡ Setup Complete!"
log "👉 Neovim ready with LazyVim"
log "👉 TPM installed for Tmux"
log "👉 Default shell: $(getent passwd $(whoami) | cut -d: -f7)"
log "👉 Log file: $log_file"
log ""

read -rp "🔄 Reboot now to apply changes? (y/n) " yn
if [[ "$yn" =~ [Yy] ]]; then
  sudo reboot
else
  log "⚡ Reboot later to finalize setup."
fi
