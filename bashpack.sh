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




# Uncomment for debug
# set -x



export VERSION="2.0.1"

export NAME="Bashpack"
export NAME_LOWERCASE="$(echo "$NAME" | tr A-Z a-z)"
export NAME_UPPERCASE="$(echo "$NAME" | tr a-z A-Z)"
export NAME_ALIAS="bp"

export current_cli="$0"

# BASE_URL="https://api.github.com/repos/$NAME_LOWERCASE-project"
REPO_URL="$NAME_LOWERCASE-project"
HOST_URL_ARCH="https://api.github.com/repos/$REPO_URL"
HOST_URL_FILE="https://raw.githubusercontent.com/$REPO_URL"

USAGE="Usage: $current_cli [COMMAND] [OPTION] \n$current_cli --help"

dir_tmp="/tmp"
dir_bin="/usr/local/sbin"
dir_systemd="/lib/systemd/system"

dir_config="/etc/$NAME_LOWERCASE"
dir_log="/var/log/$NAME_LOWERCASE"
dir_src_cli="/opt/$NAME_LOWERCASE"

# Automatically detect the best PATH for the installation 
# Usage: define_installation_path
define_installation_path() {

	# Useful in case of spaces in path
	# Spaces are creating new lines in for loop, so the trick here is to replacing it with a special char assuming it should not be much used in $PATH directories
	# TL;DR: translate spaces -> special char -> spaces = keep single line for each directory
	local special_char="|"
			
	for directory_raw in $(echo "$PATH" | tr ":" "\n" | tr " " "$special_char"); do
		local directory="$(echo $directory_raw | tr "$special_char" " ")"

		if [ -d "$directory" ] && [ "$(echo "$directory" | grep "usr" | grep "sbin" | grep "local" )" ]; then
			echo $directory
			break

		elif [ -d "$directory" ] && [ "$(echo "$directory" | grep "usr" | grep "sbin" )" ]; then
			echo $directory
			break

		elif [ -d "$directory" ] && [ "$(echo "$directory" | grep "usr" | grep "bin" )" ]; then
			echo $directory
			break

		fi
	done
}
dir_bin="$(define_installation_path)"



export archive_tmp="$dir_tmp/$NAME_LOWERCASE-$VERSION.tar.gz"
export archive_dir_tmp="$dir_tmp/$NAME_LOWERCASE" # Make a generic name for tmp directory, so all versions will delete it

export now="$(date +%y-%m-%d_%H-%M-%S)"

export file_main="$dir_src_cli/$NAME_LOWERCASE.sh"
export file_main_alias_1="$dir_bin/$NAME_LOWERCASE"
export file_main_alias_2="$dir_bin/$NAME_ALIAS"

file_current_publication="$dir_config/.current_publication"


# Log creations
if [ ! -d "$dir_log" ]; then
	mkdir -p "$dir_log"
fi
file_log="$dir_log/main.log"



# Display a warning in case of using the script and not a command installed on the system
# Export a variable that permit to avoid this message duplication (because this file is called multiple times over the differents process)
if [ "$WARNING_ALREADY_SEND" != "true" ]; then
	if [ "$current_cli" = "./$NAME_LOWERCASE.sh" ]; then
		echo "Warning: you are currently using '$current_cli' which is located in $(pwd)."
		echo ""

		export WARNING_ALREADY_SEND="true"
	fi
fi




# Options that can be called without root
# Display usage in case of empty option
# if [ -z "$@" ]; then
if [ -z "$1" ]; then
	echo "$USAGE"
	exit
