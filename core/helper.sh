# #!/bin/sh

# # MIT License

# # Copyright (c) 2024 Geoffrey Gontard

# # Permission is hereby granted, free of charge, to any person obtaining a copy
# # of this software and associated documentation files (the "Software"), to deal
# # in the Software without restriction, including without limitation the rights
# # to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# # copies of the Software, and to permit persons to whom the Software is
# # furnished to do so, subject to the following conditions:

# # The above copyright notice and this permission notice shall be included in all
# # copies or substantial portions of the Software.

# # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# # IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# # FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# # AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# # LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# # OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# # SOFTWARE.




# export now=$(date +%y-%m-%d_%H-%M-%S)




# # Display always the same message in error messages.
# # Usage: display_error <message>
# display_error() {
# 	echo "$now error: ${1}"
# }




# # Display always the same message in success messages.
# # Usage: display_success <message> 
# display_success() {
# 	echo "$now success: ${1}"
# }




# # Loading animation so we know the process has not crashed.
# # Usage: loading "<command that takes time>"
# loading() {
# 	${1} & local pid=$!
# 	# local loader="\|/-"
# 	# local i=1

# 	echo ""
# 	while ps -p $pid > /dev/null; do
# 		# printf "\b%c" "${loader:i++%4:1}"
# 		# sleep 0.12
# 		for s in / - \\ \|; do
# 			printf "\b%c\r$s"
# 			sleep 0.12
# 		done
# 		i=$((i+1))
# 	done

# 	# Delete the loader character displayed after the loading has ended 
# 	printf "\b%c" " "
	
# 	echo ""
# }




# # Find if and where the command exists on the system (like 'which' but compatible with POSIX systems).
# # (could use "command -v" but was more fun creating it)
# # Usage: posix_which <command>
# posix_which() {

# 	# Useful in case of spaces in path
# 	# Spaces are creating new lines in for loop, so the trick here is to replacing it with a special char assuming it should not be much used in $PATH directories
# 	# TL;DR: translate spaces -> special char -> spaces = keep single line for each directory
# 	local special_char="|"
	
# 	for directory_raw in $(echo "$PATH" | tr ":" "\n" | tr " " "$special_char"); do
# 		local directory="$(echo $directory_raw | tr "$special_char" " ")"
# 		local command="$directory/${1}"

# 		if [ -f "$command" ]; then
# 			echo "$command"
# 			# break
# 		fi
# 	done
# }




# # Function to know if commands exist on the system.
# # Usage: exists_command <command>
# exists_command() {
# 	local command="${1}"

# 	# if ! which $command > /dev/null; then
# 	if [ ! -z "$(posix_which "$command")" ]; then
# 		echo "exists"
# 	else
# 		display_error "'$command' command not found"
# 	fi
# }




# # Getting values stored in configuration files.
# # Usage: read_config_value "<file>" "<option>"
# get_config_value() {
# 	local file=${1}
# 	local option=${2}

# 	while read -r line; do
# 		local first_char=`echo $line | cut -c1-1`

# 		# Avoid reading comments and empty lines
# 		if [ "$first_char" != "#" ] && [ "$first_char" != "" ]; then
# 			echo $line | cut -d " " -f 2
# 			break
# 		fi	
# 	done < "$file"
# }




# # Error function.
# # Usage: error_file_not_downloaded <file_url>
# error_file_not_downloaded() {
# 	display_error "${1} not found. Are curl or wget able to reach it from your system?"
# }




# # Error function.
# # Usage: error_tarball_non_working <file_name>
# error_tarball_non_working() {
# 	display_error "file '${1}' is a non-working .tar.gz tarball and cannot be used. Deleting it."
# }




