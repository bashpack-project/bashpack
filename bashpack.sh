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



export VERSION="3.0.0"

export NAME="Bashpack"
export NAME_LOWERCASE="$(echo "$NAME" | tr A-Z a-z)"
export NAME_UPPERCASE="$(echo "$NAME" | tr a-z A-Z)"
export NAME_ALIAS="bp"

export CURRENT_CLI="$0"
export HELPER="$CURRENT_CLI helper"
export OWNER="$(ls -l $CURRENT_CLI | cut -d " " -f 3)"

# BASE_URL="https://api.github.com/repos/$NAME_LOWERCASE-project"
REPO_URL="$NAME_LOWERCASE-project"
HOST_URL_API="https://api.github.com/repos/$REPO_URL"
HOST_URL_RAW="https://raw.githubusercontent.com/$REPO_URL"

export USAGE="Usage: $CURRENT_CLI [COMMAND] [OPTION] \n$CURRENT_CLI --help"

dir_tmp="/tmp"
dir_bin="/usr/local/sbin"
dir_systemd="/lib/systemd/system"

export dir_config="/etc/$NAME_LOWERCASE"
export dir_log="/var/log/$NAME_LOWERCASE"
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
export question_continue="Do you want to continue? [y/N] "


export file_main="$dir_src_cli/$NAME_LOWERCASE.sh"
export file_main_alias_1="$dir_bin/$NAME_LOWERCASE"
export file_main_alias_2="$dir_bin/$NAME_ALIAS"

file_current_publication="$dir_config/.current_publication"


# Log creations
if [ ! -d "$dir_log" ]; then
	mkdir -p "$dir_log"
fi
export file_log_main="$dir_log/main.log"



# Display a warning in case of using the script and not a command installed on the system
# Export a variable that permit to avoid this message duplication (because this file is called multiple times over the differents process)
if [ "$WARNING_ALREADY_SENT" != "true" ]; then
	if [ "$CURRENT_CLI" = "./$NAME_LOWERCASE.sh" ]; then
		echo "Warning: currently using '$CURRENT_CLI' which is located at $(pwd)."
		echo ""

		export WARNING_ALREADY_SENT="true"
	fi
fi



if [ "$CURRENT_CLI" = "./$NAME_LOWERCASE.sh" ]; then
	dir_commands="commands"
else
	dir_commands="$dir_src_cli/commands"
fi



if [ "$(echo $1 | grep -v '-' )" ]; then
	export CURRENT_SUBCOMMAND="$1"
	export file_LOG_CURRENT_SUBCOMMAND="$dir_log/$CURRENT_SUBCOMMAND.log"
	export file_CONFIG_CURRENT_SUBCOMMAND="$dir_config/$CURRENT_SUBCOMMAND.conf"
fi




# Options that can be called without root
# Display usage in case of empty option
# if [ -z "$@" ]; then
if [ -z "$1" ]; then
	echo "$USAGE"
	exit
else
	case "$1" in
		-v|--version) echo $VERSION && exit ;;
		command)
			case "$2" in
				--help) echo "$USAGE" \
				&&		echo "" \
				&&		echo "Manage $NAME sub commands." \
				&&		echo "" \
				&&		echo "Options:" \
				&&		echo " -l, --list         list available commands." \
				&&		echo " -g, --get <name>   install a command." \
				&&		echo " -d, --delete       remove a command." \
				&&		echo "" \
				&&		echo "$NAME $VERSION" \
				&&		exit ;;
			esac
		;;
		verify)
			case "$2" in
				--help) echo "$USAGE" \
				&&		echo "" \
				&&		echo "Verify current $NAME installation health." \
				&&		echo "" \
				&&		echo "Options:" \
				&&		echo " -f, --files                  check that all required files are available." \
				&&		echo " -d, --dependencies <file>    check that required dependencies are available." \
				&&		echo " -r, --repository             check that remote repository is reachable." \
				&&		echo "" \
				&&		echo "$NAME $VERSION" \
				&&		exit ;;
			esac
		;;
		--help) echo "$USAGE" \
		&&		echo "" \
		&&		echo "Options:" \
		&&		echo " -i, --self-install   install (or reinstall) $NAME on your system as the command '$NAME_ALIAS'." \
		&&		echo " -u, --self-update    update $NAME to the latest available version on the chosen publication (--force option available)." \
		&&		echo "     --self-delete    delete $NAME from your system." \
		&&		echo "     --get-logs       display logs." \
		&&		echo "     --help           display this information." \
		&&		echo " -p, --publication    display the current installed $NAME publication stage (main, unstable, dev)." \
		&&		echo " -v, --version        display version." \
		&&		echo "" \
		&&		echo "Commands (--help for commands options):" \
		&&		echo "$(ls $dir_commands | sed "s/.sh//g" | sed "s/^/  /g")" \
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


