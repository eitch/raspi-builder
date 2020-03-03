# Raspberry Pi Image builder

This repository contains scripts to build a Raspberry Image from scratch.

Currently it is focused on Raspberry Pi 4 with a 64-bit architecture with the following features built-in:
* Based on Debian Stretch
* Latest Kernel build from https://github.com/raspberrypi/linux.git
  * This includes building a GCC tool chain from https://ftp.gnu.org/gnu/binutils and GCC from https://ftp.gnu.org/gnu/gcc
* WiringPi 2.50 installed
* Java 11
* Apache Tomcat 9
* Prepared for I2C, 1-Wire over I2C and GPIO usage
* Basic Firewall (Deny all but 22, 8080, 443, 5353 and ICMP)

# Usage

Usage is simple:
* Clone this repository
* Change the default username of `pi` of the `NEW_USER` variable in the following files to suit your needs:
  * bootstrap_rpi4.sh
  * customize_rpi4.sh
  * etc/rc.local
* Customize the `customize_rpi4.sh` script anyhow you see fit 
* Run the script as `sudo ./bootstrap_rpi4.sh`
* After bulding, you will have a new file called `raspbian-rpi4_arm64-<date>.img`

**Note:** The initial build will take a long time, as it downloads the Kernel sources, tool chain and GCC and builds them all. Depending on the powerfulness of your system, you might want to modify the `JOBS` variable in `install-kernel-rpi4.sh`.

# Issues

There is a bug where on an Ubuntu/Debian system the vmdebootstrap script might fail as it was not designed to build 64-bit ARM images. The workaround is to patch the script as follows:

    sudo vi /usr/lib/python2.7/dist-packages/vmdebootstrap/constants.py
    ---
    vmdebootstrap/constants.py | 2 +-
    1 file changed, 1 insertion(+), 1 deletion(-)

    diff --git a/vmdebootstrap/constants.py b/vmdebootstrap/constants.py
    index 9f39415..3d807c6 100644
    --- a/vmdebootstrap/constants.py
    +++ b/vmdebootstrap/constants.py
    @@ -46,7 +46,7 @@ arch_table = {  # pylint: disable=invalid-name
             'package': 'grub-efi-arm64',
             'bin_package': 'grub-efi-arm64-bin',
             'extra': None,
    -        'exclusive': True,
    +        'exclusive': False,
             'target': 'arm64-efi',
         }
     }
    --
    2.9.3

# Resources

These scripts were built with help from:
* https://github.com/niklasf/build-raspbian-image
* https://blog.cloudkernels.net/posts/rpi4-64bit-image/