else
	case "$1" in
		--version) echo $VERSION && exit ;;
		update)
			case "$2" in
				--help) echo "$USAGE" \
				&&		echo "" \
				&&		echo "Supported package managers:" \
				&&		echo " - APT (https://wiki.debian.org/Apt)" \
				&&		echo " - YUM (http://yum.baseurl.org/)" \
				&&		echo " - Canonical Snapcraft (https://snapcraft.io)" \
				&&		echo " - Firmwares with fwupd (https://github.com/fwupd/fwupd)" \
				&&		echo "" \
				&&		echo "Options:" \
				&&		echo " -y, --assume-yes 	enable automatic installations without asking during the execution." \
				&&		echo "     --ask    		ask to manually write your choice about updates installations confirmations." \
				&&		echo "     --get-logs		display systemd logs." \
				&&		echo "     --when   		display systemd next service cycle." \
				&&		echo "" \
				&&		echo "$NAME $VERSION" \
				&&		exit ;;
			esac
		;;
		verify)
			case "$2" in
				--help) echo "$USAGE" \
				&&		echo "" \
				&&		echo "Verify current $NAME installation on your system." \
				&&		echo "" \
				&&		echo "Options:" \
				&&		echo " -f, --files				check that all required files are available." \
				&&		echo " -c, --commands				check that required commands are available." \
				&&		echo " -r, --repository-reachability		check that remote repository is reachable." \
				&&		echo "" \
				&&		echo "$NAME $VERSION" \
				&&		exit ;;
			esac
		;;
		--help) echo "$USAGE" \
		&&		echo "" \
		&&		echo "Options:" \
		&&		echo " -i, --self-install	install (or reinstall) $NAME on your system as the command '$NAME_ALIAS'." \
		&&		echo " -u, --self-update	update your current $NAME installation to the latest available version on the chosen publication." \
		&&		echo "     --self-delete	delete $NAME from your system." \
		&&		echo "     --help   		display this information." \
		&&		echo " -p, --publication	display your current $NAME installation publication stage (main, unstable, dev)." \
		&&		echo "     --version		display version." \
		&&		echo "" \
		&&		echo "Commands (--help for commands options):" \
		&&		echo " update [OPTION]	update everything on your system." \
		&&		echo " verify [OPTION]	verify the current $NAME installation health." \
		&&		echo "" \
		&&		echo "$NAME $VERSION" \
		&&		exit ;;
	esac
fi




# Ask for root
set -e
if [ "$(id -u)" != "0" ]; then
	echo "$now error:   must be runned as root."
	exit
fi




# --- --- --- --- --- --- ---
# Helper functions - begin


# Display always the same message in error messages.
# Usage: display_error <message>
display_error() {
	echo "$now error:   ${1}" | tee -a "$file_log"
}




# Display always the same message in success messages.
# Usage: display_success <message> 
display_success() {
	echo "$now success: ${1}" | tee -a "$file_log"
}




# Display always the same message in info messages.
# Usage: display_info <message> 
display_info() {
	echo "$now info:    ${1}" | tee -a "$file_log"
}




# Loading animation so we know the process has not crashed.
# Usage: loading "<command that takes time>"
loading() {
	${1} & local pid=$!

	# while ps -p $pid > /dev/null; do
	while ps -T | grep $pid > /dev/null; do
		# for s in / - \|; do
		for s in . o O °; do
			printf "$s\033[0K\r"

			sleep 0.12
		done
		i=$((i+1))
	done
}




# Find if and where the command exists on the system (like 'which' but compatible with POSIX systems).
# Usage: posix_which <command>
posix_which() {

	# Get the path of a given command
	# Usage: find_path <command>
	find_path() {
		# Useful in case of spaces in path
		# Spaces are creating new lines in for loop, so the trick here is to replacing it with a special char assuming it should not be much used in $PATH directories
		# TL;DR: translate spaces -> special char -> spaces = keep single line for each directory
		local special_char="|"
		
		if [ "$SHELL" = "/bin/bash" ]; then
			# Bash isn't creating new lines if command is used in "$(quotes)"
			for directory_raw in $(echo "$PATH" | tr ":" "\n" | tr " " "$special_char"); do
				local directory="$(echo $directory_raw | tr "$special_char" " ")"
				local command="$directory/${1}"

				if [ -f "$command" ]; then
					echo "$command"
				fi
			done
		else 
			for directory_raw in "$(echo "$PATH" | tr ":" "\n" | tr " " "$special_char")"; do
				local directory="$(echo $directory_raw | tr "$special_char" " ")"
				local command="$directory/${1}"

				if [ -f "$command" ]; then
					echo "$command"
				fi
			done
		fi
	}

	# Some commands are builtin and doesn't have path on the system.
	# This permit to 
	# - test if any command exists
	# - get the path of the command if it has one
	# - still display an output in case of no path but the command exist
	# - don't display anything if the command doesn't exist at all
	if [ -n "$(command -v "${1}")" ]; then
		if [ -n "$(find_path "${1}")" ]; then
			find_path "${1}"
		else
			echo "${1}"
		fi
	fi
	
}




# Function to know if commands exist on the system, with always the same output to easily use it in conditions statements.
# Usage: exists_command <command>
exists_command() {
	local command="${1}"

	# if ! which $command > /dev/null; then
	if [ ! -z "$(posix_which "$command")" ]; then
		echo "exists"
	else
		display_error "'$command' command not found"
	fi
}




