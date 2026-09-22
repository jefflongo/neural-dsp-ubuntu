#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "Do not run this script with sudo." >&2
    echo "Run it as your normal user: $0" >&2
    exit 1
fi

if ! sudo -v; then
    echo "This script requires sudo privileges." >&2
    exit 1
fi

# check if we need to install the WineHQ PPA
WINE_VERSION=$(apt-cache policy wine | awk '/Candidate:/ {print $2}')
if dpkg --compare-versions "$WINE_VERSION" lt "10"; then
    echo -e "\033[33mInsufficient wine version available, installing PPA\033[0m"
    UBUNTU_RELEASE=$(lsb_release -sc 2>/dev/null)
    sudo mkdir -pm755 /etc/apt/keyrings
    sudo wget -qO /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
    sudo wget -qO /etc/apt/sources.list.d/winehq-${UBUNTU_RELEASE}.sources https://dl.winehq.org/wine-builds/ubuntu/dists/${UBUNTU_RELEASE}/winehq-${UBUNTU_RELEASE}.sources
    WINE_PKGS="winehq-stable wine-stable-dev"
else
    WINE_PKGS="libwine-dev wine wine64-tools"
fi

# check if we need to install the PipeWire PPA
LIBPIPEWIRE_VERSION=$(apt-cache policy libpipewire-0.3-dev | awk '/Candidate:/ {print $2}')
if dpkg --compare-versions "$LIBPIPEWIRE_VERSION" lt "1.4.2"; then
    echo -e "\033[33mInsufficient libpipewire version available, installing PPA\033[0m"
    sudo add-apt-repository ppa:savoury1/pipewire -y
fi

# install dependencies
sudo dpkg --add-architecture i386
sudo apt update -q
sudo apt install -yq build-essential cmake g++-mingw-w64-x86-64 gcc-mingw-w64-x86-64 git libarchive-dev libpipewire-0.3-dev libwine-dev libyaml-cpp-dev ninja-build pkg-config qt6-base-dev $WINE_PKGS winetricks zlib1g-dev

PIPEASIO=$(mktemp -d)
trap 'rm -rf "$PIPEASIO"' EXIT

# install PipeASIO
git clone https://github.com/M0n7y5/pipeasio.git --depth 1 --single-branch $PIPEASIO
cmake -S $PIPEASIO -B $PIPEASIO/build -DPIPEASIO_WINE_INSTALL_ROOT=$(dirname $(realpath $(which wine)))/../lib/wine
cmake --build $PIPEASIO/build
sudo cmake --install $PIPEASIO/build --prefix /usr

# configure Wine
WINEDEBUG=-all wineboot -u
$PIPEASIO/pipeasio-register
winetricks -q dxvk

echo -e "\033[0;32mWine is ready to go!\033[0m"
