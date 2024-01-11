#!/usr/bin/env bash

set -e

check_for_root() 
{
if [ "$EUID" -ne 0 ]; then
    echo -e "This script cannot run without root privileges.\nIt intends to configure the DNF package manager\nto enable parallel downloads and install\nthird party repositories, Google Chrome, VSCode\nand the Micro Texteditor. It will further\ninstall or update Python and Golang.\nIt will also update packages inbetween.\nIt is written to perform a quick setup\non a new installation of Fedora Linux Workstation.\nRun this script as root or contact your SysAdmin."
    exit 1
fi
}

configure_dnf() 
{
echo "Configuring DNF to enable 15 parallel downloads."
if grep -q "max_parallel_downloads" /etc/dnf/dnf.conf; then
    echo -e "DNF is already configured for parallel downloads.\nConfiguration will be overwritten to enable 15 parallel downloads."
    sed -i '/^max_parallel_downloads=/c\max_parallel_downloads=15' /etc/dnf/dnf.conf
else
    echo "max_parallel_downloads=15" | tee -a /etc/dnf/dnf.conf >/dev/null
    echo "Configured DNF for 15 parallel downloads."
fi
}

install_flatpak()
{
if ! command -v flatpak &>/dev/null; then
    echo "Flatpak is not installed. Installing..."
    dnf install flatpak -y
fi
}

install_flathub_repos()
{
    echo "Installing Flathub repositories if not already installed."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

install_rpmfusion_repos() 
{
    echo "Installing RPM Fusion Free and Non-Free repositories."
    dnf install -y \
    https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm \
    https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm
}

update_packages()
{
    echo "UPDATING PACKAGES."
    dnf update -y
    flatpak update -y
}

install_chrome()
{
    echo "Installing Google Chrome from the flathub repository."
    flatpak install -y flathub com.google.Chrome
}

install_micro()
{
    echo "Installing Micro Texteditor."
    curl https://getmic.ro | bash
    mv micro /usr/local/bin
}

install_vsc()
{
    echo "Installing Microsoft Visual Studio Code."
    rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    dnf check-update
    dnf install code -y
}

install_python()
{
if command -v python3 &>/dev/null; then
    echo "Python is already installed."
else
    echo "Python not found. Installing..."
    dnf install python3 -y
fi
}

install_golang()
{
if command -v go &>/dev/null; then 
    echo "Golang is already installed."
else
    echo "Golang not found. Installing..."
    dnf install golang -y
fi
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
    update_packages
}

main

echo "Setup complete."
