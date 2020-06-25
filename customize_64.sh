#!/bin/bash -e

NEW_USER="pi"

TOMCAT_VERSION=9.0.36
TOMCAT_FILE=apache-tomcat-9.0.36.tar.gz
TOMCAT_URL=https://downloads.apache.org/tomcat/tomcat-9/v9.0.36/bin/apache-tomcat-9.0.36.tar.gz

WIRING_PI_VERSION=2.60
WIRING_PI_DEB=wiringpi-2.60-1_arm64.deb

JAVA_VERSION=11.0.6+10
JAVA_DEB=bellsoft-jdk11.0.6+10-linux-aarch64.deb
JAVA_URL=https://download.bell-sw.com/java/11.0.6+10/bellsoft-jdk11.0.6+10-linux-aarch64.deb

SOURCEDIR="$(cd ${0%/*} ; pwd)"
ROOTDIR="$1"

# Do not start services during installation.
echo exit 101 > ${ROOTDIR}/usr/sbin/policy-rc.d
chmod +x ${ROOTDIR}/usr/sbin/policy-rc.d

export LANG=POSIX


# Configure apt.
echo
echo "INFO: Configuring APT..."
export DEBIAN_FRONTEND=noninteractive
mkdir -p ${ROOTDIR}/etc/apt/sources.list.d/
mkdir -p ${ROOTDIR}/etc/apt/apt.conf.d/
echo "Acquire::http { Proxy \"http://localhost:3142\"; };" > ${ROOTDIR}/etc/apt/apt.conf.d/50apt-cacher-ng
#cp ${SOURCEDIR}/etc/apt/sources_64.list ${ROOTDIR}/etc/apt/sources.list
cp ${SOURCEDIR}/etc/apt/apt.conf.d/50raspi ${ROOTDIR}/etc/apt/apt.conf.d/50raspi
chroot ${ROOTDIR} apt-get update
chroot ${ROOTDIR} apt-get -y dist-upgrade
chroot ${ROOTDIR} apt-get clean -y
chroot ${ROOTDIR} apt-get autoclean -y
chroot ${ROOTDIR} apt-get autoremove -y


# configure locale
echo
echo "INFO: Configuring locale..."
chroot ${ROOTDIR} apt-get install -y locales tzdata
cp ${SOURCEDIR}/etc/default/locale ${ROOTDIR}/etc/default/locale
cp ${SOURCEDIR}/etc/default/keyboard ${ROOTDIR}/etc/default/keyboard
cp ${SOURCEDIR}/etc/locale.gen ${ROOTDIR}/etc/locale.gen
chroot ${ROOTDIR} locale-gen
TIMEZONE="Europe/Zurich"
echo $TIMEZONE > ${ROOTDIR}/etc/timezone
ln -sf /usr/share/zoneinfo/${TIMEZONE} ${ROOTDIR}/etc/localtime


# Install packages
echo
echo "INFO: Installing packages..."
chroot ${ROOTDIR} apt-get --no-install-recommends install -y \
	anacron \
	apt-utils \
	bash-completion \
	byobu \
	python-cliapp \
	binutils \
	bzip2 \
	console-data \
	ca-certificates \
	cron-apt \
	curl \
	debian-keyring \
	debian-archive-keyring \
	dbus \
	dhcpcd5 \
	dirmngr \
	fail2ban \
	fake-hwclock \
	git \
	i2c-tools \
	ifupdown \
	iptables \
	iputils-ping \
	isc-dhcp-client \
	kbd \
	kmod \
	less \
	libapr1 \
	locales \
	man-db \
	nano \
	needrestart \
	net-tools \
	netbase \
	ntp \
	ntpdate \
	openssh-server \
	owfs \
	parted \
	python-ow \
	rng-tools \
	rsync \
	uuid-runtime \
	unzip \
	vim \
	wget

chroot ${ROOTDIR} apt-get autoclean -y
chroot ${ROOTDIR} apt-get autoremove -y


# Install Java
echo
echo "INFO: Downloading JDK ${JAVA_VERSION}..."
if [[ ! -f ${JAVA_DEB} ]] ; then
	echo "INFO: Downloading JDK ${JAVA_VERSION} from ${JAVA_URL}..."
	if ! wget --quiet --continue -O ${SOURCEDIR}/debs64/${JAVA_DEB} ${JAVA_URL} ; then
		echo "ERROR: Failed to download JDK!"
	fi
else
    echo "INFO: JDK ${JAVA_VERSION} already downloaded."
fi

echo "INFO: Installing Java deb ${JAVA_DEB}"
mkdir -p ${ROOTDIR}/opt/downloads
cp ${SOURCEDIR}/debs64/${JAVA_DEB} ${ROOTDIR}/opt/downloads/
chroot ${ROOTDIR} apt-get --no-install-recommends install -y libasound2 libfreetype6 libx11-6 libxau6 libxcb1 libxdmcp6 libxext6 libxi6 libxrender1 libxtst6
chroot ${ROOTDIR} apt-get autoclean -y
chroot ${ROOTDIR} apt-get autoremove -y
chroot ${ROOTDIR} dpkg -i /opt/downloads/${JAVA_DEB}
rm ${ROOTDIR}/opt/downloads/${JAVA_DEB}
echo "INFO: JDK ${JAVA_VERSION} installed."


