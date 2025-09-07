# Ubuntu-Dev-SetUp
# 🛠️ Ubuntu Dev Setup Script: Zsh, Tmux, Neovim from Source
[![GitHub Repo](https://img.shields.io/badge/GitHub-Ubuntu--Dev--Setup-blue?logo=github)](https://github.com/ryucode2/Ubuntu-Dev-Setup)
Save hours every time you set up a new Linux system. This script automates the installation of Zsh, Tmux, and Neovim from source—fully modular, documented, and built for repeatability.

## 🚀 What It Does
- Installs **Zsh** with custom configs and plugin manager
- Builds **Tmux** from source with TPM and themes
- Compiles **Neovim** from source with plugin-ready setup
- Applies system tweaks for smoother dev workflows

## 📦 Why Use This?
- ✅ No more manual installs or config headaches  
- ✅ Fully modular—extend or swap components easily  
- ✅ Ideal for dotfiles, team onboarding, or setup-as-a-service

## ⚙️ Requirements
- Ubuntu 22.04+  
- Git, curl, build-essential

## 🧠 Usage

```bash
git clone https://github.com/ryucode2/Ubuntu-Dev-SetUp.git
cd ubuntu-dev-setup
bash install.sh


🧩 Modular Structure

This setup is broken into separate modules so you can customize or extend it easily:

• `install.sh` – Main runner script
• `modules/zsh.sh` – Installs Zsh and plugins
• `modules/tmux.sh` – Builds Tmux from source
• `modules/neovim.sh` – Compiles Neovim and sets up plugins
• `config/` – Optional themes, aliases, and extras


You can comment out or replace any module to fit your workflow.

📺 **Watch It in Action**  
[▶️ YouTube Demo](https://youtu.be/PmsCRZN20_M?si=xvTDMzM5T5tMaieT)


📬 Want This for Arch or Fedora?

Open an issue or drop a comment on the video!

🧠 License & Credits

This project is licensed under the MIT License.
See the LICENSE file for details.

Built by Leonel.
Inspired by the need for speed, clarity, and control in dev setups.
