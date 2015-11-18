#!/bin/bash

# Bash Color
green='\033[01;32m'
red='\033[01;31m'
blink_red='\033[05;31m'
restore='\033[0m'

clear

# Resources
THREAD="-j$(grep -c ^processor /proc/cpuinfo)"
KERNEL="Image"
DTBIMAGE="dt.img"
DEFCONFIG="cm_oneplus2_defconfig"
KERNEL_DIR=`pwd`
RESOURCE_DIR="$KERNEL_DIR/../VisionX"
ANYKERNEL_DIR="$RESOURCE_DIR/H815"
TOOLCHAIN_DIR="$KERNEL_DIR/.."

# Kernel Details
BASE_VI_VER="VisionX"
DEVICE_NAME="-OP2"
VER="-0.0"
VI_VER="$BASE_VI_VER$DEVICE_NAME$VER"

# Vars
export LOCALVERSION=~`echo $VI_VER`
export CROSS_COMPILE="$TOOLCHAIN_DIR/toolchain/aarch64-linux-android-4.9/bin/aarch64-linux-android-"
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER=AuxXxilium
export KBUILD_BUILD_HOST=VisionX

# Paths
REPACK_DIR="$ANYKERNEL_DIR/out"
PATCH_DIR="$ANYKERNEL_DIR/patch"
MODULES_DIR="$REPACK_DIR/modules"
ZIP_MOVE="$RESOURCE_DIR/release/"
ZIMAGE_DIR="$KERNEL_DIR/arch/arm64/boot"

# Functions
function clean_all {
		echo; ccache -c -C echo;
		if [ -f "$MODULES_DIR/*.ko" ]; then
			rm `echo $MODULES_DIR"/*.ko"`
		fi
		cd $REPACK_DIR
		rm -rf $KERNEL
		rm -rf $DTBIMAGE
		git reset --hard > /dev/null 2>&1
		git clean -f -d > /dev/null 2>&1
		cd $KERNEL_DIR
		echo
		make clean && make mrproper
}

function make_kernel {
		echo
		make $DEFCONFIG
		make $THREAD
		cp -vr $ZIMAGE_DIR/$KERNEL $ANYKERNEL_DIR/ramdisk/kernel
}

function make_modules {
		if [ -f "$MODULES_DIR/*.ko" ]; then
			rm `echo $MODULES_DIR"/*.ko"`
		fi
		#find $TOOLCHAIN_DIR/proprietary -name '*.ko' -exec cp -v {} $MODULES_DIR \;
		find $KERNEL_DIR -name '*.ko' -exec cp -v {} $MODULES_DIR \;
}

function make_dtb {
		$ANYKERNEL_DIR/tools/dtbtool -o $ANYKERNEL_DIR/ramdisk/$DTBIMAGE -s 4096 -p scripts/dtc/ arch/arm64/boot/dts/
}

function make_zip {
		cd $ANYKERNEL_DIR/tools
		./mkboot $ANYKERNEL_DIR/ramdisk $REPACK_DIR/boot.img
		cd $REPACK_DIR
		zip -x@zipexclude -r9 `echo $VI_VER`.zip *
		mv  `echo $VI_VER`.zip $ZIP_MOVE
		cd $KERNEL_DIR
		rm -rf $REPACK_DIR/boot.img
		rm -rf $ANYKERNEL_DIR/ramdisk/dt.img
		rm -rf $ANYKERNEL_DIR/ramdisk/kernel
}


DATE_START=$(date +"%s")

echo -e "${green}"
echo "Kernel Creation Script:"
echo ""
echo

echo "---------------"
echo "Kernel Version:"
echo "---------------"

echo -e "${red}"; echo -e "${blink_red}"; echo "$VI_VER"; echo -e "${restore}";

echo -e "${green}"
echo "-----------------"
echo "Making Kernel:"
echo "-----------------"
echo -e "${restore}"

while read -p "Do you want to clean stuffs (y/n)? " cchoice
do
case "$cchoice" in
	y|Y )
		clean_all
		echo
		echo "All Cleaned now."
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done

echo

while read -p "Do you want to build kernel (y/n)? " dchoice
do
case "$dchoice" in
	y|Y)
		make_kernel
		make_dtb
		#make_modules
		#make_zip
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done

echo -e "${green}"
echo "-------------------"
echo "Build Completed in:"
echo "-------------------"
echo -e "${restore}"

DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo "Time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
echo