# Getting values stored in configuration files.
# Usage: get_config_value "<file>" "<option>"
get_config_value() {
	local file="${1}"
	local option="${2}"

	while read -r line; do
		local first_char="$(echo $line | cut -c1-1)"

		# Avoid reading comments and empty lines
		if [ "$first_char" != "#" ] && [ "$first_char" != "" ]; then
			if [ "$(echo $line | cut -d " " -f 1)" = "$option" ]; then
				echo $line | cut -d " " -f 2
				break
			fi
		fi	
	done < "$file"
}



# Display current CLI informations
# Usage: current_cli_info
# /!\ This function is intended for development purpose, it's just called in logs to clarify some situations
current_cli_info() {

	# "False" option doesn't really exist as described in the config file, anything other that "true" will just disable this function.
	if [ "$(get_config_value "$dir_config/$NAME_LOWERCASE.conf" "debug")" = "true" ]; then
		echo " cli:$CURRENT_CLI pub:$PUBLICATION ver:$VERSION   "
	fi
}



# Display always the same message in error messages.
# Usage: display_error <message>
# Usage: display_error <message> <log file to duplicate the message>
display_error() {

	local format="$now error:    $(current_cli_info) ${1}"

	if [ -n "${2}" ]; then
		echo "$format" | tee -a "$file_log_main" "${2}"
	else
		echo "$format" | tee -a "$file_log_main"
	fi
}




# Display always the same message in success messages.
# Usage: display_success <message>
# Usage: display_success <message> <log file to duplicate the message>
display_success() {

	local format="$now success:  $(current_cli_info) ${1}"

	if [ -n "${2}" ]; then
		echo "$format" | tee -a "$file_log_main" "${2}"
	else
		echo "$format" | tee -a "$file_log_main"
	fi
}




# Display always the same message in info messages.
# Usage: display_info <message>
# Usage: display_info <message> <log file to duplicate the message>
display_info() {

	local format="$now info:     $(current_cli_info) ${1}"

	if [ -n "${2}" ]; then
		echo "$format" | tee -a "$file_log_main" "${2}"
	else
		echo "$format" | tee -a "$file_log_main"
	fi
}




# Write output of a command in logs
# Usage: <command> | append_log					(append to the default file)
# Usage: <command> | append_log <log file>		(append to the given file)
append_log() {

	local file_log="${1}"
	
	# Get process name to write it in log file
	local command="${0}"
	$command & local pid=$!
	local process_name="$(ps -o cmd -fp $pid | cut -d " " -f 1 -s)"
	display_info "launching: $command"


	Set the log format on the command and append it to the selected file
	if [ -n "$file_log" ]; then
		sed "s/^/$now op.sys:   $(current_cli_info) /" | tee -a "$file_log"
	else
		sed "s/^/$now op.sys:   $(current_cli_info) /" | tee -a "$file_log_main"
	fi

}




