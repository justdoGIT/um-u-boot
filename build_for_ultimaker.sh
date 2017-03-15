#!/bin/bash

# This scripts builds the bootloader for the A20 linux system that we use.

# Check for a valid cross compiler. When unset, the kernel tries to build itself
# using arm-none-eabi-gcc, so we need to ensure it exists. Because printenv and
# which can cause bash -e to exit, so run this before setting this up.
if [ "${CROSS_COMPILE}" == "" ]; then
	if [ "$(which arm-none-eabi-gcc)" != "" ]; then
		CROSS_COMPILE="arm-none-eabi-"
	fi
	if [ "$(which arm-linux-gnueabihf-gcc)" != "" ]; then
		CROSS_COMPILE="arm-linux-gnueabihf-"
	fi
	if [ "${CROSS_COMPILE}" == "" ]; then
		echo "No suiteable cross-compiler found."
		echo "One can be set explicitly via the environment variable CROSS_COMPILE='arm-linux-gnueabihf-' for example."
		exit 1
	fi
fi
export CROSS_COMPILE=${CROSS_COMPILE}

if [ "${MAKEFLAGS}" == "" ]; then
	echo -e -n "\e[1m"
	echo "Makeflags not set, hint, to speed up compilation time, increase the number of jobs. For example:"
	echo "MAKEFLAGS='-j 4' ${0}."
	echo -e "\e[0m"
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
