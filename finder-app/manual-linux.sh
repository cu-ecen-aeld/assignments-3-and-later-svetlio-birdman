#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -x
set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]; then
    echo "Using default directory ${OUTDIR} for output"
else
    OUTDIR=$(realpath $1)
    echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p "${OUTDIR}"

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux" ]; then
    # Clone only if the repository does not exist.
    echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
    git clone "${KERNEL_REPO}" --depth 1 --single-branch --branch "${KERNEL_VERSION}"
fi
if [ ! -e "${OUTDIR}/linux/arch/${ARCH}/boot/Image" ]; then
    cd linux
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout "${KERNEL_VERSION}"

    # TODO: Add your kernel build steps here
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig 
    make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all
    make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules
    make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs

fi

cp "${OUTDIR}/linux/arch/${ARCH}/boot/Image" "${OUTDIR}/Image" 

echo "Adding the Image in outdir"

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]; then
    echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm -rf "${OUTDIR}/rootfs"
fi

# TODO: Create necessary base directories
mkdir rootfs
cd rootfs
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log


cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]; then
    git clone git://busybox.net/busybox.git
    cd busybox
    git checkout "${BUSYBOX_VERSION}"
    # TODO: Configure busybox
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} distclean
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
else
    cd busybox
fi

# TODO: Make and install busybox
make distclean
make defconfig
make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX=${OUTDIR}/rootfs ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install
# make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} #-j$(nproc)
# make CONFIG_PREFIX="${OUTDIR}/rootfs" ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

echo "Library dependencies"
${CROSS_COMPILE}readelf -a "${OUTDIR}/rootfs/bin/busybox" | grep "program interpreter"
${CROSS_COMPILE}readelf -a "${OUTDIR}/rootfs/bin/busybox" | grep "Shared library"



# TODO: Add library dependencies to rootfs
cd $(dirname $(which ${CROSS_COMPILE}gcc))
cd ../aarch64-none-linux-gnu/libc
cp lib64/ld-2.31.so ${OUTDIR}/rootfs/lib64/
cp lib64/libm.so.6 ${OUTDIR}/rootfs/lib64/
cp lib64/libresolv.so.2 ${OUTDIR}/rootfs/lib64/
cp lib64/libc.so.6 ${OUTDIR}/rootfs/lib64/
cd ${OUTDIR}/rootfs/lib
ln -s ../lib64/ld-2.31.so ld-linux-aarch64.so.1

# TODO: Make device nodes
cd ${OUTDIR}/rootfs
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 620 dev/console c 5 1

# TODO: Clean and build the writer utility
cd /home/svetoslav/Documents/linux_assignments/assignment-2-svetlio-birdman/finder-app
make clean
make CROSS_COMPILE=${CROSS_COMPILE} -j4 writer


# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cp writer ${OUTDIR}/rootfs/home/
cp finder.sh ${OUTDIR}/rootfs/home/
cp finder-test.sh ${OUTDIR}/rootfs/home/
# Modify the finder-test.sh to reference conf/assignment
sed -i 's/\.\.\/conf/conf/g' ${OUTDIR}/rootfs/home/finder-test.sh
cp -r ../conf ${OUTDIR}/rootfs/home/conf
cp autorun-qemu.sh ${OUTDIR}/rootfs/home/


# TODO: Chown the root directory
cd ${OUTDIR}/rootfs
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio

# TODO: Create initramfs.cpio.gz
# cd "${OUTDIR}/rootfs"
# find .| cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio.gz
cd $OUTDIR
gzip -f initramfs.cpio



# !/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

# set -e
# set -u

# OUTDIR=/tmp/aeld
# KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
# KERNEL_VERSION=v5.1.10
# BUSYBOX_VERSION=1_33_1
# FINDER_APP_DIR=$(realpath $(dirname $0))
# ARCH=arm64
# CROSS_COMPILE=aarch64-none-linux-gnu-

# if [ $# -lt 1 ]
# then
#     echo "Using default directory ${OUTDIR} for output"
# else
#     OUTDIR=$1
#     echo "Using passed directory ${OUTDIR} for output"
# fi

# mkdir -p ${OUTDIR}

# cd "$OUTDIR"
# if [ ! -d "${OUTDIR}/linux-stable" ]; then
#     #Clone only if the repository does not exist.
#     echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
#     git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
# fi
# if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
#     cd linux-stable
#     echo "Checking out version ${KERNEL_VERSION}"
#     git checkout ${KERNEL_VERSION}