# loading_process animation so we know the process has not crashed.
# Usage: loading_process "<command that takes time>"
loading_process() {
	${1} & local pid=$!

	# while ps -p $pid > /dev/null; do
	while ps -T | grep $pid > /dev/null; do
		# for s in / - \|; do
		# for s in l o a d e r; do
		for s in . o O °; do
			printf "$s\033[0K\r"

			sleep 0.12
		done
		# i=$((i+1))
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




# Setting values in configuration file during script execution
# Usage: set_config_value "<file>" "<option>" "<new value>"
set_config_value() {

	local file="${1}"
	local option="${2}"
	local value_new="${3}"
	local value_old="$(get_config_value $file $option)"

	display_info "set '$option' from '$value_old' to '$value_new'."

	# Drop if the option or the value are not given
	if [ -n "$option" ] || [ -n "$value_new" ]; then

		# If both the file and the option exist
		# = Replace the option old value with the new value
		if [ -f "$file" ] && [ -n "$value_old" ]; then
			sed -i "s/$option $value_old/$option $value_new/g" "$file"

		# If the file exists but the option doesn't exist
		# = Add the option and the value at the begin of the file (this is a curative way to just quickly get the option setted up)
		elif [ -f "$file" ] && [ -z "$value_old" ]; then
			sed -i "1s/^/$option $value_new/" "$file"

		# If the file doesn't exist (also meaning the option can't exist)
		# = Create the file and add the option with the value (this is a curative way to just quickly get the option setted up)
		elif [ ! -f "$file" ]; then
			echo "$option $value_new" > "$file"
		fi
	else
		display_error "missing option/value combination."
	fi
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




# Detect if the command has been installed on the system
detect_cli() {
	if [ "$(exists_command "$NAME_LOWERCASE")" = "exists" ]; then
		if [ -n "$($NAME_LOWERCASE --version)" ]; then
			display_info "$NAME $($NAME_ALIAS --version) ($($NAME_ALIAS --publication)) detected at $(posix_which $NAME_LOWERCASE)"
		fi
	fi
}




# Detect what is the current publication installed
detect_publication() {
	if [ -f "$file_current_publication" ]; then
		cat "$file_current_publication"
	else
		display_error "publication not found."
	fi
}




# Permit to verify if the remote repository is reachable with HTTP.
# Usage: verify_repository_reachability <URL>
verify_repository_reachability() {

	local url="${1}"

	if [ "$(exists_command "curl")" = "exists" ]; then
		http_code="$(curl -s -L -I -o /dev/null -w "%{response_code}" $url)"
	elif [ "$(exists_command "wget")" = "exists" ]; then
		http_code="$(wget --spider --server-response "$url" 2>&1 | awk '/^  HTTP/{print $2}' | tail -n 1)"
	else
		display_error "can't get HTTP code with curl or wget."
	fi

	http_family="$(echo $http_code | cut -c 1)"
	if [ "$http_family" = "1" ] || [ "$http_family" = "2" ] || [ "$http_family" = "3" ]; then
		# export repository_reachable="true"
		display_success "[HTTP $http_code] $url is reachable."
	else 
		# export repository_reachable="false"
		if [ -z $http_code ]; then
			display_error "$url is not reachable."
		else
			display_error "[HTTP $http_code] $url is not reachable."
		fi
		exit
	fi
}




# Download releases archives from the repository
# Usages:
# - download_file <url of single file> <temp file>
# - download_file <url of n.n.n archive> <temp archive> <temp dir for extraction>
download_file() {

	local file_url="${1}"
	local file_tmp="${2}"
	local dir_extract_tmp="${3}"

	# Testing if repository is reachable with HTTP before doing anything.
	loading_process "verify_repository_reachability $file_url"
	# if [ "$repository_reachable" = "true" ]; then

		# Try to download with curl if exists
		if [ "$(exists_command "curl")" = "exists" ]; then
			display_info "downloading sources from '$file_url' with curl."
			loading_process "curl -sL $file_url -o $file_tmp"
			
		# Try to download with wget if exists
		elif [ "$(exists_command "wget")" = "exists" ]; then
			display_info "downloading sources from '$file_url' with wget."
			loading_process "wget -q $file_url -O $file_tmp"

		else
			display_error "could not download '$file_url' with curl or wget."
		fi


		# Success message
		if [ -f "$file_tmp" ]; then
			display_success "file '$file_tmp' has been downloaded."

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
		else
			display_error "file '$file_tmp' has not been downloaded."
		fi


	# fi

}

# Helper functions - end
# --- --- --- --- --- --- ---




# bash-completion doc: https://github.com/scop/bash-completion/blob/main/README.md#faq
# If pkg-config doesn't exist, then the system won't have autocompletion.
if [ "$(exists_command "pkg-config")" = "exists" ]; then

	# Test if completion dir exists to avoid interruption
	if [ -n "$(pkg-config --variable=completionsdir bash-completion)" ]; then
		dir_autocompletion="$(pkg-config --variable=completionsdir bash-completion)"
		file_autocompletion_1="$dir_autocompletion/$NAME_LOWERCASE"
		file_autocompletion_2="$dir_autocompletion/$NAME_ALIAS"
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

case "$PUBLICATION" in
	unstable|dev)
		URL_API="$HOST_URL_API/$NAME_LOWERCASE-$PUBLICATION"
		URL_RAW="$HOST_URL_RAW/$NAME_LOWERCASE-$PUBLICATION"
		;;
	main)
		URL_API="$HOST_URL_API/$NAME_LOWERCASE"
		URL_RAW="$HOST_URL_RAW/$NAME_LOWERCASE"
		;;
	*)
		display_info "publication '$PUBLICATION' not found, using default 'main'."
		PUBLICATION="main"
		echo "main" > $file_current_publication
		URL_API="$HOST_URL_API/$NAME_LOWERCASE"
		URL_RAW="$HOST_URL_RAW/$NAME_LOWERCASE"
		;;
