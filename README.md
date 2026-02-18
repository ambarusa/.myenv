# .myenv

A curated zsh environment with modern plugins, themes, and productivity tools.

## What's Included

- **powerlevel10k** - Powerful zsh theme with git status and customizable prompt
- **zsh-syntax-highlighting** - Syntax highlighting for zsh commands
- **zsh-autosuggestions** - Fish-like autosuggestions for zsh
- **zsh-history-substring-search** - Search history with substring matching
- **tmux config** - Terminal multiplexer configuration

## Quick Start

```bash
git clone --recurse-submodules https://github.com/ambarusa/.myenv.git
cd .myenv
sudo chmod +x configure.sh
sudo ./configure.sh
```

The script will:
1. Install required dependencies (zsh, tmux, bat, lsd, neofetch)
2. Install and configure Oh-My-Zsh
3. Link themes and plugins
4. Set zsh as your default shell
5. Optionally switch to zsh immediately

## Manual Setup

If you prefer manual setup:

```bash
# Clone with submodules
git clone --recurse-submodules https://github.com/ambarusa/.myenv.git ~/.myenv

# Install zsh (if not already installed)
# sudo apt install zsh

# Create symbolic links in Oh-My-Zsh directories
ln -s ~/.myenv/powerlevel10k ~/.oh-my-zsh/custom/themes/
ln -s ~/.myenv/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/
ln -s ~/.myenv/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/
ln -s ~/.myenv/zsh-history-substring-search ~/.oh-my-zsh/custom/plugins/

# Copy config files
cp ~/.myenv/.zshrc ~/
cp ~/.myenv/.p10k.zsh ~/
cp ~/.myenv/.tmux.conf ~/

# Set zsh as default shell
chsh -s $(which zsh)
```

## After Installation

1. Start a new shell or source your config: `source ~/.zshrc`
2. Run the p10k configuration wizard if you want to customize the theme: `p10k configure`
3. Customize `.zshrc` and `.p10k.zsh` to suit your preferences

## Configuration Files

- `.zshrc` - Zsh configuration with plugin setup
- `.p10k.zsh` - Powerlevel10k theme configuration  
- `.tmux.conf` - Tmux settings