# Getting values stored in configuration files.
# Usage: get_config_value "<file>" "<option>"
get_config_value() {
	local file=${1}
	local option=${2}

	while read -r line; do
		# local first_char=`echo $line | cut -c1-1`
		local first_char=$(echo $line | cut -c1-1)

		# Avoid reading comments and empty lines
		if [ "$first_char" != "#" ] && [ "$first_char" != "" ]; then
			if [ "$(echo $line | cut -d " " -f 1)" = "$option" ]; then
				echo $line | cut -d " " -f 2
				break
			fi
		fi	
	done < "$file"
}




# Get user a confirmation that accepts differents answers and returns always the same value
# Usage: sanitize_confirmation <yes|Yes|yEs|yeS|YEs|YeS|yES|YES|y|Y>
sanitize_confirmation() {
	if [ "$1" = "yes" ] || [ "$1" = "Yes" ] || [ "$1" = "yEs" ] || [ "$1" = "yeS" ] || [ "$1" = "YEs" ] || [ "$1" = "YeS" ] || [ "$1" = "yES" ] || [ "$1" = "YES" ] || [ "$1" = "y" ] || [ "$1" = "Y" ]; then
		echo "yes"
	fi
}




# Display logs from given file
# Usage: get_logs <file>
get_logs() {

	display_info "getting logs from ${1}"

	if [ "$(exists_command "less")" = "exists" ]; then
		cat "${1}" | less +G
	else
		cat "${1}"
	fi
}




# Permit to verify if the remote repository is reachable with HTTP.
# Usage: check_repository_reachability <URL>
check_repository_reachability() {

	local url="${1}"

	if [ "$(exists_command "curl")" = "exists" ]; then
		http_code="$(curl -s -I "$url" | awk '/^HTTP/{print $2}')"
	elif [ "$(exists_command "wget")" = "exists" ]; then
		http_code="$(wget --server-response "$url" 2>&1 | awk '/^  HTTP/{print $2}' | head -n 1)"
	else
		display_error "can't get HTTP status code with curl or wget."
	fi

	http_family="$(echo $http_code | cut -c 1)"
	if [ "$http_family" = "1" ] || [ "$http_family" = "2" ] || [ "$http_family" = "3" ]; then
		repository_reachable="true"
		display_success "[HTTP $http_code] $url is reachable."
	else 
		repository_reachable="false"
		display_error "[HTTP $http_code] $url is not reachable."
		exit
	fi
}




# Download releases archives from the repository
# Usages:
# - download_cli <url of single file> <temp file>
# - download_cli <url of n.n.n archive> <temp archive> <temp dir for extraction>
download_cli() {

	local file_url="${1}"
	local file_tmp="${2}"
	local dir_extract_tmp="${3}"

	# Testing if repository is reachable with HTTP before doing anything.
	check_repository_reachability "$file_url"
	if [ "$repository_reachable" = "true" ]; then

		# Try to download with curl if exists
		if [ "$(exists_command "curl")" = "exists" ]; then
			display_info "downloading sources from $file_url with curl."
			loading "curl -sL $file_url -o $file_tmp"
			
		# Try to download with wget if exists
		elif [ "$(exists_command "wget")" = "exists" ]; then
			display_info "downloading sources from $file_url with wget."
			loading "wget -q $file_url -O $file_tmp"

		else
			display_error "could not download $file_url with curl or wget."
		fi


		# Test if the "$dir_extract_tmp" variable is empty to know if we downloaded an archive that we need to extract
		if [ -n "$dir_extract_tmp" ]; then
			# Test if the downloaded file is a tarball
			if file "$file_tmp" | grep -q "gzip compressed data"; then
				if [ "$(exists_command "tar")" = "exists" ]; then
				
					# Prepare tmp directory
					rm -rf $dir_extract_tmp
					mkdir -p $dir_extract_tmp

					# "tar --strip-components 1" permit to extract sources in /tmp/$NAME_LOWERCASE and don't create a new directory /tmp/$NAME_LOWERCASE/$NAME_LOWERCASE
					tar -xf "$file_tmp" -C "$dir_extract_tmp" --strip-components 1
				fi
			else
				display_error "file '$file_url' is a non-working tarball and cannot be used, deleting it."
			fi
		fi
	fi

}