esac




if [ "$(exists_command "systemctl")" = "exists" ]; then
	COMMAND_UPDATE_SYSTEMD_STATUS="systemctl status $NAME_LOWERCASE-updates.timer"
	
	# if [ "$(exists_command "journalctl")" = "exists" ]; then
	# 	COMMAND_UPDATE_SYSTEMD_LOGS="journalctl -e _SYSTEMD_INVOCATION_ID=`systemctl show -p InvocationID --value $NAME_LOWERCASE-updates.service`"
	# fi
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
		detect_cli

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
			rm -rf $file_autocompletion_1
			rm -rf $file_autocompletion_2
			rm -rf $file_main_alias_1
			rm -rf $file_main_alias_2
			rm -rf $dir_src_cli
			rm -rf $dir_log
		fi

		if [ -f "$file_main" ]; then
			if [ "$exclude_main" = "exclude_main" ]; then
				display_success "all sources removed excepted $file_main."
			else
				display_error "$NAME $VERSION located at $(posix_which $NAME_ALIAS) has not been uninstalled." && exit
			fi
		else
			display_success "uninstallation completed."
		fi
	fi
}




# Delete the installed systemd units from the system
delete_systemd() {

	if [ "$(exists_command "$NAME_ALIAS")" = "exists" ] && [ "$(exists_command "systemctl")" = "exists" ]; then

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




# Check if all the files and directories that compose the CLI exist 
# Usages:
#  verify_files
#  verify_files <file to test>
verify_files() {

	display_info  "checking if required files and directories are available on the system."

	local file_to_test="${1}"
	if [ -z "$file_to_test" ]; then
		file_to_test="$CURRENT_CLI"
	fi

	# local filters_example="text1\|text2\|text3\|text4" 
	local filters_wanted="=" 
	local filters_unwanted="local " # the space is important for "local " otherwise it can hide some /usr/local/ paths, but the goal is just to avoid local functions variables declarations

	local found=0
	local missing=0
	local total=0

	# Just init variable to set it local
	local previous_path


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
	done < "$file_to_test"

	display_info "$found/$total paths found."

	if [ "$missing" != "0" ]; then
		display_error "at least one file or directory is missing."
	fi
}




# Check if all the required commands are available on the system
# Usages: 
#  verify_dependencies <file to test>
#  verify_dependencies <file to test> "print-missing-required-command-only"
verify_dependencies() {

	local file_to_test="${1}"
	if [ -z "$file_to_test" ]; then
		file_to_test="$CURRENT_CLI"
	fi	

	local print_missing_required_command_only="${2}"
	if [ "$print_missing_required_command_only" = "print-missing-required-command-only" ]; then
		print_missing_required_command_only="true"
	else
		display_info "checking if required commands are available on the system."
	fi

	
	# Must store the commands in a file to be able to use the counters
	local file_tmp_all="$dir_tmp/$NAME_LOWERCASE-commands-all"
	local file_tmp_required="$dir_tmp/$NAME_LOWERCASE-commands-required"
	local file_tmp_optional="$dir_tmp/$NAME_LOWERCASE-commands-optional"

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



	# Automatically detect all commands 
	# For each regex below:
	# - Remove comments
	# - Do regex specific use case
	# - Get all words of the file line by line
	# - Remove everything that is not a char contained in command name
	# - Sort & remove duplications

	# - Get most of "command" from this pattern: command text
	# - Remove text strings inside ""
	local list1="$(cat $file_to_test \
		| sed 's/#.*$//' \
		| sed 's/\([a-z]\) .*/\1/' \
		| sed 's/"[^*]*"//' \
		| sort -ud)"

	# Get "command" from this pattern: "text $(command text"
	local list2="$(cat $file_to_test \
		| sed 's/#.*$//' \
		| sed 's/.*$(\([a-z_-]*\).*/\1/' \
		| grep -v "_" \
		| grep -v "^.$" \
		| grep "^[a-z]" \
		| grep -v "a-z" \
		| grep -v "[=:;.,_)\"\$]" \
		| sort -ud)"

	# Get "command" from this pattern: text | command text
	local list3="$(cat $file_to_test \
		| sed 's/#.*$//' \
		| grep '|[ ]' \
		| tr '|' '\n' \
		| awk '{print $1}' \
		| grep -v "^.$" \
		| grep "^[a-z]" \
		| grep -v "a-z" \
		| grep -v "[=:;.,_)\"\$]" \
		| sort -ud)"

	# Get "command" from this pattern: if command text
	local list4="$(cat $file_to_test \
		| sed 's/#.*$//' \
		| grep 'if' \
		| sed 's/[^ ]* *\([^ ]*\) .*/\1/' \
		| sort -ud)"

	# Get "command" from this pattern: loop command text; do
	local list5="$(cat $file_to_test \
		| sed 's/#.*$//' \
		| grep ';' \
		| grep 'do' \
		| sed 's/[a-z]* \([a-z]* \).*/\1/' \
		| sort -ud)"

	# Get "command" from this pattern: command -
	local list6="$(cat $file_to_test \
		| sed 's/#.*$//' \
		| grep "[a-z] -" \
		| sed 's/\([a-z]*\)[ -].*/\1/' \
		| sort -ud)"

	# Keep only the grepped text from this pattern: text grep text
	local list7="$(cat $file_to_test \
		| sed 's/#.*$//' \
		| grep "grep" \
		| sed 's/.*\(grep\).*/\1/' \
		| sort -ud)"

	local list="$(echo "$list1" \
				&& echo "$list2" \
				&& echo "$list3" \
				&& echo "$list4" \
				&& echo "$list5" \
				&& echo "$list6" \
				&& echo "$list7" \
			)"

	# - Remove functions names
	# - Remove words of 1 char
	# - Remove words that are not commands starting with special chars (careful to the - that can be contained in middle of command names)
	# - Remove words that are not commands containing special chars
	# - Remove words that are not commands ending with special chars
	# - Sort & remove duplications
	echo $list \
		| sed -E 's/\s+/\n/g' \
		| grep -v "^.$" \
		| grep "^[a-z]" \
		| grep -v "a-z" \
		| grep -v "[=:;.,_)\"\$]" \
		| sort -ud > $file_tmp_all



	# # Manually set optional commands
	# echo "\
	# 	less
	# 	pkg-config
	# 	curl
	# 	wget
	# 	systemctl \
	# " | sort -d | tr -d "[:blank:]" > $file_tmp_optional


	# Automatically detect all optional commands
	# Get "command" from this pattern: exists_command "command"
	cat $file_to_test \
		| sed 's/#.*$//' \
		| grep 'exists_command "' \
		| sed 's/.*exists_command "\([a-z-]*\)".*/\1/' \
		| grep -v 'exists_command' \
		| sort -ud > $file_tmp_optional


	# Get required commands
	# local commands_required="$(diff --changed-group-format='%<' --unchanged-group-format='' $file_tmp_all $file_tmp_optional | cut -d " " -f 2)"
	local commands_required="$(comm -23 $file_tmp_all $file_tmp_optional)"
	echo "$commands_required" | sort -d > $file_tmp_required



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


	rm $file_tmp_all
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
		local first_char="$(echo $line | cut -c1-1)"

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




