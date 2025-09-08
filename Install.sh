#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Ubuntu Dev Setup Installer (Stable Version)
###############################################################################

CONFIG_DIR="$HOME/.config/UbuntuDevSetUp"
NVIM_CONFIG="$HOME/.config/nvim"

APT_PACKAGES="curl git iproute2 python3 python3-pip cmake ripgrep tmux zsh \
ninja-build gettext libtool libtool-bin autoconf automake g++ pkg-config unzip \
doxygen gpg gawk tree eza zsh-autosuggestions zsh-syntax-highlighting fontconfig"

APT_OPTIONAL="gnupg htop npm rsync fonts-firacode"

###############################################################################
# Functions
###############################################################################
install_packages() {
  echo "📦 Installing system packages..."
  sudo apt-get update -qq
  sudo apt-get install -y $APT_PACKAGES $APT_OPTIONAL
}

clone_or_update_repo() {
  if [ ! -d "$CONFIG_DIR" ]; then
    git clone https://github.com/ryucode2/UbuntuDevSetUp.git "$CONFIG_DIR"
  else
    git -C "$CONFIG_DIR" pull --ff-only
  fi
}

setup_configs() {
  echo "⚙️ Linking configs..."
  mkdir -p "$CONFIG_DIR/zsh" "$CONFIG_DIR/tmux"

  [ ! -f "$CONFIG_DIR/zsh/.zshrc" ] && echo "# Default .zshrc" > "$CONFIG_DIR/zsh/.zshrc"
  [ ! -f "$CONFIG_DIR/tmux/.tmux.conf" ] && echo "# Default .tmux.conf" > "$CONFIG_DIR/tmux/.tmux.conf"

  ln -fs "$CONFIG_DIR/zsh/.zshrc" "$HOME/.zshrc"
  ln -fs "$CONFIG_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
}

install_neovim() {
  if ! command -v nvim &>/dev/null; then
    echo "📦 Installing Neovim..."
    git clone https://github.com/neovim/neovim
    cd neovim && make CMAKE_BUILD_TYPE=Release && sudo make install
    cd .. && rm -rf neovim
  else
    echo "✅ Neovim already installed: $(nvim --version | head -n 1)"
  fi
}

setup_lazyvim() {
  echo "⚡ Setting up LazyVim..."
  if [ ! -d "$NVIM_CONFIG" ] || [ -z "$(ls -A "$NVIM_CONFIG")" ]; then
    rm -rf "$NVIM_CONFIG"
    git clone https://github.com/LazyVim/starter "$NVIM_CONFIG"
    rm -rf "$NVIM_CONFIG/.git"
  fi
  rm -f "$HOME/.config/nvim/init.vim"
  nvim --headless "+Lazy! sync" +qa || true
}

install_nerd_font() {
  echo "🔤 Installing FiraCode Nerd Font..."
  mkdir -p ~/.local/share/fonts && cd ~/.local/share/fonts
  if [ ! -f "FiraCodeNerdFontMono-Regular.ttf" ]; then
    curl -fLo FiraCode.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip
    unzip -qo FiraCode.zip -d FiraCode && mv FiraCode/*.ttf . && rm -rf FiraCode FiraCode.zip
    fc-cache -fv
  fi
}

set_gnome_terminal_font() {
  if command -v gsettings &>/dev/null; then
    profile=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d \')
    if [ -n "$profile" ]; then
      dconf write /org/gnome/terminal/legacy/profiles:/:$profile/use-system-font false
      dconf write /org/gnome/terminal/legacy/profiles:/:$profile/font "'FiraCode Nerd Font Mono 12'"
    fi
  fi
}

set_default_shell() {
  local zsh_path
  zsh_path=$(command -v zsh)

  echo "👉 Setting Zsh as default shell for $(whoami)..."
  if chsh -s "$zsh_path" "$(whoami)" 2>/dev/null; then
    echo "✅ Default shell set via chsh."
  elif sudo usermod --shell "$zsh_path" "$(whoami)" 2>/dev/null; then
    echo "✅ Default shell set via usermod."
  else
    echo "❌ Failed to set Zsh as default shell." && exit 1
  fi

  echo "🔎 Verified shell: $(getent passwd $(whoami) | cut -d: -f7)"
}

###############################################################################
# Run setup
###############################################################################
install_packages
clone_or_update_repo
setup_configs
install_neovim
setup_lazyvim
install_nerd_font
set_gnome_terminal_font
set_default_shell

###############################################################################
# Finish + Reboot
###############################################################################
echo -e "\n✅ Setup Complete!"
echo "👉 Zsh is your default shell."
echo "👉 LazyVim installed in Neovim."
echo "👉 Nerd Font installed and GNOME Terminal updated."

echo -e "\n🔄 Rebooting in 20 seconds..."
for i in {20..1}; do
  echo -ne "\rReboot in $i sec... Press CTRL+C to cancel."
  sleep 1
done
echo
sudo reboot