# Helper functions - end
# --- --- --- --- --- --- ---




# bash-completion doc: https://github.com/scop/bash-completion/tree/master?tab=readme-ov-file#faq
# If pkg-config doesn't exist, then the system won't have autocompletion.
if [ "$(exists_command "pkg-config")" = "exists" ]; then

	# Test if completion dir exists to avoid interruption
	if [ -n "$(pkg-config --variable=completionsdir bash-completion)" ]; then
		dir_autocompletion="$(pkg-config --variable=completionsdir bash-completion)"
		file_autocompletion="$dir_autocompletion/$NAME_LOWERCASE"
	fi
fi




export file_config="$dir_config/$NAME_LOWERCASE.conf"
# Since 1.2.0 the main config file has been renamed from $NAME_LOWERCASE_config to $NAME_LOWERCASE.conf
# The old file is not needed anymore and must be removed (here it's automatically renamed)
if [ -f "$dir_config/"$NAME_LOWERCASE"_config" ]; then
	mv "$dir_config/"$NAME_LOWERCASE"_config" "$file_config"
fi




# Depending on the chosen publication, the repository will be different:
# - Main (= stable) releases:	https://github.com/$NAME_LOWERCASE-project/$NAME_LOWERCASE
# - Unstable releases:			https://github.com/$NAME_LOWERCASE-project/$NAME_LOWERCASE-unstable
# - Dev releases:				https://github.com/$NAME_LOWERCASE-project/$NAME_LOWERCASE-dev
if [ -f "$file_config" ]; then
	PUBLICATION="$(get_config_value "$file_config" "publication")"
else
	PUBLICATION="main"
fi

case $PUBLICATION in
	unstable|dev)
		URL_ARCH="$HOST_URL_ARCH/$NAME_LOWERCASE-$PUBLICATION"
		URL_FILE="$HOST_URL_FILE/$NAME_LOWERCASE-$PUBLICATION"
		;;
	*)
		URL_ARCH="$HOST_URL_ARCH/$NAME_LOWERCASE"
		URL_FILE="$HOST_URL_FILE/$NAME_LOWERCASE"
		;;
esac




if [ "$current_cli" = "./$NAME_LOWERCASE.sh" ]; then
	dir_commands="commands"
else
	dir_commands="$dir_src_cli/commands"
fi

file_COMMAND_UPDATE="$dir_commands/update.sh"
file_COMMAND_MAN="$dir_commands/man.sh"
file_COMMAND_FIREWALL="$dir_commands/firewall.sh"	

if [ "$(exists_command "systemctl")" = "exists" ]; then
	COMMAND_UPDATE_SYSTEMD_STATUS="systemctl status $NAME_LOWERCASE-updates.timer"
	
	if [ "$(exists_command "journalctl")" = "exists" ]; then
		COMMAND_UPDATE_SYSTEMD_LOGS="journalctl -e _SYSTEMD_INVOCATION_ID=`systemctl show -p InvocationID --value $NAME_LOWERCASE-updates.service`"
	fi
fi



# Delete the installed command from the system
# Usages: 
# - delete_cli
# - delete_cli "exclude_main"
delete_cli() {
	
	# $exclude_main permit to not delete main command "$NAME_ALIAS" and "$NAME_LOWERCASE".
	#	(i) This is useful in case when the CLI tries to update itself, but the latest release is not accessible.
	#	/!\ Unless it can happen that the CLI destroys itself, and then the user must reinstall it.
	#	(i) Any new update will overwrite the "$NAME_ALIAS" and "$NAME_LOWERCASE" command, so it doesn't matter to not delete it during update.
	#	(i) It's preferable to delete all others files since updates can remove files from olders releases 
	local exclude_main="${1}"

	if [ "$(exists_command "$NAME_ALIAS")" != "exists" ]; then
		display_error "$NAME is not installed on your system."
	else
		if [ "$exclude_main" = "exclude_main" ]; then
			# Delete everything except main files and directories
			
			# The "find" command below permit to delete everything in $dir_src_cli except:
			# - main CLI file
			# - "core" directory (because some functions needed for main CLI file are stored in it)
			#
			# Notes: 
			# - "exec rm -rv {} +" is the part that permit to remove the files and directory
			# - "mindepth 1" permit to avoid the $dir_src_cli directory to be itself deleted
			#
			# This command can be used to list concerned files and directories : 
			# find $dir_src_cli -mindepth 1 -maxdepth 1 ! -name "$NAME_LOWERCASE.sh" -print
			# find $dir_src_cli -mindepth 1 -maxdepth 1 ! -name "$NAME_LOWERCASE.sh" -exec rm -rv {} + 2&> /dev/null
			find $dir_src_cli -mindepth 1 -maxdepth 1 -not -name "$NAME_LOWERCASE.sh" -exec rm -rf {} +

		else
			# Delete everything
			rm -rf $dir_config
			rm -rf $file_autocompletion
			rm -rf $file_main_alias_1
			rm -rf $file_main_alias_2
			rm -rf $dir_src_cli
			rm -rf $dir_log
		fi

		if [ -f "$file_main" ]; then
			if [ "$exclude_main" = "exclude_main" ]; then
				display_success "all sources removes excepted $file_main."
			else
				display_error "$NAME $VERSION located at $(posix_which $NAME_ALIAS) has not been uninstalled." && exit
			fi
		else
			display_success "$NAME $VERSION ($(detect_publication)) has been uninstalled."
		fi
	fi
}