# # Permit to set an option in the main config file to activate or not the automation of a sub command 
# # Usage: command_config_activation <command> <description> <option>
# command_config_activation() {

# 	local command="${1}"
# 	local description="${2}"
# 	local option="${3}"


# 	echo "" >> $file_config
# 	echo $description >> $file_config

# 	set_config_value $file_config $command $option

# 	echo "" >> $file_config
# }




# List available commands from repository
# Usages:
#  command_list
#  command_list <url>
command_list() {

	local list_tmp1="$dir_tmp/$NAME_LOWERCASE-command-list1"
	local list_tmp2="$dir_tmp/$NAME_LOWERCASE-command-list2"
	local url="${1}"
	if [ -z "$url" ]; then
		url="$URL_API/contents/commands"
	fi
	local installed="[installed]"


	loading_process "verify_repository_reachability $url"
	if [ "$(exists_command "curl")" = "exists" ]; then
		loading_process "curl -sL $url" > $list_tmp1
	elif [ "$(exists_command "wget")" = "exists" ]; then			
		loading_process "wget -q $url -O $list_tmp1"
	else
		display_info "displaying installed commands."
		ls $dir_commands | sed "s/\.sh/ $installed/"
	fi


	if [ -f "$list_tmp1" ]; then
		cat $list_tmp1 \
			| grep 'download_url' \
			| sed "s/.*commands\/\(.*\).sh.*/\1/" \
			| sort -ud > $list_tmp2

		while read -r command; do
			if [ "$command" != "" ]; then

				# Checking if the command is already installed
				if [ -f "$dir_commands/$command.sh" ]; then
					echo "$command $installed"
				else
					echo "$command"
				fi
			fi

		done < "$list_tmp2"

		rm $list_tmp1
		rm $list_tmp2
	fi
}




