#!/bin/bash

# Check if the script is being run with sudo privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo or as the root user."
    exit 1
fi

# Function to suppress output and print a custom message
function apt_install_silent {
    echo "Install is in progress for package: $1"
    apt-get -qq install -y "$1" >/dev/null 2>&1

    # Check if the installation was successful, exit if not
    if [ $? -ne 0 ]; then
        echo "Failed to install $1. Please check the error messages above."
        exit 1
    fi
}

# Function to create symbolic links for directories and hard links for files
function create_links {
    source_path="$1"
    dest_dir="$2"
    link_name="${3:-$(basename "$source_path")}" # Use default name if link_name is not provided

    # Check if the source exists
    if [ ! -e "$source_path" ]; then
        echo "Source path '$source_path' does not exist."
        return 1
    fi

    # Get the base name of the source path
    source_name="$(basename "$source_path")"

    # Create symbolic link for a directory, overwrite it if it exists
    if [ -d "$source_path" ]; then
        # Remove the old symlink (if exists) before creating a new one for a directory
        if [ -L "$dest_dir/$link_name" ]; then
            rm "$dest_dir/$link_name"
        fi
        su - "$SUDO_USER" -c "ln -s "$source_path" "$dest_dir/$link_name" 2>/dev/null"
        if [ $? -eq 0 ]; then
            echo "Symbolic link created for $source_name in $dest_dir"
        else
            echo "Failed to create symbolic link for $source_name in $dest_dir"
        fi
    # Create hard link for a file, overwrite it if it exists
    elif [ -f "$source_path" ]; then
        su - "$SUDO_USER" -c "ln -f "$source_path" "$dest_dir/$link_name" 2>/dev/null"
        if [ $? -eq 0 ]; then
            echo "Hard link created for $source_name in $dest_dir"
        else
            echo "Failed to create hard link for $source_name in $dest_dir"
        fi
    else
        echo "Source path '$source_path' is neither a file nor a directory."
    fi
}

# Installing the packages. apt_install_silent function exits from the script if there is a failure
# No need for extra verification
apt_update=$(apt-get -qq update)
if [ $? -eq 0 ]; then
    apt_install_silent bat
    apt_install_silent neofetch
    #    apt_install_silent lsd - lsd doesn't seem to be available in apt
    lsd_link="https://github.com/Peltoche/lsd/releases/download/0.23.1/lsd-musl_0.23.1_amd64.deb"
    wget -qO tmp "$lsd_link"
    if [ $? -eq 0 ]; then
        dpkg -i tmp > /dev/null
        rm tmp
    else
        echo "Lsd release was not found!"
    fi

    echo "batcat, neofetch, and lsd have been installed successfully!"

    # Install Zsh
    apt_install_silent zsh
    echo "Zsh has been installed successfully!"
    chsh -s $(which zsh)
else
    echo "Failed to update package lists. Please check the error messages above."
fi

# Get the absolute path of the script
script_dir="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

# Navigate one level up from the script directory
target_dir="$(realpath "$script_dir/..")"

# Check if the .zshrc file exists in the target directory
if [ -f "$target_dir/.zshrc" ]; then
    # Backing up original .zshrc file
    cp $target_dir/.zshrc $target_dir/.zshrc.orig
else
    echo "Error: .zshrc file not found in the current directory."
fi

# Create the links in the home directory using the user who called sudo
create_links $script_dir/ohmyzsh $target_dir ".oh-my-zsh"
create_links $script_dir/powerlevel10k $target_dir/.oh-my-zsh/custom/themes
create_links $script_dir/zsh-autosuggestions $target_dir/.oh-my-zsh/custom/plugins
create_links $script_dir/zsh-history-substring-search $target_dir/.oh-my-zsh/custom/plugins
create_links $script_dir/zsh-syntax-highlighting $target_dir/.oh-my-zsh/custom/plugins
create_links $script_dir/.p10k.zsh $target_dir
create_links $script_dir/.zshrc $target_dir
#create_links $script_dir/.tmux.conf $target_dir
