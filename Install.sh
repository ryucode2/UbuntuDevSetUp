#!/usr/bin/env bash
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
sudo apt-get install -y "${APT_PACKAGES[@]}" "${APT_OPTIONAL[@]}" dconf-cli gnome-tweaks gnome-extensions-app uuid-runtime xclip

# -----------------------------
# Extra: Install Zsh plugins if missing
# -----------------------------
ZSH_SHARE="/usr/share/"

# zsh-autosuggestions
if [ ! -d "$ZSH_SHARE/zsh-autosuggestions" ]; then
  echo "📦 Installing zsh-autosuggestions into $ZSH_SHARE..."
  sudo git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_SHARE/zsh-autosuggestions"
fi

# zsh-syntax-highlighting
if [ ! -d "$ZSH_SHARE/zsh-syntax-highlighting" ]; then
  echo "📦 Installing zsh-syntax-highlighting into $ZSH_SHARE..."
  sudo git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_SHARE/zsh-syntax-highlighting"
fi

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
[ ! -f "$CONFIG_DIR/zsh/.zshrc" ] && echo "# Default .zshrc" >"$HOME/.zshrc"

# -----------------------------
# 3️⃣ Symlink configs safely (excluding nvim)
# -----------------------------
echo "⚡ Symlinking config files..."

# Map zsh config
if [ -f "$CONFIG_DIR/zsh/.zshrc" ]; then
  target="$HOME/.zshrc"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    mv "$target" "$target.$(date +%Y%m%d%H%M%S).bak"
  fi
  ln -fs "$CONFIG_DIR/zsh/.zshrc" "$target"
  echo "Linked $CONFIG_DIR/zsh/.zshrc → $target"
fi

# -----------------------------
# Fix: Ensure tmux config is pulled and linked
# -----------------------------
mkdir -p "$CONFIG_DIR/tmux"
[ ! -f "$CONFIG_DIR/tmux/.tmux.conf" ] && echo "# Default .tmux.conf" >"$CONFIG_DIR/tmux/.tmux.conf"

if [ -f "$CONFIG_DIR/tmux/.tmux.conf" ]; then
  target="$HOME/.tmux.conf"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    mv "$target" "$target.$(date +%Y%m%d%H%M%S).bak"
  fi
  ln -fs "$CONFIG_DIR/tmux/.tmux.conf" "$target"
  echo "Linked $CONFIG_DIR/tmux/.tmux.conf → $target"
fi

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
# 6️⃣ GNOME Terminal Themes
# -----------------------------
echo "🎨 Setting up GNOME Terminal themes..."

PROFILE_ID=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d \')
PROFILE_PATH="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/"

declare -A THEMES

# Dracula
THEMES[Dracula_background]="#282A36"
THEMES[Dracula_foreground]="#F8F8F2"
THEMES[Dracula_palette]="['#000000','#FF5555','#50FA7B','#F1FA8C','#BD93F9','#FF79C6','#8BE9FD','#BFBFBF','#4D4D4D','#FF6E67','#5AF78E','#F4F99D','#CAA9FA','#FF92D0','#9AEDFE','#E6E6E6']"

# Solarized Dark
THEMES[SolarizedDark_background]="#002B36"
THEMES[SolarizedDark_foreground]="#839496"
THEMES[SolarizedDark_palette]="['#073642','#DC322F','#859900','#B58900','#268BD2','#D33682','#2AA198','#EEE8D5','#002B36','#CB4B16','#586E75','#657B83','#839496','#6C71C4','#93A1A1','#FDF6E3']"

# Gruvbox Dark
THEMES[GruvboxDark_background]="#282828"
THEMES[GruvboxDark_foreground]="#EBDBB2"
THEMES[GruvboxDark_palette]="['#282828','#CC241D','#98971A','#D79921','#458588','#B16286','#689D6A','#A89984','#928374','#FB4934','#B8BB26','#FABD2F','#83A598','#D3869B','#8EC07C','#EBDBB2']"

echo "Choose a GNOME Terminal theme:"
select choice in Dracula SolarizedDark GruvboxDark; do
    if [[ -n "$choice" ]]; then
        echo "Applying $choice..."
        gsettings set "$PROFILE_PATH" background-color "${THEMES[${choice}_background]}"
        gsettings set "$PROFILE_PATH" foreground-color "${THEMES[${choice}_foreground]}"
        gsettings set "$PROFILE_PATH" palette "${THEMES[${choice}_palette]}"
        gsettings set "$PROFILE_PATH" use-theme-colors false
        dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/use-transparent-background true
        dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/background-transparency-percent 15
        echo "✅ $choice theme applied with 15% transparency"
        break
    else
        echo "❌ Invalid choice"
    fi
done

# -----------------------------
# 7️⃣ Set Zsh as default shell
# -----------------------------
zsh_path=$(command -v zsh)
chsh -s "$zsh_path" 2>/dev/null || sudo usermod --shell "$zsh_path" "$(whoami)"
echo "🔎 Current shell: $(getent passwd $(whoami) | cut -d: -f7)"

# -----------------------------
# 8️⃣ Finish
# -----------------------------
echo -e "\n✅ Ubuntu Dev Setup Complete!"
echo "👉 Zsh is default shell"
echo "👉 LazyVim installed in Neovim (existing configs preserved)"
echo "👉 FiraCode Nerd Font installed"
echo "👉 GNOME Terminal theme applied with 15% transparency"
echo "👉 GNOME Extensions Manager installed — open it to install Workspace Grid & Indicator"
echo "👉 All config files in $CONFIG_DIR are pulled from repo and symlinked, existing files backed up as *.bak"

read -rp "🔄 Do you want to reboot now? (y/N) " REBOOT_CHOICE
[[ "$REBOOT_CHOICE" =~ ^[Yy]$ ]] && echo "Rebooting..." && sleep 2 && sudo reboot