# Get a command from repository
# Usages:
#  command_get <command>
#  command_get <command> <url>
command_get() {

	local command="${1}"
	local file_command="$dir_commands/$command.sh"
	local file_command_tmp="$dir_tmp/$NAME_LOWERCASE-$command.sh"

	if [ -z "$command" ]; then
		display_info "please specify a command from the list below."
		command_list

	elif [ -f "$file_command" ]; then
		display_info "command '$command' is already installed."

	else
		local url="${2}"
		if [ -z "$url" ]; then
			url="$URL_RAW/$VERSION/commands/$command.sh"
		fi

		download_file $url $file_command_tmp
		# download_file $url $file_command

		if [ -f "$file_command_tmp" ]; then
			mv "$file_command_tmp" "$file_command"
			chmod +x $file_command
			chown $OWNER:$OWNER $file_command

			$CURRENT_CLI $command init_command
		fi

		if [ -f $file_command ]; then
			display_success "command '$command' has been installed."
			display_info "'$NAME_ALIAS $command --help' to display help."
		else
			display_error "command '$command' has not been installed."
		fi
	fi
}




# Remove an installed command
# Usage: command_delete <command>
command_delete() {

	local command="${1}"
	local file_command="$dir_commands/$command.sh"

	# Just init to set it local
	local confirmation
	

	if [ -f "$file_command" ]; then

		read -p "$question_continue" confirmation
	
		if [ "$(sanitize_confirmation $confirmation)" = "yes" ]; then
			rm "$file_command"

			# Remove the related sub command options from the main config file
			sed -i '/\[command\] firewall/,/^\s*$/{d}' $file_config

			if [ -f "$file_command" ]; then
				display_error "command '$command' has not been removed."
			else
				display_success "command '$command' has been removed."
			fi
		else
			display_info "uninstallation aborted."
		fi
	else
		display_error "command '$command' not found."
	fi

}




# Update the installed CLI on the system
#
# !!!!!!!!!!!!!!!!!!!!!!!!!
# !!! CRITICAL FUNCTION !!!
# !!!!!!!!!!!!!!!!!!!!!!!!!
#
# /!\	This function must work everytime a modification is made in the code. 
# 		Unless, we risk to not being able to update it on the endpoints where it has been installed.
update_cli() {

	local downloaded_cli="$dir_tmp/$NAME_LOWERCASE.sh"
	local remote_archive="$URL_API/releases/latest"
	local force="${1}"
	local chosen_publication="${2}"

	update_process() {
		display_info "starting self update."

		# Download only the main file (main by default, or the one of the chosen publication if specified)
		if [ -z "$chosen_publication" ]; then
			download_file "$URL_RAW/main/$NAME_LOWERCASE.sh" "$downloaded_cli"
		elif [ "$chosen_publication" = "main" ]; then
			download_file "$HOST_URL_RAW/$NAME_LOWERCASE/main/$NAME_LOWERCASE.sh" "$downloaded_cli"
		else
			download_file "$HOST_URL_RAW/$NAME_LOWERCASE-$chosen_publication/main/$NAME_LOWERCASE.sh" "$downloaded_cli"
		fi


		# Delete old files
		delete_cli "exclude_main"
		
		# Execute the installation from the downloaded file 
		chmod +x "$downloaded_cli"
		"$downloaded_cli" -i

		display_info "end of self update or publication rotation."
	}


	# Option to force update (just bypass the version check)
	# If the newest version already installed, it will just install it again
	if [ "$force" = "force" ]; then
		display_info "using force option."
		update_process
	else
		# Testing if a new version exists on the current publication to avoid reinstall if not.
		if [ "$(exists_command "curl")" = "exists" ] && [ "$(curl -s "$remote_archive" | grep tag_name | cut -d \" -f 4)" = "$VERSION" ] && [ "$(detect_publication)" = "$(get_config_value "$file_config" "publication")" ]; then
			display_info "latest version is already installed ($VERSION-$(detect_publication))."

		elif [ "$(exists_command "wget")" = "exists" ] && [ "$(wget -q -O- "$remote_archive" | grep tag_name | cut -d \" -f 4)" = "$VERSION" ] && [ "$(detect_publication)" = "$(get_config_value "$file_config" "publication")" ]; then
			display_info "latest version is already installed ($VERSION-$(detect_publication))."

		else
			update_process
		fi
	fi
}




