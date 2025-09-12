!/usr/bin/env bash
set -euo pipefail

echo "🚀 Starting Ubuntu Dev Setup..."

# -----------------------------
# 1️⃣ Install system packages
# -----------------------------
APT_PACKAGES=(
  curl git iproute2 python3 python3-pip cmake ripgrep tmux
  zsh ninja-build gettext libtool libtool-bin autoconf automake g++
  pkg-config unzip doxygen gpg gawk tree eza
  zsh-autosuggestions zsh-syntax-highlighting fontconfig
)
APT_OPTIONAL=(gnupg htop npm rsync fonts-firacode)

sudo apt-get update -qq
sudo apt-get install -y "${APT_PACKAGES[@]}" "${APT_OPTIONAL[@]}" dconf-cli gnome-tweaks gnome-extensions-app

# -----------------------------
# 2️⃣ Setup configs directory and pull repo
# -----------------------------
CONFIG_DIR="$HOME/.config/UbuntuDevSetUp"
mkdir -p "$CONFIG_DIR"

if [ ! -d "$CONFIG_DIR/.git" ]; then
  git clone --depth 1 --quiet https://github.com/ryucode2/UbuntuDevSetUp.git "$CONFIG_DIR"
else
  git -C "$CONFIG_DIR" pull --ff-only
fi

mkdir -p "$CONFIG_DIR/zsh" "$CONFIG_DIR/tmux" "$CONFIG_DIR/nvim"
[ ! -f "$CONFIG_DIR/zsh/.zshrc" ] && echo "# Default .zshrc" >"$CONFIG_DIR/zsh/.zshrc"
[ ! -f "$CONFIG_DIR/tmux/.tmux.conf" ] && echo "# Default .tmux.conf" >"$CONFIG_DIR/tmux/.tmux.conf"

# -----------------------------
# 3️⃣ Symlink configs safely
# -----------------------------
echo "⚡ Symlinking config files..."
find "$CONFIG_DIR" -type f | while read -r file; do
  rel_path="${file#$CONFIG_DIR/}"
  target="$HOME/$rel_path"
  mkdir -p "$(dirname "$target")"
  [ -e "$target" ] && mv "$target" "$target.bak"
  ln -fs "$file" "$target"
  echo "Linked $file → $target"
done

# -----------------------------
# 4️⃣ Install Neovim + LazyVim
# -----------------------------
NVIM_CONFIG="$HOME/.config/nvim"
if ! command -v nvim &>/dev/null; then
  TMP_DIR=$(mktemp -d)
  git clone --depth 1 --quiet https://github.com/neovim/neovim.git "$TMP_DIR/neovim"
  (cd "$TMP_DIR/neovim" && make CMAKE_BUILD_TYPE=Release && sudo make install)
  rm -rf "$TMP_DIR"
fi

if [ ! -d "$NVIM_CONFIG" ] || [ -z "$(ls -A "$NVIM_CONFIG")" ]; then
  rm -rf "$NVIM_CONFIG"
  git clone --depth 1 --quiet https://github.com/LazyVim/starter "$NVIM_CONFIG" 2>/dev/null || true
  rm -rf "$NVIM_CONFIG/.git" "$HOME/.config/nvim/init.vim"
  nvim --headless "+Lazy! sync" +qa || true
fi

# -----------------------------
# 5️⃣ Install FiraCode Nerd Font
# -----------------------------
mkdir -p "$HOME/.local/share/fonts"
cd "$HOME/.local/share/fonts"
if [ ! -f "FiraCodeNerdFontMono-Regular.ttf" ]; then
  curl -fLo FiraCode.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip
  unzip -qo FiraCode.zip -d FiraCode
  mv FiraCode/*.ttf .
  rm -rf FiraCode FiraCode.zip
  fc-cache -fv
fi

# -----------------------------
# 6️⃣ GNOME Terminal TokyoNight theme + transparency
# -----------------------------
export TERMINAL=gnome-terminal
echo "🎨 Installing GNOME Terminal theme (TokyoNight) with transparency..."
bash -c "$(wget -qO- https://git.io/vQgMr)" || {
  echo "❌ Gogh installer failed!"
  exit 1
}

PROFILE=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d \')
if [ -n "$PROFILE" ]; then
  dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE/use-transparent-background true
  dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE/background-transparency-percent 15
fi

# -----------------------------
# 7️⃣ Launch GNOME Extensions Manager
# -----------------------------
echo -e "\n⚡ GNOME Extensions Manager installed. Launching..."
echo "👉 Use it to install Workspace Grid, Workspace Indicator, and any other extensions."
gnome-extensions-app &

# -----------------------------
# 8️⃣ Set Zsh as default shell
# -----------------------------
zsh_path=$(command -v zsh)
chsh -s "$zsh_path" 2>/dev/null || sudo usermod --shell "$zsh_path" "$(whoami)"
echo "🔎 Current shell: $(getent passwd $(whoami) | cut -d: -f7)"

# -----------------------------
# 9️⃣ Finish
# -----------------------------
echo -e "\n✅ Ubuntu Dev Setup Complete!"
echo "👉 Zsh is default shell"
echo "👉 LazyVim installed in Neovim (existing configs preserved)"
echo "👉 FiraCode Nerd Font installed"
echo "👉 GNOME Terminal TokyoNight theme applied with 15% transparency"
echo "👉 GNOME Extensions Manager installed — open it to install Workspace Grid & Indicator"
echo "👉 All config files in $CONFIG_DIR are pulled from repo and symlinked, existing files backed up as *.bak"

read -rp "🔄 Do you want to reboot now? (y/N) " REBOOT_CHOICE
[[ "$REBOOT_CHOICE" =~ ^[Yy]$ ]] && echo "Rebooting..." && sleep 2 && sudo reboot
