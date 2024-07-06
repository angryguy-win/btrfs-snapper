#!/usr/bin/env bash


install_packages() {
    # Check if the file exists
    if [ ! -f "pkg-files/$1" ]; then
        echo "File not found!"
        exit 1
    fi

    # Usage: install_packages <file>
    # install_packages "packages.txt"

    local file="$1"
    local PKGS=()

    echo "INSTALLING SOFTWARE"

    # Read the file and populate the PKGS array
    while IFS= read -r line; do
        PKGS+=("$line")
    done < "$file"

    # Install the packages
    for PKG in "${PKGS[@]}"; do
        echo "INSTALLING: ${PKG}"
        sudo pacman -S "$PKG" --noconfirm --needed
    done
}

## Install packages from a file  ##
install_packages "pkg-files/base-pkgs.txt"
install_packages "pkg-files/software-pacman.txt"
# install_packages "pkg-files/flatpak-packages.txt"
