#!/bin/bash -e

SOURCEDIR="$(cd ${0%/*} ; pwd)"
export TOOLCHAIN="${SOURCEDIR}/toolchains/aarch64"

cd "${TOOLCHAIN}"
if [[ -d rpi-linux ]] ; then
  echo "INFO: Cleaning Raspberry Pi 4 Kernel at ${TOOLCHAIN}/rpi-linux"
  cd rpi-linux
  git clean -Xf
  git clean -df
  git reset --hard
fi

cd "${TOOLCHAIN}"
if [[ -d rpi-firmware ]] ; then
  echo "INFO: Cleaning Raspberry Pi 4 Firmware at ${TOOLCHAIN}/rpi-firmware"
  cd rpi-firmware
  git clean -Xf
  git clean -df
  git reset --hard
fi

exit 0