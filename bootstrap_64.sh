#!/bin/bash -e

if [[ "$(whoami)" != "root" ]] ; then
  echo -e "ERROR: This script must run as root!"
  exit 1
fi

SOURCEDIR=$(dirname $0)

export NEW_USER="pi"

check_installed() {
    type $1 >/dev/null 2>&1 || { echo >&2 "$1 not installed"; exit 1; }
}

echo "INFO: Checking for required programs..."
check_installed vmdebootstrap
check_installed apt-cacher-ng
check_installed qemu-aarch64-static

IMAGE=`date +raspbian_arm64-%Y%m%d.img`

# sudo vi /usr/lib/python2.7/dist-packages/vmdebootstrap/constants.py
#    ---
#    vmdebootstrap/constants.py | 2 +-
#    1 file changed, 1 insertion(+), 1 deletion(-)
#
#    diff --git a/vmdebootstrap/constants.py b/vmdebootstrap/constants.py
#    index 9f39415..3d807c6 100644
#    --- a/vmdebootstrap/constants.py
#    +++ b/vmdebootstrap/constants.py
#    @@ -46,7 +46,7 @@ arch_table = {  # pylint: disable=invalid-name
#             'package': 'grub-efi-arm64',
#             'bin_package': 'grub-efi-arm64-bin',
#             'extra': None,
#    -        'exclusive': True,
#    +        'exclusive': False,
#             'target': 'arm64-efi',
#         }
#     }
#    --
#    2.9.3

echo "INFO: Starting vmdebootstrap..."
vmdebootstrap \
    --verbose \
    --arch arm64 \
    --distribution buster \
    --image "$IMAGE" \
    --size 2500M \
    --roottype ext4 \
    --bootsize 128M \
    --boottype vfat \
    --lock-root-password \
    --sudo \
    --user ${NEW_USER}/${NEW_USER} \
    --enable-dhcp \
    --log=bootstrap.log \
    --log-level=debug \
    --log-keep=1 \
    --verbose \
    --owner=${SUDO_USER} \
    --no-kernel \
    --no-extlinux \
    --no-acpid \
    --hostname raspbian \
    --foreign /usr/bin/qemu-aarch64-static \
    --debootstrapopts="keyring=$SOURCEDIR/signatures/release-10.asc" \
    --package netbase \
    --customize $(dirname $0)/customize_64.sh

$(dirname $0)/autosizer.sh "$IMAGE" 50