#     # deep clean kernel build tree
#     make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
#     # Use provided configuration for 'virt' arm dev board
#     make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
#     # build kernel image for QEMU
#     make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all
#     # Skip building modules to avoid too large kernel to fit in the initramfs with default memory.
#     make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules
#     # build device tree
#     make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs
# fi

# echo "Adding the Image in outdir"
# cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}

# echo "Creating the staging directory for the root filesystem"
# cd "$OUTDIR"
# if [ -d "${OUTDIR}/rootfs" ]
# then
#     echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
#     sudo rm  -rf ${OUTDIR}/rootfs
# fi

# # Create necessary base directories
# ROOTFS="${OUTDIR}/rootfs/"
# mkdir -p ${ROOTFS}/bin
# mkdir -p ${ROOTFS}/dev
# mkdir -p ${ROOTFS}/etc
# mkdir -p ${ROOTFS}/home
# mkdir -p ${ROOTFS}/lib
# mkdir -p ${ROOTFS}/lib64
# mkdir -p ${ROOTFS}/proc
# mkdir -p ${ROOTFS}/sbin
# mkdir -p ${ROOTFS}/sys
# mkdir -p ${ROOTFS}/tmp
# mkdir -p ${ROOTFS}/var
# mkdir -p ${ROOTFS}/usr/bin
# mkdir -p ${ROOTFS}/usr/lib
# mkdir -p ${ROOTFS}/usr/sbin
# mkdir -p ${ROOTFS}/var/log

# cd ${OUTDIR}
# if [ ! -d "${OUTDIR}/busybox" ]
# then
# git clone git://busybox.net/busybox.git
#     cd busybox
#     git checkout ${BUSYBOX_VERSION}
#     # Configure busybox
#     make distclean
#     make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
# else
#     cd busybox
# fi

# # Make and install busybox
# make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
# make CONFIG_PREFIX=${OUTDIR}/rootfs ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

# cd "$OUTDIR/rootfs"
# echo "Library dependencies"
# ${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
# ${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"


# # Add library dependencies to rootfs
# SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)
# cp ${SYSROOT}/lib/ld-linux-aarch64.so.1 ${ROOTFS}/lib
# cp ${SYSROOT}/lib/ld-linux-aarch64.so.1 lib64
# cp ${SYSROOT}/lib64/libm.so.6 ${ROOTFS}/lib64
# cp ${SYSROOT}/lib64/libresolv.so.2 ${ROOTFS}/lib64
# cp ${SYSROOT}/lib64/libc.so.6 ${ROOTFS}/lib64

# # Make device nodes
# sudo mknod -m 666 ${ROOTFS}/dev/null c 1 3
# sudo mknod -m 600 ${ROOTFS}/dev/console c 5 1

# # Clean and build the writer utility
# # make clean -C ${FINDER_APP_DIR}
# make CROSS_COMPILE=${CROSS_COMPILE} -C ${FINDER_APP_DIR} writer

# # Copy the finder related scripts and executables to the /home directory
# # on the target rootfs
# cp ${FINDER_APP_DIR}/autorun-qemu.sh ${ROOTFS}/home
# cp ${FINDER_APP_DIR}/dependencies.sh ${ROOTFS}/home
# cp ${FINDER_APP_DIR}/finder-test.sh ${ROOTFS}/home
# cp ${FINDER_APP_DIR}/finder.sh ${ROOTFS}/home
# cp ${FINDER_APP_DIR}/writer ${ROOTFS}/home
# cp ${FINDER_APP_DIR}/writer.c ${ROOTFS}/home
# cp ${FINDER_APP_DIR}/writer.sh ${ROOTFS}/home
# cp ${FINDER_APP_DIR}/Makefile ${ROOTFS}/home
# mkdir ${ROOTFS}/home/conf
# cp ${FINDER_APP_DIR}/conf/username.txt ${ROOTFS}/home/conf
# cp ${FINDER_APP_DIR}/conf/assignment.txt ${ROOTFS}/home/conf


# # Chown the root directory
# sudo chown -R root:root ${ROOTFS}

# # Create initramfs.cpio.gz
# cd ${ROOTFS}
# find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
# gzip -f ${OUTDIR}/initramfs.cpio