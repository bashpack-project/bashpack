#!/bin/sh

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



. "core/helper.sh"




# General informations
# This file permit to test if the current installation is working or not.
# It can be used in two ways:
# - from the main installed CLI
# - directly by calling the script from the cloned repository

# To do :
#	- Create a test that ensure "bp -i", "bp -u" and "bp --self-delete" is working as expected



# # Testing if the exported variables from the main CLI are empty.
# # This permit to use the value from: 
# # - sudo bp verify					(= installed CLI)
# # - sudo /usr/local/sbin/bp verify	(= installed CLI)
# # - sudo ./bashpack.sh verify		(= cloned repository)
# # - sudo ./commands/tests.sh		(= cloned repository)
# if [ "$NAME" = "" ]; then
# 	NAME="Bashpack"
# fi

# if [ "$NAME_LOWERCASE" = "" ]; then
# 	NAME_LOWERCASE=$(echo "$NAME" | tr A-Z a-z)
# fi

# if [ "$NAME_ALIAS" = "" ]; then
# 	NAME_ALIAS="bp"
# fi



# dir_bin="/usr/local/sbin"
# dir_src="/usr/local/src/$NAME_LOWERCASE"
# dir_systemd="/lib/systemd/system"
# dir_config="/etc/$NAME_LOWERCASE"
# if [ $(exists_command "pkg-config") = "exists" ]; then
# 	dir_autocompletion="$(pkg-config --variable=compatdir bash-completion)"
# else
# 	dir_autocompletion="/etc/bash_completion.d"
# fi


# "Core"	-> means that the CLI can't be installed, uninstalled or updated without it.
# "Other"	-> means that the CLI can be installed, uninstalled or updated without it.
# (the update process must handle a clean installation by deleting or creating right files at right places).
directories_core=""$dir_bin""
directories_other=""$dir_src" "$dir_systemd" "$dir_config" "$dir_autocompletion""
files_core=""$dir_bin/$NAME_LOWERCASE" "$dir_bin/bp""
files_other=""$dir_autocompletion/$NAME_LOWERCASE" "$dir_systemd/$NAME_LOWERCASE-updates.service" "$dir_systemd/$NAME_LOWERCASE-updates.timer" "$dir_config/.current_publication" "$dir_config/"$NAME_LOWERCASE"_config""




# Permit to check if files exist or not
# Usage:
# - check_files
# - check_files | grep -q "$NAME failure:"
check_files() {

	local number_core_found=0
	local number_core_notfound=0

	local number_other_found=0
	local number_other_notfound=0
	
	echo ">>> Verifying files"

	# Core directories
	for directory in "${directories_core}"; do
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
		display_error "missing core file(s). A reinstallation is required (https://github.com/bashpack-project/bashpack?tab=readme-ov-file#quick-start)"
	elif [ $number_other_notfound -gt 0 ]; then
		echo ""
		display_error "core file(s) are working, but some features are not working as expected. 'sudo bp -i' should solve the issue (if not, you can open an issue at https://github.com/bashpack-project/bashpack/issues)"
	else
		echo ""
		display_success "Current installation is working as expected."
	fi
}




# Permit to verify if downloading tarball works as expected.
# Usage: 
# - Latest version:		check_download
# - Current version:	check_download <VERSION>
check_download() {

	local not_found=0
	local defined_version=${1}


	echo ">>> Attempting to download and extract archive from $URL/tarball/$defined_version"

	download_cli "$URL/tarball/$defined_version" $archive_tmp $archive_dir_tmp
	
	if [ -f "$archive_tmp" ]; then
		display_success "verification passed: $archive_tmp found."
	else
		not_found=$((not_found+1))
		display_error "verification failed: $archive_tmp not found."
	fi
	
	if [ -d "$archive_dir_tmp" ]; then
		display_success "verification passed: $archive_dir_tmp found."
	else
		not_found=$((not_found+1))
		display_error "verification failed: $archive_dir_tmp not found."
	fi

	# Cleaning downloaded temp files.
	rm -rf $archive_tmp
	rm -rf $archive_dir_tmp
}




# # Permit to verify if the remote repository is reachable with HTTP.
# # Usage: 
# # - check_repository_reachability
# # - check_repository_reachability | grep -q "$NAME failure: "
# check_repository_reachability() {

# 	if [ $(exists_command "curl") = "exists" ]; then
# 		http_code=$(curl -s -I $URL | awk '/^HTTP/{print $2}')
# 	elif [ $(exists_command "wget") = "exists" ]; then
# 		http_code=$(wget --server-response "$URL" 2>&1 | awk '/^  HTTP/{print $2}')
# 	else
# 		display_error "can't get HTTP status code with curl or wget."
# 	fi


# 	# Need to be improved to all 1**, 2** and 3** codes.
# 	if [ $http_code -eq 200 ]; then
# 		display_success "HTTP status code $http_code. Repository is reachable."
# 	else 
# 		display_error "HTTP status code $http_code. Repository is not reachable."
# 	fi
# }




if [ "$function_to_launch" = "check_all" ]; then
	check_files
	
	echo ""
	check_download
	
	echo ""
	check_download $VERSION


	echo ""
	loading "check_repository_reachability"
fi



if [ "$function_to_launch" = "check_files" ]; then
	check_files
fi



if [ "$function_to_launch" = "check_download" ]; then
	check_download

	echo ""
	check_download $VERSION
fi



if [ "$function_to_launch" = "check_repository_reachability" ]; then
	loading "check_repository_reachability"
fi






# Properly exit
exit

#EOF