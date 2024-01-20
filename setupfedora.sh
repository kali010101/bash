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
info "Configuring DNF to enable 15 parallel downloads."
if grep -q "max_parallel_downloads" /etc/dnf/dnf.conf; then
    info "DNF is already configured for parallel downloads.\nConfiguration will be overwritten to enable 15 parallel downloads."
    sed -i '/^max_parallel_downloads=/c\max_parallel_downloads=15' /etc/dnf/dnf.conf
else
    echo "max_parallel_downloads=15" | tee -a /etc/dnf/dnf.conf >/dev/null
    info "Configured DNF for 15 parallel downloads."
fi
}

install_flatpak()
{
if ! command -v flatpak &>/dev/null; then
    info "Flatpak is not installed. Installing..."
    dnf install -y flatpak
fi
}

install_flathub_repos()
{
    info "Installing Flathub repositories if not already installed."
    flatpak remote-add --if-not-exists flathub "$URL_FLATHUB_REPO"
}

install_rpmfusion_repos()
{
    info "Installing RPM Fusion Free and Non-Free repositories."
    dnf install -y "$URL_RPMFUSION_FREE" "$URL_RPMFUSION_NONFREE"
}

update_packages()
{
    info "UPDATING PACKAGES."
    dnf update -y
    flatpak update -y
}

install_chrome()
{
    info "Installing Google Chrome from the flathub repository."
    flatpak install -y flathub com.google.Chrome
}

install_micro()
{
    info "Installing Micro Texteditor."
    curl "$URL_MICRO" | bash
    mv micro /usr/local/bin
}

install_vsc()
{
    info "Installing Microsoft Visual Studio Code."
    rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    dnf check-update
    dnf install -y code
}

install_python()
{
if command -v python3 &>/dev/null; then
    info "Python is already installed."
else
    info "Python not found. Installing..."
    dnf install -y python3
fi
}

install_golang()
{
if command -v go &>/dev/null; then
    info "Golang is already installed."
else
    info "Golang not found. Installing..."
    dnf install -y golang
fi
}

install_virt_manager()
{
    dnf install -y virt-manager
}

remove_gnome_bloat()
{
    info "Uninstalling bloatware."
    if dnf remove -y gnome-maps gnome-tour gnome-weather gnome-boxes gnome-contacts; then
        info "Bloatware successfully uninstalled."
    else
        info "Error: failed to uninstall bloatware."
        exit 1
    fi
    dnf autoremove -y
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