# Configuring boot
echo
echo "INFO: Configuring boot..."
cp ${SOURCEDIR}/boot/cmdline_64.txt ${ROOTDIR}/boot/cmdline.txt
cp ${SOURCEDIR}/boot/config_64.txt ${ROOTDIR}/boot/config.txt
cp ${SOURCEDIR}/etc/default/* ${ROOTDIR}/etc/default/
cp ${SOURCEDIR}/etc/fstab ${ROOTDIR}/etc/fstab
cp ${SOURCEDIR}/etc/modules ${ROOTDIR}/etc/modules
cp ${SOURCEDIR}/etc/network/iptables.rules ${ROOTDIR}/etc/network/iptables.rules
cp ${SOURCEDIR}/etc/rc.local ${ROOTDIR}/etc/rc.local
ln -fs /dev/null ${ROOTDIR}/etc/systemd/network/99-dhcp.network
chmod a+x ${ROOTDIR}/etc/rc.local


# Install kernel.
echo
echo "INFO: Installing kernel..."
${SOURCEDIR}/install-kernel-64.sh ${ROOTDIR}


# Regenerate SSH host keys on first boot.
echo
echo "INFO: Deleting generated SSH host keys..."
chroot ${ROOTDIR} apt-get install -y 
rm -f ${ROOTDIR}/etc/ssh/ssh_host_*
mkdir -p ${ROOTDIR}/etc/systemd/system
cp ${SOURCEDIR}/etc/systemd/system/regen-ssh-keys.service ${ROOTDIR}/etc/systemd/system/regen-ssh-keys.service
chroot ${ROOTDIR} systemctl enable regen-ssh-keys


# Raspberry Pi features.
echo
echo "INFO: Configuring Raspberry Pi features..."

# get raspi-config
echo "INFO: Cloning raspi-config..."
cd ${ROOTDIR}/opt/
git clone https://github.com/RPi-Distro/raspi-config.git

# configure non-root interfaces
echo "INFO: Adding special groups..."
chroot ${ROOTDIR} groupadd --force gpio
chroot ${ROOTDIR} groupadd --force i2c
chroot ${ROOTDIR} groupadd --force spi

echo "INFO: Adding udev rules..."
cp ${SOURCEDIR}/etc/udev/rules.d/99-com.rules ${ROOTDIR}/etc/udev/rules.d/99-com.rules

# copy binaries
echo "INFO: Copying special binaries..."
mkdir -p ${ROOTDIR}/usr/local/bin
cp ${SOURCEDIR}/bin-files64/* ${ROOTDIR}/usr/local/bin/
chmod u+s ${ROOTDIR}/usr/local/bin/pwm
chmod u+s ${ROOTDIR}/usr/local/bin/i2c_get_clkt_tout
chmod u+s ${ROOTDIR}/usr/local/bin/i2c_set_clkt_tout
cd ${SOURCEDIR}


# WiringPi
echo
echo "INFO: Installing wiringPi ${WIRING_PI_VERSION}"
mkdir -p ${ROOTDIR}/opt/downloads
cp ${SOURCEDIR}/debs64/${WIRING_PI_DEB} ${ROOTDIR}/opt/downloads/
chroot ${ROOTDIR} dpkg -i /opt/downloads/${WIRING_PI_DEB}
rm ${ROOTDIR}/opt/downloads/${WIRING_PI_DEB}
echo "INFO: wiringPi ${WIRING_PI_VERSION} installed."


# Configure OWFS
echo
echo "INFO: Configuring OWFS..."
cp ${SOURCEDIR}/etc/owfs.conf ${ROOTDIR}/etc/owfs.conf
mkdir -p ${ROOTDIR}/mnt/1wire0
chroot ${ROOTDIR} systemctl disable owftpd
chroot ${ROOTDIR} systemctl disable owhttpd


# Configure user
echo
echo "INFO: Configuring User ${NEW_USER}..."
chroot ${ROOTDIR} usermod ${NEW_USER} --append --groups i2c,spi,gpio,dialout


# Create a swapfile.
echo
echo "INFO: Creating SWAP file..."
dd if=/dev/zero of=${ROOTDIR}/var/swapfile bs=1M count=512
chroot ${ROOTDIR} chmod 600 /var/swapfile
chroot ${ROOTDIR} mkswap /var/swapfile
echo /var/swapfile none swap sw 0 0 >> ${ROOTDIR}/etc/fstab


# Tomcat preparations
echo
echo "INFO: Preparing Apache Tomcat ${TOMCAT_VERSION}..."
if [[ ! -f ${TOMCAT_FILE} ]] ; then
	echo "INFO: Downloading Apache Tomcat..."
	if ! wget --quiet -O ${SOURCEDIR}/${TOMCAT_FILE} ${TOMCAT_URL} ; then
		echo "ERROR: Failed to download Tomcat!"
	fi
fi
tar -xzf ${TOMCAT_FILE}
rm -rf apache-tomcat-${TOMCAT_VERSION}/webapps/{docs,examples,host-manager,manager}
mv apache-tomcat-${TOMCAT_VERSION} ${ROOTDIR}/opt/
cd ${ROOTDIR}/opt/
ln -s apache-tomcat-${TOMCAT_VERSION} tomcat

cp ${SOURCEDIR}/tomcat-setenv.sh ${ROOTDIR}/opt/tomcat/bin/setenv.sh

echo
echo "INFO: Preparing directories..."
chroot ${ROOTDIR} chown -R ${NEW_USER}:${NEW_USER} /opt/downloads
chroot ${ROOTDIR} chown -R ${NEW_USER}:${NEW_USER} /opt/apache-tomcat-${TOMCAT_VERSION}
chroot ${ROOTDIR} chown -R ${NEW_USER}:${NEW_USER} /opt/tomcat


# Done.
echo
echo "INFO: Cleaning up..."
chroot ${ROOTDIR} apt-get clean -y
chroot ${ROOTDIR} apt-get autoclean -y
chroot ${ROOTDIR} apt-get autoremove -y
rm ${ROOTDIR}/usr/sbin/policy-rc.d
rm ${ROOTDIR}/etc/apt/apt.conf.d/50apt-cacher-ng
echo "INFO: Done."
echo
echo
