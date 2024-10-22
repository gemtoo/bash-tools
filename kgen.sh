#!/bin/bash

source /etc/init.d/functions.sh

KCONFIG="/tmp/kernel-config.conf"
zcat /proc/config.gz > "${KCONFIG}" 

APPEND=$(grep "CONFIG_LOCALVERSION=" ${KCONFIG} | sed 's/^CONFIG_LOCALVERSION="//g;s/"$//g')
KVER=$(eselect kernel list | grep "*" | tr -s '[:space:]' | cut -d ' ' -f 3 | sed "s/linux-//")

checks () {
	if [ $(id -u) -eq 0 ]
		then
		ebegin "Running as root" && eend
		else
		eend "Please run this script as root user. Exiting."
		exit
	fi
	
	DEPS="eclean-kernel dracut zcat"
	for DEP in $DEPS; do
		ebegin "Checking for ${DEP}" && [ "$(command -v ${DEP})" ] ; eend $? || exit
	done

	ebegin "Checking whether a gentoo-kernel-bin is used"
	if [ "$(eselect kernel list | grep "\*" | grep -c dist)" -eq 0 ]; then
		eend $?
		ebegin "Checking if .config exists" && [ -f ${KCONFIG} ] ; eend $? || exit
		ebegin "Checking for a new kernel" && [ "$(eselect kernel list | wc -l)" -gt 2 ] ; eend $? || exit
		else
		eend $?
		exit
	fi
}

adapt() {
	ebegin "Entering source directory"
	cd /usr/src/linux
	eend $?
	
	ebegin "Running make mrproper"
	make mrproper 1> /dev/null
	eend $?
	
	ebegin "Adapting config"
	cp ${KCONFIG} $PWD/.config && make olddefconfig 1> /dev/null
	eend $?
}

build() {
	ebegin "Building the kernel"
	make -j$(nproc) V=1
	eend $?

	ebegin "Rebuilding modules"
	emerge @module-rebuild
	eend $?
	
	ebegin "Installing kernel modules"
	make -j$(nproc) modules_install
	eend $?
	
	ebegin "Mounting /boot"
	mount /boot
	eend $?

	ebegin "Installing kernel to /boot"
	make install
	eend $?
}

initramfs() {
	ebegin "Generating initramfs for ${KVER}${APPEND}"
	dracut --force --kver ${KVER}${APPEND}
	eend $?
	
	ebegin "Regenerating GRUB config"
	grub-mkconfig -o /boot/grub/grub.cfg
	eend $?
}

purgeold() {
	ebegin "Running eclean-kernel"
	eclean-kernel
	eend $?
	
	ebegin "Removing old kernels from /boot"
	cd /boot && rm -rf *old && rm -rf $(ls /boot | sed "s/EFI//;s/grub//" | sed "s|.*${KVER}${APPEND}.*||g" | sed '/^[[:space:]]*$/d')
	eend $?

	ebegin "Regenerating GRUB config"
	grub-mkconfig -o /boot/grub/grub.cfg
	eend $?
	
	ebegin "Removing deprecated kernel source code"
	cd /usr/src && rm -rf $(ls /usr/src | sed 's/^linux$//' | sed "s|.*${KVER}.*||g" | sed '/^[[:space:]]*$/d')
	eend $?	

	emerge --deselect sys-kernel/gentoo-kernel-bin
	emerge --depclean --verbose sys-kernel/gentoo-kernel-bin
}

checks && adapt && build && initramfs && purgeold
