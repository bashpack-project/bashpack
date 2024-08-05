#!/bin/bash

# MIT License

# Copyright (c) 2024 Geoffrey Gontard

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.




# General informations
# This file permit to test if the current installation is working or not.
# It can be used in two ways:
# - from the main installed CLI
# - directly by calling the script from the cloned repository

# To do :
#	- Create a test that ensure "bp -i", "bp -u" and "bp --self-delete" is working as expected



# Testing if the exported variables from the main CLI are empty.
# This permit to use the value from: 
# - sudo bp -t					(= installed CLI)
# - sudo /usr/local/sbin/bp -t	(= installed CLI)
# - sudo ./bashpack.sh -t		(= cloned repository)
# - sudo ./commands/tests.sh	(= cloned repository)
if [[ $NAME = "" ]]; then
	NAME="Bashpack"
fi

if [[ $NAME_LOWERCASE = "" ]]; then
	NAME_LOWERCASE=$(echo "$NAME" | tr A-Z a-z)
fi

if [[ $NAME_ALIAS = "" ]]; then
	NAME_ALIAS="bp"
fi



dir_bin="/usr/local/sbin"
dir_src="/usr/local/src/$NAME_LOWERCASE"
dir_systemd="/lib/systemd/system"
dir_config="/etc/$NAME_LOWERCASE"
if [[ $(exists_command "pkg-config") = "exists" ]]; then
	dir_autocompletion="$(pkg-config --variable=compatdir bash-completion)"
else
	dir_autocompletion="/etc/bash_completion.d"
fi


# "Core"	-> means that the CLI can't be installed, uninstalled or updated without it.
# "Other"	-> means that the CLI can be installed, uninstalled or updated without it.
# (the update process must handle a clean installation by deleting or creating right files at right places).
directories_core=(
	$dir_bin
)
directories_other=(
	$dir_src
	$dir_systemd
	$dir_config
	$dir_autocompletion
)
files_core=(
	"$dir_bin/$NAME_LOWERCASE"
	"$dir_bin/bp"
)
files_other=(
	"$dir_autocompletion/$NAME_LOWERCASE"
	"$dir_systemd/$NAME_LOWERCASE-updates.service"
	"$dir_systemd/$NAME_LOWERCASE-updates.timer"
	"$dir_config/.current_publication"
	"$dir_config/"$NAME_LOWERCASE"_config"
)




# Permit to check if files exist or not
check_files() {

	local number_core_found=0
	local number_core_notfound=0

	local number_other_found=0
	local number_other_notfound=0
	
	echo ">>> Verifying files"

	# Core directories
	for directory in "${directories_core[@]}"; do
		if [ -d $directory ]; then
			echo "[dir]  Found		-> $directory"
			number_core_found=$((number_core_found+1))
		else
			echo "[dir]  Not found	-> $directory"
			number_core_notfound=$((number_core_notfound+1))
		fi
	done
	
	# Other directories
	for directory in "${directories_other[@]}"; do
		if [ -d $directory ]; then
			echo "[dir]  Found		-> $directory"
			number_other_found=$((number_other_found+1))
		else
			echo "[dir]  Not found	-> $directory"
			number_other_notfound=$((number_other_notfound+1))
		fi
	done

	# Core files
	for file in "${files_core[@]}"; do
		if [ -f $file ]; then
			echo "[file] Found		-> $file"
			number_core_found=$((number_core_found+1))
		else
			echo "[file] Not found	-> $file"
			number_core_notfound=$((number_core_notfound+1))
		fi
	done

	# Other files
	for file in "${files_other[@]}"; do
		if [ -f $file ]; then
			echo "[file] Found		-> $file"
			number_other_found=$((number_other_found+1))
		else
			echo "[file] Not found	-> $file"
			number_other_notfound=$((number_other_notfound+1))
		fi
	done


	number_core_total=$((${#directories_core[@]}+${#files_core[@]}))
	number_other_total=$((${#directories_other[@]}+${#files_other[@]}))


	echo ""
	echo "Core	-> found: $number_core_found/$number_core_total	| not found: $number_core_notfound"
	echo "Other	-> found: $number_other_found/$number_other_total	| not found: $number_other_notfound"


	if [ $number_core_notfound -gt 0 ]; then
		echo ""
		echo "Error: missing core file(s). A reinstallation is required (https://github.com/bashpack-project/bashpack?tab=readme-ov-file#quick-start)"
	elif [ $number_other_notfound -gt 0 ]; then
		echo ""
		echo "Error: core file(s) are working, but some features are not working as expected. 'sudo bp -i' should solve the issue (if not, you can open an issue at https://github.com/bashpack-project/bashpack/issues)"
	else
		echo ""
		echo "Success! Current installation is working as expected."
	fi
}




check_download() {

	local not_found=0

	echo ">>> Verifying download"
	echo "Attempting to download and extract archive from $URL"


	# Verification : download and extract latest available tarball
	echo ""
	echo "Verification 1 -> Latest tarball"
	download_cli "$URL/tarball" $archive_tmp $archive_dir_tmp
	
	if [[ -f $archive_tmp ]]; then
		echo "Success! Verification passed. $archive_tmp found."
	else
		not_found=$((not_found+1))
		echo "Error: verification failed. $archive_tmp not found."
	fi
	
	if [[ -d $archive_dir_tmp ]]; then
		echo "Success! Verification passed. $archive_dir_tmp found."
	else
		not_found=$((not_found+1))
		echo "Error: verification failed. $archive_dir_tmp not found."
	fi

	# Cleaning files to prepare next verifications.
	rm -rf $archive_tmp
	rm -rf $archive_dir_tmp



	# Verification : download and extract given version tarball
	echo ""
	echo "Verification 2 -> $VERSION tarball"
	download_cli "$URL/tarball/$VERSION" $archive_tmp $archive_dir_tmp
	
	if [[ -f $archive_tmp ]]; then
		echo "Success! Verification passed. $archive_tmp found."
	else
		not_found=$((not_found+1))
		echo "Error: verification failed. $archive_tmp not found."
	fi
	
	if [[ -d $archive_dir_tmp ]]; then
		echo "Success! Verification passed. $archive_dir_tmp found."
	else
		not_found=$((not_found+1))
		echo "Error: verification failed. $archive_dir_tmp not found."
	fi

	# Cleaning files to prepare next verifications.
	rm -rf $archive_tmp
	rm -rf $archive_dir_tmp


	if [ $not_found -gt 0 ]; then
		echo ""
		echo "Error: $not_found download verification(s) not working as expected."
	else
		echo ""
		echo "Success! Download functions are working as expected."
	fi
}



if [[ $function_to_launch = "check_all" ]]; then
	check_files
	
	echo ""
	check_download
fi

if [[ $function_to_launch = "check_files" ]]; then
	check_files
fi

if [[ $function_to_launch = "check_download" ]]; then
	check_download
fi




# Properly exit
exit

#EOF