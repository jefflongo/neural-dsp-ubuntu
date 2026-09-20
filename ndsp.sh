#!/usr/bin/env bash
set -euo pipefail

if [ $(id -u) -ne 0 ]
then
    echo "this script must be executed as root"
    exit 1
fi

USER_HOME=$(eval echo ~${SUDO_USER})
UBUNTU_RELEASE=$(lsb_release -sc 2>/dev/null)
WINE_INSTALL=$(dirname $(realpath /usr/bin/wine))/..
WINEPREFIX=${WINEPREFIX:=$USER_HOME/.wine}

# add winehq PPA
dpkg --add-architecture i386
mkdir -pm755 /etc/apt/keyrings
wget -qO /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
wget -qO /etc/apt/sources.list.d/winehq-${UBUNTU_RELEASE}.sources https://dl.winehq.org/wine-builds/ubuntu/dists/${UBUNTU_RELEASE}/winehq-${UBUNTU_RELEASE}.sources
apt update -q
apt install pipewire-jack winehq-stable wine-stable-dev winetricks -y

WINEASIO=$(mktemp -u)
trap 'rm -rf "$WINEASIO"' EXIT

# build wineasio
sudo -u $SUDO_USER git clone -q git@github.com:wineasio/wineasio.git $WINEASIO
sudo -u $SUDO_USER make -C $WINEASIO 64

# configure wine
sudo -u $SUDO_USER WINEDEBUG=-all wineboot -u
sudo -u $SUDO_USER winetricks -q dxvk

cp $WINEASIO/build64/wineasio64.dll $WINE_INSTALL/lib/wine/x86_64-unix/
cp $WINEASIO/build64/wineasio64.dll.so $WINE_INSTALL/lib/wine/x86_64-windows/
sudo -u $SUDO_USER cp $WINEASIO/build64/wineasio64.dll.so $WINEPREFIX/drive_c/windows/system32/wineasio64.dll
sudo -u $SUDO_USER regsvr32 /s $WINEASIO/build64/wineasio64.dll.so

echo -e "\033[0;32mWine is ready to go!\033[0m"