# Install the CLI on the system
#
# !!!!!!!!!!!!!!!!!!!!!!!!!
# !!! CRITICAL FUNCTION !!!
# !!!!!!!!!!!!!!!!!!!!!!!!!
#
# /!\	This function must work everytime a modification is made in the code. 
#		Because it's called by the update function.
# Usages: 
#  install_cli
#  install_cli <chosen publication>
install_cli() {

	local chosen_publication="${1}"

	# Test if all required commands are on the system before install anything
	if [ "$(verify_dependencies "$CURRENT_CLI" "print-missing-required-command-only")" = "0" ]; then

		display_info "starting self installation."
		detect_cli

		
		# Config directory installation
		# Checking if the config directory exists and create it if doesn't exists
		# This must be the first thing to do since $chosen_publication needs to be stored in this directory but it would not exists if it's the first time the CLI is installed
		display_info "installing configuration."
		if [ ! -d "$dir_config" ]; then
			display_info "$dir_config not found, creating it."
			mkdir $dir_config
		fi


		# Just a log message
		if [ -n "$chosen_publication" ]; then
			display_info "publication '$chosen_publication' entered manually."
		else
			display_info "using current '$($NAME_ALIAS --publication)' publication."
		fi


		# Check if a publication has been chosen, and allow to reinstall if the specified publication is the same as the current or is empty
		if [ "$chosen_publication" = "" ] || [ "$chosen_publication" = "$($NAME_ALIAS --publication)" ]; then

			# Download tarball archive with the default way
			download_file "$URL_API/tarball/$VERSION" $archive_tmp $archive_dir_tmp

			echo "$($NAME_ALIAS --publication)" > $file_current_publication
		else
			# Force using chosen publication, unless it always will be installed under the main publication
			set_config_value "$file_config" "publication" "$chosen_publication"

			# # Download tarball archive from the given publication
			# download_file "$HOST_URL_API/$NAME_LOWERCASE-$chosen_publication/tarball/$VERSION" $archive_tmp $archive_dir_tmp

			# update_cli
			update_cli -f "$chosen_publication"

			echo "$chosen_publication" > $file_current_publication
		fi


		
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
			cp -RT $archive_dir_tmp $dir_src_cli	# -T used to overwrite the source dir and not creating a new inside
			chmod 555 -R $dir_src_cli				# Set everyting in read+exec by default
			chmod 555 $file_main					# Set main file executable for everyone (autcompletion of the command itself requires it)
			chmod 550 -R "$dir_src_cli/commands/"	# Set commands files executable for users + root
			chmod 444 -R "$dir_src_cli/"*.md		# Set .md files read-only for everyone


			# Create an alias so the listed package are clear on the system (-f to force overwrite existing)
			display_info "installing aliases."
			ln -sf $file_main $file_main_alias_1
			ln -sf $file_main $file_main_alias_2


			# Autocompletion installation
			# Install autocompletion only if the directory has been found.
			if [ -n "$dir_autocompletion" ]; then
				display_info "installing autocompletion."
				cp "$archive_dir_tmp/completion" $file_autocompletion_1
				cp "$archive_dir_tmp/completion" $file_autocompletion_2
			fi

			
			# Systemd services installation
			# Checking if systemd is installed (and do nothing if not installed because it means the OS doesn't work with it)
			if [ "$(exists_command "systemctl")" = "exists" ]; then
			
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


			# Must testing if config file exists to avoid overwrite user customizations 
			if [ ! -f "$file_config" ]; then
				display_info "$file_config not found, creating it. "
				# cp "$archive_dir_tmp/config/$file_config" "$file_config"
				cp "$archive_dir_tmp/config/$NAME_LOWERCASE.conf" "$file_config"

			else
				display_info "$file_config already exists, installing new file and inserting current configured options."
				install_new_config_file
			fi


			# Allow users to edit the configuration
			chmod +rw -R $dir_config


			# Remove unwanted files from the installed sources (keep only main, sub commands and .md files)
			find $dir_src_cli -mindepth 1 -maxdepth 1 -not -name "$NAME_LOWERCASE.sh" -not -name "*.md" -not -name "commands" -exec rm -rf {} +


			# Success message
			if [ "$(exists_command "$NAME_ALIAS")" = "exists" ]; then
				# display_success "$NAME $($NAME_ALIAS --version) ($($NAME_ALIAS --publication)) has been installed."
				display_success "command '$NAME_ALIAS' has been installed."
			else
				# Remove config dir that might have been created just to store the publication name
				rm -rf "$dir_config"

				display_error "$NAME installation failed."
			fi
			
		fi
		

		# Clear temporary files & directories
		rm -rf $dir_tmp/$NAME_LOWERCASE*
		

		display_info "end of self installation."


		# Success message
		if [ "$chosen_publication" = "" ] || [ "$chosen_publication" = "$($NAME_ALIAS --publication)" ]; then
			if [ "$(exists_command "$NAME_ALIAS")" = "exists" ]; then
				display_success "$NAME $($NAME_ALIAS --version) ($($NAME_ALIAS --publication)) is ready."
			fi
		fi

	else
		verify_dependencies
	fi

}




