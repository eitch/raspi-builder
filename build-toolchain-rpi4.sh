#!/bin/bash -e

##
## https://blog.cloudkernels.net/posts/rpi4-64bit-image/
##

# build bin-utils
cd "$TOOLCHAIN"
if ! [[ -d ${BIN_UTILS} ]] ; then
  if ! [[ -f ${BIN_UTILS}.tar.bz2 ]] ; then
    wget https://ftp.gnu.org/gnu/binutils/${BIN_UTILS}.tar.bz2
  fi
  tar -xf "${BIN_UTILS}.tar.bz2"
fi

mkdir -p "${BIN_UTILS}-build"
cd "${BIN_UTILS}-build"
../${BIN_UTILS}/configure --prefix="$TOOLCHAIN" --target=aarch64-linux-gnu --disable-nls
make -j"${JOBS}"
make install

# build gcc
cd "$TOOLCHAIN"
if ! [[ -d ${GCC} ]] ; then
  if ! [[ -f "${GCC}.tar.gz" ]] ; then
    wget "https://ftp.gnu.org/gnu/gcc/${GCC}/${GCC}.tar.gz"
  fi
  tar -xf "${GCC}.tar.gz"
fi

cd "${GCC}"
./contrib/download_prerequisites
cd ..

mkdir -p "${GCC}-build"
cd "${GCC}-build"
../${GCC}/configure --prefix="$TOOLCHAIN" --target=aarch64-linux-gnu --with-newlib --without-headers --disable-nls --disable-shared --disable-threads --disable-libssp --disable-decimal-float --disable-libquadmath --disable-libvtv --disable-libgomp --disable-libatomic --enable-languages=c
make all-gcc -j"${JOBS}"
make install-gcc

exit 0