# # Get user a confirmation that accepts differents answers and returns always the same value
# # Usage: get_confirmation <yes|Yes|yEs|yeS|YEs|YeS|yES|YES|y|Y>
# sanitize_confirmation() {
# 	if [ "$1" = "yes" ] || [ "$1" = "Yes" ] || [ "$1" = "yEs" ] || [ "$1" = "yeS" ] || [ "$1" = "YEs" ] || [ "$1" = "YeS" ] || [ "$1" = "yES" ] || [ "$1" = "YES" ] || [ "$1" = "y" ] || [ "$1" = "Y" ]; then
# 		echo "yes"
# 	fi
# }




# # # Compare given version with current version 
# # # Permit to adapt some behaviors like file renamed in new versions
# # compare_version_age_with_current() {

# # 	local given_version=${1}
# # 	local given_major=$(echo $given_version | cut -d "." -f 1)
# # 	local given_minor=$(echo $given_version | cut -d "." -f 2)

# # 	local current_major=$(echo $VERSION | cut -d "." -f 1)
# # 	local current_minor=$(echo $VERSION | cut -d "." -f 2)
# # 	# local current_patch=$(echo $VERSION | cut -d "." -f 3) # Should not be used. If something is different between two version, so it's not a patch, it must be at least in a new minor version.

# # 	if [ $current_major -gt $given_major ] || ([ $current_major -ge $given_major ] && [ $current_minor -gt $given_minor ]); then
# # 		echo "current_is_younger"
# # 	elif [ $current_major -eq $given_major ] && [ $current_minor -eq $given_minor ]; then
# # 		echo "current_is_equal"
# # 	else
# # 		echo "current_is_older"
# # 	fi
# # }



# # Helper function to extract a .tar.gz archive
# # Usage: archive_extract <archive> <destination directory>
# archive_extract() {
# 	# Testing if actually using a working tarball, and if not exiting script so we avoid breaking any installations.
# 	if file ${1} | grep -q 'gzip compressed data'; then
# 		if [ "$(exists_command "tar")" = "exists" ]; then
# 			# "tar --strip-components 1" permit to extract sources in /tmp/$NAME_LOWERCASE and don't create a new directory /tmp/$NAME_LOWERCASE/$NAME_LOWERCASE
# 			tar -xf ${1} -C ${2} --strip-components 1
# 		fi
# 	else
# 		error_tarball_non_working ${1}
# 		rm -f ${1}
# 	fi
# }




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
# 		display_success "[HTTP $http_code] $URL is reachable."
# 	# elif [ -z $http_code ]; then
# 	# 	display_error "[HTTP $http_code] $URL is not reachable."
# 	# 	exit
# 	else 
# 		display_error "[HTTP $http_code] $URL is not reachable."
# 		exit
# 	fi
# }




# # Download releases archives from the repository
# # Usages:
# # - download_cli <url of latest> <temp archive> <temp dir for extraction>
# # - download_cli <url of n.n.n> <temp archive> <temp dir for extraction>
# download_cli() {

# 	local archive_url=${1}
# 	local archive_tmp=${2}
# 	local archive_dir_tmp=${3}

# 	# Prepare tmp directory
# 	rm -rf $archive_dir_tmp
# 	mkdir $archive_dir_tmp

	
# 	# Download source scripts
# 	# Testing if repository is reachable with HTTP before doing anything.
# 	if ! check_repository_reachability | grep -q '$NAME failure:'; then
# 		# Try to download with curl if exists
# 		echo -n "Downloading sources from $archive_url "
# 		if [ $(exists_command "curl") = "exists" ]; then
# 			echo -n "with curl...   "
# 			loading "curl -sL $archive_url -o $archive_tmp"

# 			archive_extract $archive_tmp $archive_dir_tmp
			
# 		# Try to download with wget if exists
# 		elif [ $(exists_command "wget") = "exists" ]; then
# 			echo -n "with wget...  "
# 			loading "wget -q $archive_url -O $archive_tmp"
			
# 			archive_extract $archive_tmp $archive_dir_tmp

# 		else
# 			error_file_not_downloaded $archive_url
# 		fi
# 	else
# 		# Just call again the same function to get its error message
# 		check_repository_reachability
# 	fi

# }


# #EOF