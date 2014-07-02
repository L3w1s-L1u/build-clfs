#! /bin/bash

source ../utils.sh

if [ ! -n $SRC ]; then
	echo "Env not initialized."
	exit 1
else
	echo "Test extracting to current folder..."
	extract_src binutils
	echo "Test extracting to $SRC folder ..."	
	extract_src binutils $SRC
fi
