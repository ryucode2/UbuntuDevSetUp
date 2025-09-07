#!/usr/bin/env bash
set -e

###############################################################################
# Ubuntu Dev Setup Installer
###############################################################################

skip_system_packages="${1}"
os_type="$(uname -s)"
config_dir="${HOME}/.config/UbuntuDevSetUp"

apt_packages="curl git iproute2 python3 python3-pip cmake ripgrep tmux zsh \
ninja-build gettext libtool libtool-bin autoconf automake g++ pkg-config unzip doxygen gpg gawk"
apt_packages_optional="gnupg htop npm rsync zsh-syntax-highlighting zsh-autosuggestions fonts-firacode"

###############################################################################
# Helper functions
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

function display_packages {
    echo "${apt_packages} ${apt_packages_optional}"
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
*) os_type="Other"
   [ -z "${skip_system_packages}" ] && no_system_packages ;;
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
# Install system packages (prompt)
###############################################################################
if [ -z "${skip_system_packages}" ]; then
    cat <<EOF
The following system packages will be installed:
$(display_packages)
EOF
    while true; do
        read -rp "Proceed? (y/n) " yn
        case "${yn}" in
        [Yy]*) apt_install_packages; break ;;
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
    git clone https://github.com/ryucode2/Ubuntu-Dev-SetUp.git "${config_dir}"
else
    echo "Updating repo: ${config_dir}"
    git -C "${config_dir}" pull --ff-only
fi

###############################################################################
# Normalize repo directories (fix capitalization issues)
###############################################################################
for d in Zsh zsh Tmux tmux Nvim nvim; do
    if [ -d "${config_dir}/${d}" ]; then
        lower=$(echo "$d" | tr '[:upper:]' '[:lower:]')
        if [ "$d" != "$lower" ]; then
            echo "Renaming ${d} → ${lower}"
            mv "${config_dir}/${d}" "${config_dir}/${lower}"
        fi
    fi
done

###############################################################################
# Ensure configs exist & symlink
###############################################################################

# Zsh
mkdir -p "${config_dir}/zsh"
[ ! -f "${config_dir}/zsh/.zshrc" ] && echo "# Default .zshrc" > "${config_dir}/zsh/.zshrc"
[ ! -f "${config_dir}/zsh/.aliases" ] && echo "# Default .aliases" > "${config_dir}/zsh/.aliases"
ln -fs "${config_dir}/zsh/.zshrc" "${HOME}/.zshrc"
ln -fs "${config_dir}/zsh/.aliases" "${HOME}/.aliases"

# Tmux
mkdir -p "${config_dir}/tmux"
[ ! -f "${config_dir}/tmux/.tmux.conf" ] && echo "# Default .tmux.conf" > "${config_dir}/tmux/.tmux.conf"
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
# Install LazyVim starter config
###############################################################################
rm -rf "${HOME}/.config/nvim"
git clone https://github.com/LazyVim/starter "${HOME}/.config/nvim"

###############################################################################
# Install tmux plugin manager (TPM)
###############################################################################
rm -rf "${HOME}/.tmux/plugins/tpm"
git clone --depth 1 https://github.com/tmux-plugins/tpm "${HOME}/.tmux/plugins/tpm"
"${HOME}/.tmux/plugins/tpm/bin/install_plugins" || true

###############################################################################
# Install fzf
###############################################################################
rm -rf "${HOME}/.local/share/fzf"
git clone --depth 1 https://github.com/junegunn/fzf.git "${HOME}/.local/share/fzf"
yes | "${HOME}/.local/share/fzf/install" --bin --no-update-rc

###############################################################################
# Set zsh as default shell
###############################################################################
if [ "${SHELL}" != "$(command -v zsh)" ]; then
    echo "Changing default shell to zsh..."
    chsh -s "$(command -v zsh)" || echo "⚠️ Could not change shell automatically."
fi

###############################################################################
# Cleanup & Reboot with countdown
###############################################################################
echo "Cleaning up installer..."
rm -rf "${PWD}/Ubuntu-Dev-SetUp" || true

echo -e "\n✅ Setup complete!"
echo "System will reboot in 10 seconds to apply changes..."
for i in {10..1}; do
    echo -ne "$i...\r"
    sleep 1
done

sudo reboot
