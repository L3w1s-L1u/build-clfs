#! /bin/bash
# tools required: GNU Make; grep; find; patch
# check env
if [ ! -n ${CLFS} ];then
	echo "Environment not set. Did you include setup scripts in your .bashrc file?"
	exit 1
fi 

# include build utilities
. ${CLFS}/scripts/utils.sh

# Configure binutils
config_flags=" --prefix=${CLFS}/cross-tools \
--target=${CLFS_TARGET}  \
--with-sysroot=${SYSROOT} \
--disable-nls    \
--disable-multilib"
# unpatched source extracted to staging folder, waiting to be patched
if [ ! -d ${CLFS}/staging ];then
	mkdir ${CLFS}/staging 
fi

# extract source to staging dir
cd ${CLFS}/staging
extract_src binutils
if [ ! $? ];then
	echo "Seems extraction failed... please check your binutils tarball"
	rm -rvf ./binutils*
	exit 1
fi

# patch the source file
binutils_src=patch_src binutils ${CLFS}/staging

# configure binutils
if [ ! -d ${CLFS}/build_binutils ];then
	mkdir ${CLFS}/build_binutils
fi

cd ${CLFS}/build_binutils
../staging/${binutils_src}/configure ${config_flags}
if [ ! $? ];then
	echo "Config binutils failed. Please check config.log for more details"
	exit 1
fi

# Now make all defualt target
make configure-host && make && make install

# Check result
if [ ! $? ];then
	echo "Make return with errors. Please check error message for more details"
	exit 1
else
	echo "Binutils installed to ${CLFS}/cross-tools/bin"
	exit 0
fi
