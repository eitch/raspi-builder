#!/bin/bash -e

if ! which bison > /dev/null || ! which flex > /dev/null ; then
  echo "INFO: Calling sudo to install bison and flex"
  sudo apt-get install bison flex
fi

cd "${TOOLCHAIN}"
if ! [[ -d rpi-linux ]] ; then
  git clone https://github.com/raspberrypi/linux.git rpi-linux
fi

cd rpi-linux
git fetch
git clean -Xf
git clean -df

git checkout rpi-4.19.y # change the branch name for newer versions
git reset --hard

mkdir -p kernel-build

export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export KBUILD_OUTPUT=./kernel-build/
export INSTALL_MOD_PATH="./kernel-install"
export PATH=$PATH:$TOOLCHAIN/bin

make bcm2711_defconfig
make -j${JOBS}
make -j"${JOBS}" modules dtbs
make -j"${JOBS}" modules_install

cd "${TOOLCHAIN}"
if ! [[ -d rpi-tools ]] ; then
  git clone https://github.com/raspberrypi/tools.git rpi-tools
fi
cd rpi-tools/armstubs
git checkout 7f4a937e1bacbc111a22552169bc890b4bb26a94
PATH=$PATH:$TOOLCHAIN/bin make armstub8-gic.bin

exit 0