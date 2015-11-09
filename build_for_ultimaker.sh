#!/bin/bash

set -e
set -u

UBOOT=`pwd`/u-boot/

pushd ${UBOOT}
#Check if the release version number is set, if not, we are building a dev version.
if [ -z ${RELEASE_VERSION+x} ]; then
	RELEASE_VERSION=9999.99.99
fi
BUILDCONFIG="opinicus_v1"
CROSS_COMPILE="arm-none-eabi-"

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
fakeroot dpkg-deb --build "debian"
mv debian.deb ../u-boot-sunxi.deb
popd