# The options (except --help) must be called with root
case "$1" in
	-p|--publication)				loading_process "detect_publication" ;;
	-i|--self-install)				loading_process "install_cli $2" ;;		# Critical option, see the comments at function declaration for more info	
	-u|--self-update)
		if [ -z "$2" ]; then
									loading_process "update_cli"			# Critical option, see the comments at function declaration for more info
		else
			case "$2" in
				-f|--force)			loading_process "update_cli force" ;;	# Shortcut to quickly reinstall the CLI
			esac
		fi ;;
	--self-delete)					loading_process "delete_all" ;;
	--get-logs)						get_logs "$file_log_main" ;;
	command)
		if [ -z "$2" ]; then
									command_list
		else
			case "$2" in
				-l|--list)			command_list ;;
				-g|--get)			command_get $3 $4 ;;
				-d|--delete)		command_delete $3 ;;
				*)					display_error "unknown option [$1] '$2'."'\n'"$USAGE" && exit ;;
			esac
		fi ;;
	verify)
		if [ -z "$2" ]; then
									loading_process "verify_dependencies $3";  loading_process "verify_files"; loading_process "verify_repository_reachability "$URL_RAW/main/$NAME_LOWERCASE.sh""; loading_process "verify_repository_reachability "$URL_API/tarball/$VERSION""
		else
			case "$2" in
				-f|--files)			loading_process "verify_files $3" ;;
				-d|--dependencies)	loading_process "verify_dependencies $3" ;;
				-r|--repository)	loading_process "verify_repository_reachability "$URL_RAW/main/$NAME_LOWERCASE.sh""; loading_process "verify_repository_reachability "$URL_API/tarball/$VERSION"" ;;
				*)					display_error "unknown option [$1] '$2'."'\n'"$USAGE" && exit ;;
			esac
		fi ;;
	# Since "export -f" is not available in Shell, the helper command below permit to use commands from this file in sub scripts
	helper)
		# The $allow_helper_functions variable must be exported as "true" in sub scripts that needs the helper functions
		# This permit to avoid these commands to be used directly from the command line by the users
		if [ "$allow_helper_functions" != "true" ]; then
			display_error "reserved operation."
		else
			if [ -z "$2" ]; then
				display_error "unknown option [$1] '$2'."'\n'"$USAGE" && exit
			else
				case "$2" in
					loading_process)				loading_process "$3" ;;
					display_success)				display_success "$3" "$4" ;;
					display_error)					display_error "$3" "$4" ;;
					display_info)					display_info "$3" "$4" ;;
					get_logs)						get_logs "$3" ;;
					append_log)						append_log "$3" ;;
					exists_command)					exists_command "$3" ;;
					sanitize_confirmation)			sanitize_confirmation "$3" ;;
					get_config_value)				get_config_value "$3" "$4" ;;
					# command_config_activation)		command_config_activation "$3" "$4" "$5";;
					*)								display_error "unknown option [$1] '$2'."'\n'"$USAGE" && exit ;;
				esac
			fi
		fi ;;
	*)
		# Dynamically get availables commands or display error in case of not found
		if [ "$1" = "$(find $dir_commands/ -name "$1*" -printf "%f\n" | sed "s/.sh//g")" ]; then
			"$dir_commands/$1.sh" "$@"
		else
			display_error "unknown command '$1'."'\n'"$USAGE" && exit
		fi
		;;
esac


# Properly exit
exit

#EOF