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




# General information
# This file permit to test if the current installation is working or not.
# It must be used within the main CLI file since most of the variables used here are declared in the main CLI file.


# To do :
#	- Create a test that ensure "bp -i", "bp -u" and "bp --self-delete" is working as expected
# 	- Create a test in case of "bp" or "bashpack" is not available and make this command useless




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
		echo "$NAME is working as expected !"
	fi
}




check_files




# Properly exit
exit

#EOF