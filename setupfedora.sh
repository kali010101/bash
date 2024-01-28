#!/usr/bin/env bash

set -e

info()
{
    echo -e "\e[1;4;32;40m${*}\e[0m"
}

URL_FLATHUB_REPO="https://dl.flathub.org/repo/flathub.flatpakrepo"
URL_RPMFUSION_FREE="https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
URL_RPMFUSION_NONFREE="https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
URL_MICRO="https://getmic.ro"

check_for_root()
{
    if [ "$EUID" -ne 0 ]; then
        info "This script cannot run without root privileges.\nIt intends to configure the DNF package manager\nto enable parallel downloads, add repositories\nfor Flathub and RPM Fusion (Free and Non-Free)\nand install Google Chrome, VSCode, Virt-Manager\nand the text editor Micro. It will further update\nor install Python and Golang and uninstall apps\nconsidered to be bloatware. Dependencies which\nmight become obsolete as a result of this will\nalso be deleted. Run this script as root or with\ntemporarily elevated privileges (superuser)."
        exit 126
    fi
}

configure_dnf()
{
    DNFCONFIG_PATH="/etc/dnf/dnf.conf"
    info "Configuring DNF to enable 15 parallel downloads."
    if grep -q "max_parallel_downloads" $DNFCONFIG_PATH; then
        info "DNF is already configured for parallel downloads.\nConfiguration will be overwritten to enable 15 parallel downloads."
        sed -i '/^max_parallel_downloads=/c\max_parallel_downloads=15' $DNFCONFIG_PATH
    else
    echo "max_parallel_downloads=15" | tee -a $DNFCONFIG_PATH >/dev/null
    info "Configured DNF for 15 parallel downloads."
    fi
}

install_flatpak()
{
    if ! command -v flatpak >/dev/null; then
        info "Flatpak is not installed. Installing..."
        if ! dnf install -y flatpak >/dev/null; then
            info "Flatpak could not be installed."
        fi
        info "Flatpak has been installed successfully."
    fi
}

install_flathub_repos()
{
    info "Installing Flathub repositories if not already installed."
    flatpak remote-add --if-not-exists flathub "$URL_FLATHUB_REPO" >/dev/null
}

install_rpmfusion_repos()
{
    info "Installing RPM Fusion Free and Non-Free repositories."
    if ! dnf install -y "$URL_RPMFUSION_FREE" "$URL_RPMFUSION_NONFREE" >/dev/null; then
        info "RPM Fusion repositories could not be installed."
    fi
    info "RPM Fusion repositories have been installed."
}

update_packages()
{
    info "UPDATING PACKAGES."
    dnf update -y >/dev/null
    flatpak update -y >/dev/null
}

install_chrome()
{
    info "Installing Google Chrome from the flathub repository."
    if ! flatpak install -y flathub com.google.Chrome >/dev/null; then
        info "Google Chrome could not be installed."
    fi
    info "Google Chrome has been installed successfully."
}

install_micro()
{
    info "Installing Micro Texteditor."
    curl "$URL_MICRO" | bash >/dev/null
    mv micro /usr/local/bin
    if ! command -v micro >/dev/null; then
        info "The text editor Micro could either\nnot be installed or moved into a directory\nassigned to the PATH variable."
    fi
}

install_vsc()
{
    info "Installing Microsoft Visual Studio Code."
    rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    dnf check-update >/dev/null
    if ! dnf install -y code >/dev/null; then
        info "Microsoft Visual Studio Code could not be installed."
    fi
    info "Microsoft Visual Studio Code has been installed successfully."
}

install_python()
{
if ! command -v python3 >/dev/null; then
    info "Python not found. Installing..."
    if ! dnf install -y python3 >/dev/null; then
        info "Python could not be installed."
    fi
    info "Python has been installed successfully."
fi
}

install_golang()
{
if ! command -v go >/dev/null; then
    info "Golang not found. Installing..."
    if ! dnf install -y golang >/dev/null; then
        info "Golang could not be installed."
    fi
    info "Golang has been installed successfully."
fi
}

install_virt_manager()
{
    info "Installing Virt-Manager."
    if ! dnf install -y virt-manager >/dev/null; then
        info "Virt-Manager could not be installed."
    fi
    info "Virt-Manager has been installed successfully."
}

remove_gnome_bloat()
{
    info "Uninstalling bloatware."
    if ! dnf remove -y gnome-maps gnome-tour gnome-weather gnome-boxes gnome-contacts >/dev/null; then
        info "Error: failed to uninstall bloatware."
        exit 1
    fi
    dnf autoremove -y >/dev/null
    info "Bloatware has been uninstalled successfully."
}

main()
{
    check_for_root
    configure_dnf
    install_flatpak
    install_flathub_repos
    install_rpmfusion_repos
    update_packages
    install_chrome
    install_micro
    install_vsc
    install_python
    install_golang
    install_virt_manager
    remove_gnome_bloat
    update_packages
}

main

info "Setup complete."