# Delete the installed systemd units from the system
delete_systemd() {

	if [ "$(exists_command "$NAME_ALIAS")" != "exists" ]; then
		echo "$NAME $VERSION is not installed on your system."
	else
		if [ "$(exists_command "systemctl")" = "exists" ]; then

			# Stop, disable and delete all systemd units
			for file in $(ls $dir_systemd/$NAME_LOWERCASE* | grep ".timer"); do
				if [ -f $file ]; then
					display_info "$file found."

					local unit="$(basename "$file")"

					systemctl stop $unit
					systemctl disable $unit
					rm -f $file

					if [ -f $file ]; then
						display_error "$file has not been removed."
					else
						display_success "$file has been removed."
					fi
				else
					display_error "$file not found."
				fi
			done

			systemctl daemon-reload
		fi
	fi
}




# Helper function to assemble all functions that delete something
# Usages: 
# - delete_all
# - delete_all "exclude_main" (Please check the explaination of $exclude_main at the delete_cli() function declaration)
delete_all() {
	
	local exclude_main=${1}

	delete_systemd && delete_cli ${1}
	# delete_cli ${1}
}




# Detect if the command has been installed on the system
detect_cli() {
	if [ "$(exists_command "$NAME_LOWERCASE")" = "exists" ]; then
		if [ -n "$($NAME_LOWERCASE --version)" ]; then
			display_info "$NAME $($NAME_ALIAS --version) detected at $(posix_which $NAME_LOWERCASE)"
		fi
	fi
}




# Detect what is the current publication installed
detect_publication() {
	if [ -f $file_current_publication ]; then
		cat $file_current_publication
	else
		display_error "publication not found."
	fi
}




# Check if all the files and directories that compose the CLI exist 
# Usage: verify_cli_files
verify_cli_files() {

	display_info  "checking if required files and directories are available on the system."

	# local filters_example="text1\|text2\|text3\|text4" 
	local filters_wanted="=" 
	local filters_unwanted="local " # the space is important for "local " otherwise it can hide some /usr/local/ paths, but the goal is just to avoid local functions variables declarations

	local found=0
	local missing=0
	local total=0

	# Just init variable to set it local
	local previous_path

	if [ "$(exists_command "eval")" = "exists" ]; then

		# Automatically detect every files and directories used in the CLI (every paths that we want to test here must be used through variables from this file)
		while read -r line; do
			if [ -n "$(echo $line | grep "$filters_wanted" | grep -v "$filters_unwanted" | grep "file_" | grep -v "\$file")" ] || [ -n "$(echo $line | grep "$filters_wanted" | grep -v "$filters_unwanted" | grep "dir_" | grep -v "\$dir")" ]; then

				local path_variable="$(echo $line | cut -d "=" -f 1 | sed s/"export "//)"

				# Just init variable to set it local
				local path_value
				eval path_value=\$$path_variable

				if [ -n "$path_value" ]; then
					if [ "$previous_path" != "$path_variable" ]; then

						if [ -f "$path_value" ]; then
							# display_success "found file -> $path_variable -> $path_value"
							display_success "found file -> $path_value"
							found=$((found+1))
						elif [ -d "$path_value" ]; then
							# display_success "found dir  -> $path_variable -> $path_value"
							display_success "found dir. -> $path_value"
							found=$((found+1))
						else
							# display_error "miss.      -> $path_variable -> $path_value"
							display_error "miss.      -> $path_value"
							missing=$((missing+1))
						fi
				
						total=$((total+1))
					fi
				fi

				# Store current path as the next previous path to be able to avoid tests duplication
				previous_path="$path_variable"

			fi
		done < "$current_cli"


		display_info "$found/$total paths found."

		if [ "$missing" != "0" ]; then
			display_error "at least one file or directory is missing."
		fi
	fi
}





