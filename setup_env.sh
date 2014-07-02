
# TODO: expand this function to take at least one parameter which could be used to specify target CPU type
# Set up ARM Cortex-A8,9 target
set_target () 
{
	CLFS_FLOAT=hard
	CLFS_FPU=vfpv3-d16
	CLFS_HOST=$( echo ${MACHTYPE} |sed "s/-[^-]*/-cross/")
	CLFS_TARGET=arm-linux-musleabihf
	CLFS_ARCH=arm
	CLFS_ARM_ARCH=armv7-a
	export CLFS_FLOAT CLFS_FPU CLFS_HOST CLFS_TARGET CLFS_ARCH CLFS_ARM_ARCH
}
	

# Setup CLFS cross-compile environment
set +h
umask 022
CLFS=/srv/nfsroot/clfs
LC_ALL=POSIX
PATH=$PATH:$CLFS/cross-tools/bin
export CLFS LC_ALL PATH

# Clear GCC flags and set CLFS dirs: src cross-tools build, etc.
unset CFLAGS
unset CXXFLAGS
if [ -n ${CLFS} ]; then
	export SRC=${CLFS}/src

fi

set_target

if [ -n ${CLFS_TARGET} ];then
	export 	SYSROOT=${CLFS}/cross-tools/${CLFS_TARGET}
	mkdir -p ${SYSROOT}
	if [ ! -d ${SYSROOT}/usr  ];then
		echo "symbolic link ${SYSROOT}/usr created."
		ln -sfv . ${CLFS}/cross-tools/${CLFS_TARGET}/usr
	fi
	echo "SYSROOT: $SYSROOT"
else
	echo "No target specified, please specify your target CPU arch first!"
fi


