#!/bin/bash

# Check for a valid cross compiler. When unset, the kernel tries to build itself
# using arm-none-eabi-gcc, so we need to ensure it exists. Because printenv and
# which can cause bash -e to exit, so run this before setting this up.
CROSS_COMPILE=$(printenv CROSS_COMPILE)
if [ ${CROSS_COMPILE+x} ]; then
    _CROSS_COMPILE=`which arm-none-eabi-gcc`
    if [ -z ${_CROSS_COMPILE} ]; then
        _CROSS_COMPILE=`which arm-linux-gnueabihf-gcc`
        if [ ${_CROSS_COMPILE} ]; then
            CROSS_COMPILE="arm-linux-gnueabihf-"
            export CROSS_COMPILE=${CROSS_COMPILE}
        else
            echo "No suiteable cross-compiler found."
            echo "One can be set explicitly via the environment variable CROSS_COMPILE='arm-linux-gnueabihf-' for example."
	    exit
        fi
    fi
fi

set -e
set -u

UBOOT=`pwd`/u-boot/

pushd ${UBOOT}
#Check if the release version number is set, if not, we are building a dev version.
if [ -z ${RELEASE_VERSION+x} ]; then
	RELEASE_VERSION=9999.99.99
fi
BUILDCONFIG="opinicus_v1"

#Build the actual bootloader
ARCH=arm CROSS_COMPILE="${CROSS_COMPILE}" make "${BUILDCONFIG}_defconfig"
ARCH=arm CROSS_COMPILE="${CROSS_COMPILE}" make

#Setup the debian package data
rm -rf debian
mkdir -p debian/boot
mkdir -p debian/DEBIAN
cp u-boot-sunxi-with-spl.bin debian/boot/
cat > debian/DEBIAN/control <<-EOT
Package: u-boot-sunxi
Source: linux-upstream
Version: ${RELEASE_VERSION}
Architecture: armhf
Maintainer: Anonymous <root@monolith.ultimaker.com>
Section: kernel
Priority: optional
Description: u-boot image with spl for A20 CPU.
EOT

#Build the debian package
fakeroot dpkg-deb --build "debian" ../u-boot-sunxi-${RELEASE_VERSION}.deb
popd