# Check if all the required commands are available on the system
# Usage: verify_cli_commands
# Usage: verify_cli_commands "print-missing-required-command-only"
verify_cli_commands() {

	local print_missing_required_command_only="${1}"
	if [ "$print_missing_required_command_only" = "print-missing-required-command-only" ]; then
		print_missing_required_command_only="true"
	else
		display_info "checking if required commands are available on the system."
	fi	

	local found=0
	local missing=0
	local missing_required=0
	local total=0

	# Permit to find all the commands listed in a file (1 line = 1 command)
	# Usage: find_command <file>
	find_command() {
		local file_tmp="${1}"
		local type="${2}"		# "required" or "optional" command

		while read -r command; do
			if [ "$(exists_command "$command")" = "exists" ]; then

				if [ "$print_missing_required_command_only" != "true" ]; then
					display_success "found ($type) $command"
				fi

				found=$((found+1))
			else 
				if [ "$print_missing_required_command_only" != "true" ]; then
					display_error "miss. ($type) $command"
				fi

				missing=$((missing+1))

				if [ "$type" = "required" ]; then
					missing_required=$((missing_required+1))
				fi
			fi

			total=$((total+1))

		done < "$file_tmp"
	}

	local commands_required=" \
		tr
		ls
		echo
		printf
		cat
		cut
		sed
		awk
		find
		grep
		chmod
		mkdir
		mv
		rm
		cp
		pwd
		id
		date
		sleep
		ps
		sort
		basename
		tee
		file
		tar
		curl
		command
		exec
		set
		read
		cd
		eval
		exit
		export
		case
		if
		while
		for
		local
		then
		fi
		esac
		do
		done
		$SHELL \
	"

	local commands_optional=" \
		less
		pkg-config
		wget
		journalctl
		systemctl \
	"

	# Must store the commands in a file to be able to use the counters
	local file_tmp_required="$dir_tmp/$NAME_LOWERCASE-commands-required"
	local file_tmp_optional="$dir_tmp/$NAME_LOWERCASE-commands-optional"

	echo "$commands_required" | sort -d > $file_tmp_required
	echo "$commands_optional" | sort -d > $file_tmp_optional

	find_command $file_tmp_required "required"
	find_command $file_tmp_optional "optional"


	if [ "$print_missing_required_command_only" != "true" ]; then
		
		display_info "$found/$total commands found."	

		if [ "$missing_required" = "0" ] && [ "$missing" != "0" ]; then
			display_error "at least one optional command is missing but will not prevent proper functioning."
		elif [ "$missing_required" != "0" ]; then
			display_error "at least one required command is missing."
		fi
	else
		echo $missing_required		
	fi


	rm $file_tmp_required
	rm $file_tmp_optional

}




# This function will install the new config file given within new versions, while keeping user configured values
# Usage: install_new_config_file
install_new_config_file() {

	local file_config_current="$file_config"
	# local file_config_tmp="$archive_dir_tmp/config/$file_config"
	local file_config_tmp="$archive_dir_tmp/config/$NAME_LOWERCASE.conf"

	while read -r line; do
		local first_char=`echo $line | cut -c1-1`

		# Avoid reading comments and empty lines
		if [ "$first_char" != "#" ] && [ "$first_char" != "" ]; then

			option=$(echo $line | cut -d " " -f 1)
			value=$(echo $line | cut -d " " -f 2)

			# Replacing options values in temp config file with current configured values
			# /^#/! is to avoid commented lines
			sed -i "/^#/! s/$option.*/$line/g" $file_config_tmp

		fi	
	done < "$file_config_current"

	cp $file_config_tmp $file_config_current

}




