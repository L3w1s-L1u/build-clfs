#! /bin/bash
# ==================== Utilities Library ===================================   
# Functions: 	extract source
#		patch source
#		check target generated	 
#
# These utilities require below variables been set in order to work correctly
#		SRC: folder that contains your clfs source tarballs
#		CLFS: top dir for building clfs
#		PATH: system PATH environment variable
# ==========================================================================

# extract source from tarball, must specify the source name first, e.g. binutils, gcc-4.7.3, etc.
# arglist: $1  keyword of source currently extracting
#	   $2  destination folder extracted to, default: current working dir
# return:  0 for OK, 1 for error
extract_src()
{
	if [ ! -n $1 ];then
		echo "No build target source name specified. Do nothing."
		exit 1
	fi
	if [ -d $SRC ];then
		# grep source folder to find the build target source tarball, ignore case
		local srclist=`ls ${SRC} |grep -i "$1"`
		local found=0
		local tar_t
		for tarfile in ${srclist}
		do
			tar_t=`file ${SRC}/${tarfile}|egrep -o 'bzip2|gzip'`
			echo $tar_t
			if [ X${tar_t} = "Xbzip2" ];then
				untar='jxf'
				found=$[$found + 1]
			elif [ X${tar_t} = "Xgzip" ];then
				untar='zxf' 
				found=$[$found + 1]
			fi
		done
		echo "Found $found source file, extracting..."
		if [ $found -eq 1 ];then
			local dst=$2
			tar $untar ${SRC}/${tarfile} -C ${dst:-.} 
		elif [ $found -gt 1 ];then
			echo "Found more than one binutils source. Please delete unwanted one and retry."
			exit 1
		else
			echo "No binutils source found. Only bzip2 and gzip supprted. Do nothing."
			exit 1
		fi
	else
		echo "No source folder found. Please specify the directory contains $1 tarball."
		exit 1
	fi
}

# patch the source file
# arglist: $1	keyword of source currently patching, e.g. binutils, gcc, busybox, etc.	
#	   $2 	staging folder contains sources which need patching	
# return:  ${src_dir} if OK, 1 if error
patching_src()
{
	if [ ! -n ${SRC} ];then
		echo "No source folder found. Did you hooked up your setup_env.sh?"
		exit 1
	fi
	src_list=`ls $2 |grep -i "$1"`
	if [ ! -n ${src_list} ];then
		echo "No $1 source found in $2. Please check if your source has been extracted."
		exit 1
	fi

	local dir_cnt=0
	for src_dir in src_list 
	do
		if [ -d ${src_dir} ];then
			dir_cnt=$[${dir_cnt} + 1] 
		fi 
	done

	if [ ${dir_cnt} -gt 1 ];then
		echo "Found more than one $1 source folder in $2, please remove unwanted one and retry."
		exit 1
	fi
	# stripping off the path from the source dir name
	dir_name=${src_dir##/*/}
	# stripping off the version suffix of the dir name
	# version pattern: three group of digits seperated by '.', leading by '-', 
	#other version pattern will be ignored
	src_name=${dir_name%%\-[0-9]*\.[0-9]*\.[0-9]*}
	patch_files=`find $SRC -name "*${src_name}*.patch"`

	if [ ! -n ${patch_files} ];then
		echo "No musl patch for ${src_name} found, please download patch file to $SRC first"
		exit 1
	fi
	# apply patch
	cd ${src_dir} 
	for patch_f in ${patch_files}
	do
		if [ -s ${patch_f} ];then
			patch -Np1 -i ${patch_f} 2>&1 |tee -a patch-${src_name}.log
			if [ ! $? ];then
				break
			fi
		else
			echo "Bad patch file: ${patch_f}, source NOT patched."
			break
		fi
	done
	if [ ! $? ];then
		echo "Apply patch failed. Please DO NOT repatch the source."
		echo "Succeeding process might fail due to incorrect musl patch."
	fi
	return ${src_dir}
}

# strip off version string
# arglist: $1 version string pattern, 
#	      default: "[0-9]\{1,2\}.[0-9]\{1,2\}.[0-9]\{1,2\}" 
#	      e.g. XX.YY.ZZ X.YY.Z X.Y.Z
#	   $2 source dir name which contains keywords and version string
# return:  version string if match, otherwise return 1 (fail) 
get_verstr()
{
	local dir=$1
	local pattern=$2

	if [ ! -d ${dir} ];then
		echo " No folder ${dir} found. Please select a correct tools folder."
		exit 1
	fi
	# grep out version number. If version pattern not set, use default	
	ver_string=`echo ${dir} |grep -o ${pattern:=[0-9]\{1,2\}.[0-9]\{1,2\}.[0-9]\{1,2\}}` 
	return ${ver_string:-1}
}

# check cross-tools generated
# arglist: $1 target triplets, see setup_env.sh set_target() for more details
#	   $2 cross-tools list	
#	   $3 version string, generated by get_verstr()
# return: 0 if OK, 1 if errors 
check_result()
{
	local target=$1
	local toollist=$2

	local binutils_lbl='(GNU Binutils)'
	# get binutils version string
	if [ -d ${tools_dir} ];then
		echo "No "
	ver=get_verstr  

	if [ ! -n ${target} ];then
		echo "No target triplets specified. Current cross target: ${CLFS_TARGET:?'Target not set'}" 
	elif [ ! -n ${toollist} ];then
		echo "No cross-tools list specified. Do nothing."
		exit 1
	fi
	for tool in ${toollist}
	do
		case ${tool} in
			# accept only "-V"
			'ar' |'nm' |'objcopy' |'strip')
			result=`${target}-${tool} -V |grep -o "GNU ${tool} ${binutils_lbl} ${ver}"`;; 
			
			# accept "-v"
			'addr2line' | 
			  'c++filt' | 
			  'elfedit' | 
			     'gcov' | 
			    'gprof' | 
			       'ld' | 
			   'ld.bfd' |
			  'objdump' )
				result=`${target}-${tool} -v |grep -o ${gnu_pattern}`;; 
		esac			
	done


}
