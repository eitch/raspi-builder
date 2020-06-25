#!/bin/bash -e

ROOTDIR="$1"
BOOTDIR=${ROOTDIR}/boot

cd "${TOOLCHAIN}"

BUILD_PATH=./rpi-linux/kernel-build
TOOLS_PATH=./rpi-tools/armstubs

cd rpi-linux
KERNEL_VERSION="$(make kernelversion)-v8+"

cd "${TOOLCHAIN}"

if ! [[ -d firmware-nonfree ]] ; then
  git clone https://github.com/RPi-Distro/firmware-nonfree firmware-nonfree
fi

if ! [[ -d rpi-firmware ]] ; then
  git clone https://github.com/Hexxeh/rpi-firmware.git rpi-firmware
fi

echo "INFO: Copying firmware files..."
cp -v rpi-firmware/bcm* "${BOOTDIR}/"
cp -v rpi-firmware/bootcode.bin "${BOOTDIR}/"
cp -v rpi-firmware/fixup* "${BOOTDIR}/"
cp -v rpi-firmware/kernel* "${BOOTDIR}/"
cp -v rpi-firmware/Module* "${BOOTDIR}/"
cp -v rpi-firmware/start* "${BOOTDIR}/"
cp -v rpi-firmware/uname* "${BOOTDIR}/"
cp -rv rpi-firmware/overlays "${BOOTDIR}/"

echo "INFO: Copying compiled kernel..."
cp -v ${BUILD_PATH}/arch/arm64/boot/Image "${BOOTDIR}/kernel8.img"
cp -v ${BUILD_PATH}/arch/arm64/boot/dts/broadcom/*.dtb "${BOOTDIR}/overlays/"
cp -v ./rpi-linux/arch/arm64/boot/dts/overlays/README "${BOOTDIR}/overlays/"
cp -v ${TOOLS_PATH}/armstub8-gic.bin "${BOOTDIR}/armstub8-gic.bin"

echo "INFO: Copying modules..."
rm -rf ${ROOTDIR}/lib/modules/${KERNEL_VERSION}
mkdir -p ${ROOTDIR}/lib/modules/${KERNEL_VERSION}
cp -rv ${BUILD_PATH}/kernel-install/lib/modules/${KERNEL_VERSION}/kernel "${ROOTDIR}/lib/modules/${KERNEL_VERSION}/"
cp -v ${BUILD_PATH}/kernel-install/lib/modules/${KERNEL_VERSION}/mod* "${ROOTDIR}/lib/modules/${KERNEL_VERSION}/"

echo "INFO: Copying firmware..."
rsync -av firmware-nonfree/* "${ROOTDIR}/lib/firmware"

echo "INFO: Copying config.txt..."
cp ../../boot/config_64.txt "${BOOTDIR}/config.txt"

exit 0