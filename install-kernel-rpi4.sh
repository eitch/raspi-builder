#!/bin/bash -e

SOURCEDIR="$(cd ${0%/*} ; pwd)"
ROOTDIR="$1"
if ! [[ -d ${ROOTDIR} ]] ; then
  echo "ERROR: root directory does not exist at ${ROOTDIR}"
  exit 1
fi
if ! [[ -d ${ROOTDIR}/boot ]] ; then
  echo "ERROR: boot directory does not exist at ${ROOTDIR}"
  exit 1
fi
if ! [[ -d ${ROOTDIR}/lib ]] ; then
  echo "ERROR: lib directory does not exist at ${ROOTDIR}"
  exit 1
fi
cd ${ROOTDIR}
ROOTDIR=$(pwd)
echo "INFO: root dir is ${ROOTDIR}"

export JOBS=6
export BIN_UTILS="binutils-2.32"
export GCC="gcc-9.1.0"

export TOOLCHAIN="${SOURCEDIR}/toolchains/aarch64"
if ! [[ -d ${TOOLCHAIN} ]] ; then
  echo "INFO: Creating toolchain directory at ${TOOLCHAIN}"
  mkdir -p "${TOOLCHAIN}"
fi
cd "${TOOLCHAIN}"

toolTest="${TOOLCHAIN}/bin/aarch64-linux-gnu-gcc"
if [[ -f "${toolTest}" ]] ; then
  echo "INFO: Toolchain already available at ${toolTest}"
else
  echo "INFO: Building toolchain at ${TOOLCHAIN}"
  ${SOURCEDIR}/build-toolchain-rpi4.sh
fi

kernelTest="${TOOLCHAIN}/rpi-linux/kernel-build/arch/arm64/boot/Image"
if [[ -f "${kernelTest}" ]] ; then
  echo "INFO: Kernel already available at ${kernelTest}"
else
  echo "INFO: Building Kernel at ${TOOLCHAIN}"
  ${SOURCEDIR}/build-kernel-rpi4.sh
fi

"${SOURCEDIR}/copy-kernel-rpi4.sh" "${ROOTDIR}"

exit 0