# Create the command from the downloaded archives
# Works together with install or update functions
create_cli() {

	# Process to the installation
	if [ -d "$archive_dir_tmp" ]; then
	
		# Depending on what version an update is performed, it can happen that cp can't overwrite a previous symlink
		# Remove them to allow installation of the CLI
		if [ -f "$file_main_alias_1" ] || [ -f "$file_main_alias_2" ]; then
			display_info "removing old aliases."
			rm -f $file_main_alias_1
			rm -f $file_main_alias_2
		fi

		
		# Sources files installation
		display_info "installing sources."
		# cp -R "$archive_dir_tmp/commands" $dir_src_cli
		cp -RT $archive_dir_tmp $dir_src_cli # -T used to overwrite the source dir and not creating a new inside
		chmod +x -R $dir_src_cli


		# Create an alias so the listed package are clear on the system (-f to force overwrite existing)
		display_info "installing aliases."
		ln -sf $file_main $file_main_alias_1
		ln -sf $file_main $file_main_alias_2


		# Autocompletion installation
		# Install autocompletion only if the directory has been found.
		if [ -n "$dir_autocompletion" ]; then
			display_info "installing autocompletion."
			cp "$archive_dir_tmp/bash_completion" $file_autocompletion
		fi

		
		# Systemd services installation
		# Checking if systemd is installed (and do nothing if not installed because it means the OS doesn't work with it)
		if [ $(exists_command "systemctl") = "exists" ]; then
		
			display_info "installing systemd services."
		
			# Copy systemd services & timers to systemd directory
			cp -R $archive_dir_tmp/systemd/* $dir_systemd
			systemctl daemon-reload

			# Start & enable systemd timers (don't need to start systemd services because timers are made for this)
			for file in $(ls $dir_systemd/$NAME_LOWERCASE* | grep ".timer"); do
				if [ -f $file ]; then
					display_info "$file found."

					local unit="$(basename "$file")"

					display_info "starting & enabling $unit." 
					
					# Call "restart" and not "start" to be sure to run the unit provided in this current version (unless the old unit will be kept as the running one)
					systemctl restart "$unit" 
					systemctl enable "$unit"
				else
					display_error "$file not found."
				fi
			done
		fi


		# Config installation
		# Checking if the config directory exists and create it if doesn't exists
		display_info "installing configuration."
		if [ ! -d "$dir_config" ]; then
			display_info "$dir_config not found, creating it."
			mkdir $dir_config
		fi

		# Must testing if config file exists to avoid overwrite user customizations 
		if [ ! -f "$file_config" ]; then
			display_info "$file_config not found, creating it. "
			cp "$archive_dir_tmp/config/$file_config" "$file_config"

		else
			display_info "$file_config already exists, installing new file and inserting current configured options."
			install_new_config_file
		fi
		

		# Creating a file that permit to know what is the current installed publication
		echo "$PUBLICATION" > $file_current_publication


		# Allow users to edit the configuration
		chmod +rw -R $dir_config


		# Remove unwanted files from the installed sources (keep only main, sub commands and .md files)
		find $dir_src_cli -mindepth 1 -maxdepth 1 -not -name "$NAME_LOWERCASE.sh" -not -name "*.md" -not -name "commands" -exec rm -rf {} +


		# Success message
		if [ "$(exists_command "$NAME_ALIAS")" = "exists" ]; then
			display_success "$NAME $($NAME_ALIAS --version) ($(detect_publication)) has been installed."
		else
			display_error "$NAME installation failed."
		fi


		# Clear temporary files & directories
		rm -rf $dir_tmp/$NAME_LOWERCASE* # Cleaning also temp files created during update process since create_cli is not called directly during update.
		
	fi
}




# Update the installed command on the system
#
# !!!!!!!!!!!!!!!!!!!!!!!!!
# !!! CRITICAL FUNCTION !!!
# !!!!!!!!!!!!!!!!!!!!!!!!!
#
# /!\	This function must work everytime a modification is made in the code. 
# 		Unless, we risk to not being able to update it on the endpoints where it has been installed.
update_cli() {

	local downloaded_cli="$dir_tmp/$NAME_LOWERCASE.sh"

	# Testing if a new version exists on the current publication to avoid reinstall if not.
	# This test requires curl, if not usable, then the CLI will be reinstalled at each update.
	if [ "$(curl -s "$URL_ARCH/releases/latest" | grep tag_name | cut -d \" -f 4)" = "$VERSION" ] && [ "$(detect_publication)" = "$(get_config_value "$file_config" "publication")" ]; then
		display_info "latest $NAME version is already installed ($VERSION $(detect_publication))."
	else

		# Download only the main file 
		download_cli "$URL_FILE/main/$NAME_LOWERCASE.sh" "$downloaded_cli"
		
		# Execute the installation from the downloaded file 
		chmod +x "$downloaded_cli"
		"$downloaded_cli" -i

		# rm -rf "$dir_tmp/$NAME_LOWERCASE.sh"

	fi
}




# Install the command on the system
#
# !!!!!!!!!!!!!!!!!!!!!!!!!
# !!! CRITICAL FUNCTION !!!
# !!!!!!!!!!!!!!!!!!!!!!!!!
#
# /!\	This function must work everytime a modification is made in the code. 
#		Because it's called by the update function.
install_cli() {
	detect_cli
	
	# Test if all required commands are on the system before install anything
	if [ "$(verify_cli_commands "print-missing-required-command-only")" = "0" ]; then
		# Download tarball archive
		download_cli "$URL_ARCH/tarball/$VERSION" $archive_tmp $archive_dir_tmp

		# Delete old files
		delete_cli "exclude_main"

		# Install new files
		create_cli
	else
		verify_cli_commands
	fi

}




# The options (except --help) must be called with root
case "$1" in
	-i|--self-install)		loading "install_cli" ;;		# Critical option, see the comments at function declaration for more info
	-u|--self-update)		loading "update_cli" ;;			# Critical option, see the comments at function declaration for more info
	--self-delete)			loading "delete_all" ;;
	-p|--publication)		loading "detect_publication" ;;
	--get-logs)				get_logs $file_log ;;
	man)					loading "$file_COMMAND_MAN" ;;
	verify)
		if [ -z "$2" ]; then
			loading "verify_cli_commands";  loading "verify_cli_files"; loading "check_repository_reachability "$URL_FILE/main/$NAME_LOWERCASE.sh""; loading "check_repository_reachability "$URL_ARCH/tarball/$VERSION""
		else
			case "$2" in
				-f|--files)						loading "verify_cli_files" ;;
				-c|--commands)					loading "verify_cli_commands" ;;
				-r|--repository-reachability)	loading "check_repository_reachability "$URL_FILE/main/$NAME_LOWERCASE.sh""; loading "check_repository_reachability "$URL_ARCH/tarball/$VERSION"" ;;
				*)								display_error "unknown option [$1] '$2'."'\n'"$USAGE" && exit ;;
			esac
		fi ;;
	firewall)
		if [ -z "$2" ]; then
			exec $file_COMMAND_FIREWALL
		else
			case "$2" in
				-r|--restart)	exec $file_COMMAND_FIREWALL ;;
				*)				display_error "unknown option [$1] '$2'."'\n'"$USAGE" && exit ;;
			esac
		fi ;;
	update)
		if [ -z "$2" ]; then
			exec $file_COMMAND_UPDATE
		else
			case "$2" in
				-y|--assume-yes)	export install_confirmation="yes" && exec $file_COMMAND_UPDATE ;;
				--ask)				read -p "Do you want to automatically accept installations during the process? [y/N] " install_confirmation && export install_confirmation && exec $file_COMMAND_UPDATE ;;
				--when)				$COMMAND_UPDATE_SYSTEMD_STATUS | grep Trigger: | awk '$1=$1' ;;
				--get-logs)			$COMMAND_UPDATE_SYSTEMD_LOGS ;;
				*)					display_error "unknown option [$1] '$2'."'\n'"$USAGE" && exit ;;
			esac
		fi ;;
	# Since "export -f" is not available in Shell, the helper command below permit to use commands from this file in sub scripts
	helper)
		# The $allow_helper_functions variable must be exported as "true" in sub scripts that needs the helper functions
		# This permit to avoid these commands to be used directly from the command line by the users
		if [ "$allow_helper_functions" != "true" ];then
			display_error "reserved operation."
		else
			if [ -z "$2" ]; then
				display_error "unknown option [$1] '$2'."'\n'"$USAGE" && exit
			else
				case "$2" in
					loading)							loading "$3" ;;
					display_success)					display_success "$3" ;;
					display_error)						display_error "$3" ;;
					display_info)						display_info "$3" ;;
					exists_command)						exists_command "$3" ;;
					sanitize_confirmation)				sanitize_confirmation "$3" ;;
					get_config_value)					get_config_value "$3" "$4" ;;
					*)									display_error "unknown option [$1] '$2'."'\n'"$USAGE" && exit ;;
				esac
			fi
		fi ;;
	*) display_error "unknown option '$1'."'\n'"$USAGE" && exit ;;
esac


# Properly exit
exit

#EOF