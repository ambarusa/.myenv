#!/bin/bash
# Get the original user who called the script
original_user=$(who -m | awk '{print $1}')

# Check if the script is being run with sudo privileges
if [ "$EUID" -eq 0 ]; then
    echo "Script was invoked with sudo by user: $original_user"
else
    echo "Please run this script with sudo or as the root user."
    exit 1
fi

# Get the absolute path of the script
script_dir="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

# Navigate one level up from the script directory
target_dir=$(eval echo "~$original_user")

# Function to suppress output and print a custom message
function apt_install_silent {
    local pkg="$1"
    # Check if the package is already installed
    if command -v "$pkg" >/dev/null 2>&1 || \
       dpkg -l | grep -q "^ii\s\+$pkg\s" || \
       snap list | grep -q "^$pkg\s"; then
        echo "$pkg is already available."
        return 0
    fi

    echo "Install is in progress for package: $pkg"
    # Try APT first
    if apt-get -qq install -y "$pkg" >/dev/null 2>&1; then
        echo "$pkg installed via APT."
        return 0
    fi

    # Fallback to Snap
    if snap install "$pkg" >/dev/null 2>&1; then
        echo "$pkg installed via Snap."
        return 0
    fi

    echo "Failed to install $pkg via APT or Snap."
    return 1
}

function install_oh_my_zsh() {
    # Check if ~/.oh-my-zsh folder exists
    if [ -d "$target_dir/.oh-my-zsh" ]; then
        echo "Warning! $target_dir/.oh-my-zsh direcotry already exists, and it might contain important information to be backed up!"
        read -p "Can it be deleted? (y/n): " confirmation
        if [[ "$confirmation" != "y" ]]; then
            echo "Back up $target_dir/.oh-my-zsh, and come back later! Installation aborted. Exiting"
            exit 1
        else
            rm -rf "$target_dir/.oh-my-zsh"
            echo "$target_dir/.oh-my-zsh has been removed."
        fi
    fi

    # Proceed with installation
    echo "Install is in progress for Oh-My-Zsh"
    # Run the command as $original_user to obtain the correct path
    su -l "$original_user" -c 'sh -c "$(curl -fsSL https://install.ohmyz.sh/)" "" --unattended >/dev/null 2>&1'

    # Check if the installation was successful
    if [ $? -ne 0 ]; then
        echo "Failed to install Oh-My-Zsh. Please check your system logs for more details!"
        exit 1
    else
        echo "Oh-My-Zsh has been installed successfully."
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
    apt_install_silent lsd
    apt_install_silent zsh
    apt_install_silent tmux
    install_oh_my_zsh

    # Change the default shell to Zsh for the original user
    chsh -s "$(which zsh)" "$original_user"
else
    echo "Failed to update package lists. Please check the error messages above."
fi

# Create the links in the home directory using the user who called sudo
create_links $script_dir/powerlevel10k $target_dir/.oh-my-zsh/custom/themes
create_links $script_dir/zsh-autosuggestions $target_dir/.oh-my-zsh/custom/plugins
create_links $script_dir/zsh-history-substring-search $target_dir/.oh-my-zsh/custom/plugins
create_links $script_dir/zsh-syntax-highlighting $target_dir/.oh-my-zsh/custom/plugins
create_links $script_dir/.p10k.zsh $target_dir
create_links $script_dir/.zshrc $target_dir
create_links $script_dir/.tmux.conf $target_dir

# Installation was successful
echo "Installation was successful. Do you want to switch to Zsh now? (y/n)"
read -r switch_to_zsh

if [[ "$switch_to_zsh" == "y" || "$switch_to_zsh" == "Y" ]]; then
    echo "Switching to Zsh..."
    # Switch to original_user and start Zsh without blocking the script
    su -l "$original_user" -c "zsh &"
    exit 0
else
    echo "You can switch to Zsh later by typing 'zsh'. Exiting now."
    exit 0
fi
