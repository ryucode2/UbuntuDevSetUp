#!/usr/bin/env bash
set -e

###############################################################################
# Ubuntu Dev Setup Installer (Idempotent + Auto-Reboot w/ Flag)
###############################################################################

skip_system_packages=""
auto_reboot="yes"

# Parse args
for arg in "$@"; do
    case "$arg" in
        --skip-system) skip_system_packages="1" ;;
        --no-reboot) auto_reboot="no" ;;
    esac
done

os_type="$(uname -s)"
config_dir="${HOME}/.config/UbuntuDevSetUp"
repo_url="https://github.com/ryucode2/UbuntuDevSetUp.git"

apt_packages="curl git iproute2 python3 python3-pip cmake ripgrep tmux zsh \
ninja-build gettext libtool libtool-bin autoconf automake g++ pkg-config unzip doxygen gpg gawk"
apt_packages_optional="gnupg htop npm rsync zsh-syntax-highlighting zsh-autosuggestions fonts-firacode"

###############################################################################
# Helpers
###############################################################################
backup_file() {
    local target="$1"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        mv "$target" "$target.bak.$(date +%s)"
        echo "📦 Backed up $target → $target.bak.$(date +%s)"
    fi
}

function apt_install_packages {
    sudo apt-get update
    sudo apt-get install -y ${apt_packages} ${apt_packages_optional}
}

###############################################################################
# OS Detection
###############################################################################
case "${os_type}" in
Linux*) os_type="Linux"
    if [ ! -f "/etc/debian_version" ]; then
        [ -z "${skip_system_packages}" ] && {
            echo "❌ Non-Debian Linux detected, skipping system packages."
            exit 1
        }
    fi ;;
Darwin*) os_type="macOS" ;;
*) os_type="Other"
   [ -z "${skip_system_packages}" ] && {
       echo "❌ Unsupported OS."
       exit 1
   } ;;
esac

###############################################################################
# Ensure Zsh installed
###############################################################################
if ! command -v zsh &>/dev/null; then
    echo "⚠️ Installing Zsh..."
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
# Install system packages (auto)
###############################################################################
if [ -z "${skip_system_packages}" ]; then
    echo "📦 Installing system packages..."
    apt_install_packages
else
    echo "⏭️ Skipping system package installation."
fi

###############################################################################
# Clone or update repo
###############################################################################
if [ ! -d "${config_dir}/.git" ]; then
    git clone "${repo_url}" "${config_dir}"
else
    echo "🔄 Updating repo..."
    git -C "${config_dir}" pull --ff-only
fi

###############################################################################
# Zsh config
###############################################################################
mkdir -p "${config_dir}/zsh"
[ ! -f "${config_dir}/zsh/.zshrc" ] && echo "# Default .zshrc" > "${config_dir}/zsh/.zshrc"
[ ! -f "${config_dir}/zsh/.aliases" ] && echo "# Default .aliases" > "${config_dir}/zsh/.aliases"

backup_file "${HOME}/.zshrc"
ln -fs "${config_dir}/zsh/.zshrc" "${HOME}/.zshrc"

backup_file "${HOME}/.aliases"
ln -fs "${config_dir}/zsh/.aliases" "${HOME}/.aliases"

###############################################################################
# Tmux config
###############################################################################
mkdir -p "${config_dir}/tmux"
[ ! -f "${config_dir}/tmux/.tmux.conf" ] && echo "# Default .tmux.conf" > "${config_dir}/tmux/.tmux.conf"

backup_file "${HOME}/.tmux.conf"
ln -fs "${config_dir}/tmux/.tmux.conf" "${HOME}/.tmux.conf"

###############################################################################
# Neovim config
###############################################################################
mkdir -p "${config_dir}/nvim"
if [ ! -d "${HOME}/.config/nvim" ]; then
    ln -s "${config_dir}/nvim" "${HOME}/.config/nvim"
fi

###############################################################################
# Install Neovim from source if missing
###############################################################################
if ! command -v nvim &>/dev/null; then
    git clone https://github.com/neovim/neovim
    cd neovim && make && sudo make install
    cd .. && rm -rf neovim
else
    echo "✅ Neovim already installed: $(nvim --version | head -n 1)"
fi

###############################################################################
# LazyVim (optional)
###############################################################################
if [ ! -d "${HOME}/.config/nvim/.git" ]; then
    read -rp "Install LazyVim starter config (overwrite ~/.config/nvim)? (y/n) " yn
    if [[ "${yn}" =~ ^[Yy]$ ]]; then
        rm -rf "${HOME}/.config/nvim"
        git clone https://github.com/LazyVim/starter "${HOME}/.config/nvim"
    fi
fi

###############################################################################
# Install tmux plugin manager (TPM)
###############################################################################
if [ ! -d "${HOME}/.tmux/plugins/tpm" ]; then
    git clone --depth 1 https://github.com/tmux-plugins/tpm "${HOME}/.tmux/plugins/tpm"
    "${HOME}/.tmux/plugins/tpm/bin/install_plugins" || true
else
    echo "✅ TPM already installed."
fi

###############################################################################
# Install fzf
###############################################################################
if [ ! -d "${HOME}/.local/share/fzf" ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git "${HOME}/.local/share/fzf"
    yes | "${HOME}/.local/share/fzf/install" --bin --no-update-rc
else
    echo "✅ fzf already installed."
fi

###############################################################################
# Set zsh as default shell
###############################################################################
if [ "${SHELL}" != "$(command -v zsh)" ]; then
    echo "Changing default shell to zsh..."
    chsh -s "$(command -v zsh)" || echo "⚠️ Could not change shell automatically."
fi

###############################################################################
# Done + Reboot Logic
###############################################################################
echo -e "\n🎉 Setup complete!"

if [ "$auto_reboot" = "yes" ]; then
    echo "System will reboot in 15 seconds..."
    echo "⏳ Press Ctrl+C to cancel reboot."
    for i in {15..1}; do
        echo -ne "$i...\r"
        sleep 1
    done
    echo "🔄 Rebooting now..."
    sudo reboot
else
    echo "👉 Skipping reboot (use --no-reboot flag). Please reboot manually when ready."
fi
