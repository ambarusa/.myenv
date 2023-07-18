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

# Install zsh using apt
apt_update=$(apt-get -qq update)
if [ $? -eq 0 ]; then
    apt_install_silent batcat
    apt_install_silent neofetch
    apt_install_silent lsd

    if [ $? -eq 0 ]; then
        echo "batcat, neofetch, and lsd have been installed successfully!"

        # Install Zsh
        apt_install_silent zsh

        if [ $? -eq 0 ]; then
            echo "Zsh has been installed successfully!"
            chsh -s $(which zsh)

            # Check if Oh My Zsh setup was successful
            if [ $? -eq 0 ]; then
                echo "Oh My Zsh has been set up successfully!"
            else
                echo "Oh My Zsh setup failed. Please check the error messages above."
            fi
        else
            echo "Failed to install Zsh. Please check the error messages above."
        fi
    else
        echo "Failed to install batcat, neofetch, and lsd. Please check the error messages above."
    fi
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

