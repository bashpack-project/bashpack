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
# export NAME_UPPERCASE="$(echo "$NAME" | tr a-z A-Z)"
export NAME_ALIAS="bp"

export CURRENT_CLI="$0"
export HELPER="$CURRENT_CLI helper"
export OWNER="$(ls -l $CURRENT_CLI | cut -d " " -f 3)"


if [ "$(echo $CURRENT_CLI | grep -v '.sh')" ]; then
	usage_cli="$NAME_ALIAS"
else
	usage_cli="$CURRENT_CLI"
fi
export USAGE="Usage: $usage_cli [COMMAND] [OPTION...] \n$usage_cli --help"


dir_tmp="/tmp"
dir_bin="/usr/local/sbin"
dir_systemd="/lib/systemd/system"

export dir_config="/etc/$NAME_LOWERCASE"
export file_config="$dir_config/$NAME_LOWERCASE.conf"


# Quickly ensure to have a structure for the config file to avoid errors
if [ ! -d "$dir_config" ]; then
	mkdir -p $dir_config
fi

# Quickly ensure to have a config file ready to avoid errors
if [ ! -f "$file_config" ]; then
	echo "" > $file_config
fi


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




# Log creations
if [ ! -d "$dir_log" ]; then
	mkdir -p "$dir_log"
fi
export file_log_main="$dir_log/main.log"



# Display a warning in case of using the script and not a command installed on the system
# Export a variable that permits to avoid this message duplication (because this file is called multiple times over the differents process)
if [ "$WARNING_ALREADY_SENT" != "true" ]; then
	if [ "$CURRENT_CLI" = "./$NAME_LOWERCASE.sh" ]; then
		echo "Warning: currently using '$CURRENT_CLI' which is located at $(pwd)."
		echo ""

		export WARNING_ALREADY_SENT="true"
	fi
fi



if [ "$CURRENT_CLI" = "./$NAME_LOWERCASE.sh" ]; then
	export dir_commands="commands"
else
	export dir_commands="$dir_src_cli/commands"
fi



if [ "$(echo $1 | grep -v '-' )" ]; then
	export CURRENT_SUBCOMMAND="$1"
	export LOG_CURRENT_SUBCOMMAND="$dir_log/$CURRENT_SUBCOMMAND.log"
	export CONFIG_CURRENT_SUBCOMMAND="$dir_config/$CURRENT_SUBCOMMAND.conf"
fi


dir_sourceslist="$dir_config/sources"
# file_sourceslist_cli="$dir_sourceslist/cli.list"
file_sourceslist_subcommands="$dir_sourceslist/subcommands.list"
file_registry="$dir_sourceslist/.subcommands.registry"


subcommands_allowed_extensions="\|sh\|bash"


file_repository_reachable_tmp="$dir_tmp/$NAME_LOWERCASE-last-repository-tested-is-reachable"



# Options that can be called without root
# Display usage in case of empty option
# if [ -z "$@" ]; then
if [ -z "$1" ]; then
	echo "$USAGE"
	exit
else
	case "$1" in
		-v|--version) echo $VERSION && exit ;;
		# command)
		# 	case "$2" in
		# 		--help) echo "$USAGE" \
		# 		&&		echo "" \
		# 		&&		echo "Manage $NAME sub commands." \
		# 		&&		echo "" \
		# 		&&		echo "Options:" \
		# 		&&		echo " -l, --list         list available commands." \
		# 		&&		echo " -g, --get <name>   install a command." \
		# 		&&		echo " -d, --delete       remove a command." \
		# 		&&		echo "" \
		# 		&&		echo "$NAME $VERSION" \
		# 		&&		exit ;;
		# 	esac
		# ;;
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
		-h|--help|help) echo "$USAGE" \
		&&		echo "" \
		&&		echo "Options:" \
		&&		echo " -i, --self-install   install (or reinstall) $NAME on your system as the command '$NAME_ALIAS'." \
		&&		echo " -u, --self-update    update $NAME to the latest available version (--force option available)." \
		&&		echo "     --self-delete    delete $NAME from your system." \
		&&		echo "     --logs           display logs." \
		&&		echo " -h, --help           display this information." \
		&&		echo " -v, --version        display version." \
		&&		echo " -l, --list           list available subcommands (local and remote). " \
		&&		echo " -g, --get <name>     install a subcommand." \
		&&		echo " -n, --new <name>     get a template to create a subcommand." \
		&&		echo " -d, --delete <name>  uninstall a subcommand." \
		&&		echo "" \
		&&		echo "Commands (<command> --help to display usages):" \
		&&		echo "  verify" \
		&&		echo "$(ls $dir_commands 2> /dev/null | sed 's|\..*||' | sed 's|^|  |')" \
		&&		echo "\n$NAME $VERSION" \
		&&		exit ;;
	esac
fi




# Ask for root
set -e
if [ "$(id -u)" != "0" ]; then
	echo "must be runned as root."
	exit
fi




# --- --- --- --- --- --- ---
# Helper functions - begin


# Getting values stored in configuration files.
# Usages:
#  get_config_value "<file>" "<option>"
#  get_config_value "<file>" "<option>" <position>
get_config_value() {

	local file="$1"
	local option="$2"
	local position="$3"


	while read -r line; do
		local first_char="$(echo $line | cut -c1-1)"

		# Avoid reading comments and empty lines
		if [ "$first_char" != "#" ] && [ "$first_char" != "" ]; then
			# Default is to get the "word2" of the line like in this example:
			# word1 word2 word3 ... wordn 
			if [ -z "$position" ]; then
				if [ "$(echo $line | cut -d " " -f 1)" = "$option" ]; then
					echo $line | cut -d " " -f 2
					break
				fi

			# Unless, the $3 will give the position to read
			# word1 word2 word3 ... wordn 
			else
				if [ "$(echo $line | cut -d " " -f 1)" = "$option" ]; then
					echo $line | cut -d " " -f $position
					break
				fi

			fi

		fi	
	done < "$file"
}




# # Getting values stored in configuration files.
# # Usage: get_config_value "<file>" "<option>"
# get_config_value() {
# 	local file="$1"
# 	local option="$2"

# 	while read -r line; do
# 		local first_char="$(echo $line | cut -c1-1)"

# 		# Avoid reading comments and empty lines
# 		if [ "$first_char" != "#" ] && [ "$first_char" != "" ]; then
# 			if [ "$(echo $line | cut -d " " -f 1)" = "$option" ]; then
# 				echo $line | cut -d " " -f 2
# 				break
# 			fi
# 		fi	
# 	done < "$file"
# }




# Display current CLI informations
# Usage: current_cli_info
current_cli_info() {

	# "False" option doesn't really exist as described in the config file, anything other that "true" will just disable this function.
	if [ "$(get_config_value $file_config display_loglevel | grep debug)" ]; then
		# echo " cli:$CURRENT_CLI pub:$PUBLICATION ver:$VERSION   "
		# echo " cli:$CURRENT_CLI ver:$VERSION   "
		echo "cli:$CURRENT_CLI ver:$VERSION "
	fi
}




# Display always the same message in error messages.
# Usages:
#  log_error <message>
#  log_error <message> <log file to duplicate the message>
log_error() {

	# local text="$1"
	local text="$(echo $1 | sed "s|^|$(current_cli_info)|")"
	local format="$now error:    $text"

	if [ "$(get_config_value $file_config display_loglevel | grep error)" ]; then
		echo $text
	fi

	if [ -n "$2" ]; then
		echo "$format" >> "$2"
	else
		echo "$format" >> "$file_log_main"
	fi
}




# Display always the same message in success messages.
# Usages:
#  log_success <message>
#  log_success <message> <log file to duplicate the message>
log_success() {

	# local text="$1"
	local text="$(echo $1 | sed "s|^|$(current_cli_info)|")"
	local format="$now success:  $text"

	if [ "$(get_config_value $file_config display_loglevel | grep success)" ]; then
		echo $text
	fi

	if [ -n "$2" ]; then
		echo "$format" >> "$2"
	else
		echo "$format" >> "$file_log_main"
	fi
}




# Display always the same message in info messages.
# Usages:
#  log_info <message>
#  log_info <message> <log file to duplicate the message>
log_info() {

	# local text="$1"
	local text="$(echo $1 | sed "s|^|$(current_cli_info)|")"
	local format="$now info:     $text"

	if [ "$(get_config_value $file_config display_loglevel | grep info)" ]; then
		echo $text
	fi

	if [ -n "$2" ]; then
		echo "$format" >> "$2"
	else
		echo "$format" >> "$file_log_main"
	fi
}




# Write output of a command in logs
# Usages:
#  <command> | append_log					(append to the default file)
#  <command> | append_log <log file>		(append to the given file)
append_log() {

	local file_log="$1"


	# Format the message
	local text="$(sed "s|^|$(current_cli_info) |")"
	local format="$now op.sys:   "

	# Display the text
	echo $text

	# Append the text to the logs
	if [ -n "$file_log" ]; then
		echo $text | sed "s|^|$format|" >> "$file_log"
	else
		echo $text | sed "s|^|$format|" >> "$file_log_main"
	fi

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
				local command="$directory/$1"

				if [ -f "$command" ]; then
					echo "$command"
				fi
			done
		else 
			for directory_raw in "$(echo "$PATH" | tr ":" "\n" | tr " " "$special_char")"; do
				local directory="$(echo $directory_raw | tr "$special_char" " ")"
				local command="$directory/$1"

				if [ -f "$command" ]; then
					echo "$command"
				fi
			done
		fi
	}

	# Some commands are builtin and doesn't have path on the system.
	# This permits to 
	# - test if any command exists
	# - get the path of the command if it has one
	# - still display an output in case of no path but the command exist
	# - don't display anything if the command doesn't exist at all
	if [ -n "$(command -v "$1")" ]; then
		if [ -n "$(find_path "$1")" ]; then
			find_path "$1"
		else
			echo "$1"
		fi
	fi
	
}




# Function to know if commands exist on the system, with always the same output to easily use it in conditions statements.
# Usage: exists_command <command>
exists_command() {
	local command="$1"

	# if ! which $command > /dev/null; then
	if [ ! -z "$(posix_which "$command")" ]; then
		echo "exists"
	else
		log_error "'$command' command not found"
	fi
}




# loading_process animation so we know the process has not crashed.
# Usage: loading_process "<command that takes time>"
loading_process() {

	$1 & local pid=$!


	if [ "$(exists_command "trap")" = "exists" ] && [ "$(exists_command "tput")" = "exists" ]; then

		# Trap the future CTRL+C to get back the cursor
		trap "tput cnorm" INT

		# Hide cursor
		tput civis
	fi
	

	while ps -T | grep $pid > /dev/null; do
		i=$((i+1))
		# for s in / - \|; do
		# for s in l o a d e r; do
		# for s in . o O °; do
		for s in . .. ... .. . ' '; do
		# for s in '⠋' '⠙' '⠹' '⠸' '⠼' '⠴'  '⠦'  '⠧' '⠇' '⠏'; do
			printf "$s\033[0K\r"

			sleep 0.12
		done
	done


	# Get back the cursor because the process has finished
	if [ "$(exists_command "tput")" = "exists" ]; then
		tput cnorm
	fi
}




# Setting values in configuration file during script execution
# Usage: set_config_value "<file>" "<option>" "<new value>"
set_config_value() {

	local file="$1"
	local option="$2"
	local value_new="$3"
	local value_old="$(get_config_value $file $option)"

	log_info "set '$option' from '$value_old' to '$value_new'."

	# Drop if the option or the value are not given
	if [ -n "$option" ] || [ -n "$value_new" ]; then

		# If both the file and the option exist
		# = Replace the option old value with the new value
		if [ -f "$file" ] && [ -n "$value_old" ]; then
			sed -i "s|$option $value_old|$option $value_new|" "$file"

		# If the file exists but the option doesn't exist
		# = Add the option and the value at the begin of the file (this is a curative way to just quickly get the option setted up)
		elif [ -f "$file" ] && [ -z "$value_old" ]; then
			sed -i "1s|^|$option $value_new|" "$file"

		# If the file doesn't exist (also meaning the option can't exist)
		# = Create the file and add the option with the value (this is a curative way to just quickly get the option setted up)
		elif [ ! -f "$file" ]; then
			echo "$option $value_new" > "$file"
		fi
	else
		log_error "missing option/value combination."
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

	log_info "getting logs from $1"

	if [ "$(exists_command "less")" = "exists" ]; then
		cat "$1" | less +G
	else
		cat "$1"
	fi
}




# Detect if the command has been installed on the system
detect_cli() {
	if [ "$(exists_command "$NAME_ALIAS")" = "exists" ]; then
		if [ -n "$($NAME_ALIAS --version)" ]; then
			# log_info "$NAME $($NAME_ALIAS --version) ($($NAME_ALIAS --publication)) detected at $(posix_which $NAME_LOWERCASE)"
			log_info "'$NAME_ALIAS' $($NAME_ALIAS --version) detected."
		fi
	fi
}




# Permits to verify if the remote repository is reachable with HTTP.
# Usage: verify_repository_reachability <URL>
verify_repository_reachability() {

	local url="$1"

	log_info "try reach: $url"

	if [ "$(exists_command "curl")" = "exists" ]; then
		http_code="$(curl -s -k -L -I -o /dev/null -w "%{response_code}" $url)"
	elif [ "$(exists_command "wget")" = "exists" ]; then
		http_code="$(wget --spider --server-response --no-check-certificate "$url" 2>&1 | awk '/^  HTTP/{print $2}' | tail -n 1)"
	else
		log_error "can't get HTTP code with curl or wget."
	fi

	http_family="$(echo $http_code | cut -c 1)"
	if [ "$http_family" = "1" ] || [ "$http_family" = "2" ] || [ "$http_family" = "3" ]; then
		echo "true" > $file_repository_reachable_tmp
		log_info "[HTTP $http_code] $url is reachable."
	else 
		echo "false" > $file_repository_reachable_tmp
		if [ -z $http_code ]; then
			log_error "$url is not reachable."
		else
			log_error "[HTTP $http_code] $url is not reachable."
		fi
		exit
	fi
}




# Download releases archives from the repository
# Usages:
# - download_file <url of single file> <temp file>
# - download_file <url of n.n.n archive> <temp archive> <temp dir for extraction>
download_file() {

	local file_url="$1"
	local file_tmp="$2"
	local dir_extract_tmp="$3"

	# Testing if repository is reachable with HTTP before doing anything.
	loading_process "verify_repository_reachability $file_url"
	if [ -f "$file_repository_reachable_tmp" ] && [ "$(cat $file_repository_reachable_tmp)" = "true" ]; then

		# Try to download with curl if exists
		if [ "$(exists_command "curl")" = "exists" ]; then
			log_info "downloading sources from '$file_url' with curl."
			loading_process "curl -sLk $file_url -o $file_tmp"
			
		# Try to download with wget if exists
		elif [ "$(exists_command "wget")" = "exists" ]; then
			log_info "downloading sources from '$file_url' with wget."
			loading_process "wget -q --no-check-certificate $file_url -O $file_tmp"

		else
			log_error "could not download '$file_url' with curl or wget."
		fi


		# Success message
		if [ -f "$file_tmp" ]; then
			log_info "file '$file_tmp' downloaded."

			# Test if the "$dir_extract_tmp" variable is empty to know if we downloaded an archive that we need to extract
			if [ -n "$dir_extract_tmp" ]; then
				# Test if the downloaded file is a tarball
				if file "$file_tmp" | grep -q "gzip compressed data"; then
					if [ "$(exists_command "tar")" = "exists" ]; then
					
						# Prepare tmp directory
						rm -rf $dir_extract_tmp
						mkdir -p $dir_extract_tmp

						# "tar --strip-components 1" permits to extract sources in /tmp/$NAME_LOWERCASE and don't create a new directory /tmp/$NAME_LOWERCASE/$NAME_LOWERCASE
						tar -xf "$file_tmp" -C "$dir_extract_tmp" --strip-components 1
					fi
				else
					log_error "file '$file_url' is a non-working tarball and cannot be used, deleting it."
				fi
			fi
		else
			log_error "file '$file_tmp' not downloaded."
		fi
		
	fi
	rm -f $file_repository_reachable_tmp

}




# Dynamically create automation (systemd, cron, ...)
# This can be used from subcommand, in the init_command() function to install automation in the same time that the command has been downloaded
# /!\ If using through $HELPER in subcommands, "$1" must be called to get the subcommand name 
# Usages:
#  <$HELPER> create_automation "$1 <command to launch>"
#  <$HELPER> create_automation "$1 <command to launch>" <name alteration> <description alteration>
create_automation() {

	# Automatically detect command to launch
	if [ -z "$1" ]; then
		log_error "missing subcommand name."
	else
		local command="$NAME_LOWERCASE $1"
	fi

	# Automatically create name based on command to launch if nothing given
	if [ -z "$2" ]; then
		local name="$NAME_LOWERCASE-$(echo "$1" | sed 's/-.*//' | sed 's/ /-/g' | sed 's/-$//')"
	else
		local name="$NAME_LOWERCASE-$2"
	fi

	# Automatically create description based on command to launch if nothing given
	if [ -z "$3" ]; then
		local description="$NAME: $(echo "$1" | sed 's/-.*//')"
	else
		local description="$NAME: $3"
	fi


	local documentation="$NAME_ALIAS --help"


	create_systemd() {
		echo "
			[Unit]
			Description=$description
			Documentation=$documentation

			[Service]
			ExecStart=$command
			KillMode=control-group
			TimeoutStartSec=1800
			TimeoutStopSec=1800
			" | sed 's/^[ \t]*//' > "$dir_systemd/$name.service"
			
		echo "
			[Unit]
			Description=$description
			Documentation=$documentation

			[Timer]
			OnCalendar=daily
			Persistent=true

			[Install]
			WantedBy=multi-user.target
			" | sed 's/^[ \t]*//' > "$dir_systemd/$name.timer"


		systemctl -q daemon-reload
		systemctl -q enable $name.timer
	}


	if [ "$(exists_command "systemctl")" = "exists" ]; then
		create_systemd

		# Log message
		if [ -f "$dir_systemd/$name.service" ] && [ -f "$dir_systemd/$name.timer" ]; then
			log_info "automation $name ready."
		else
			log_error "automation $name not ready."
		fi

	elif [ "$(exists_command "cron")" = "exists" ]; then
		log_error "cron has not been implemented yet."

	else
		log_error "no automation tool available."

	fi
}




# bash-completion doc: https://github.com/scop/bash-completion/blob/main/README.md#faq
# If pkg-config doesn't exist, then the system won't have completion.
if [ "$(exists_command "pkg-config")" = "exists" ]; then

	# Test if completion dir exists to avoid interruption
	if [ -n "$(pkg-config --variable=completionsdir bash-completion)" ]; then
		dir_completion="$(pkg-config --variable=completionsdir bash-completion)"
		file_completion="$dir_src_cli/completion"
		file_completion_alias_1="$dir_completion/$NAME_LOWERCASE"
		file_completion_alias_2="$dir_completion/$NAME_ALIAS"
	fi
fi




# Dynamically create completion for CLI & subcommands with options
# Usage: create_completion <file_command>
create_completion() {

	local file_command="$1"
	local command="$(echo $(basename $file_command))"


	# List all options of any file that is a CLI
	# Usage: get_options <file path>
	get_options() {
		cat $1 | sed 's/.*[ \t|]\(.*\)).*/\1/' | grep '^\-\-' | sort -ud | sed -Ez 's/([^\n])\n/\1 /g'
	}


	if [ "$(exists_command "pkg-config")" = "exists" ]; then
	
		# Install completion only if the directory has been found.
		if [ -d "$dir_completion" ]; then

				if [ "$file_command" = "$CURRENT_CLI" ]; then

				if [ -f "$file_completion" ]; then
					rm -f $file_completion

					if [ -f "$file_completion_alias_1" ]; then
						rm -f $file_completion_alias_1
					fi

					if [ -f "$file_completion_alias_2" ]; then
						rm -f $file_completion_alias_2
					fi
				fi

				echo '_'$NAME_LOWERCASE'() {'																				> $file_completion
				echo '	local cur=${COMP_WORDS[COMP_CWORD]}'																>> $file_completion
				echo '	local prev=${COMP_WORDS[COMP_CWORD-1]}'																>> $file_completion
				echo ''																										>> $file_completion
				echo '	case ${COMP_CWORD} in'																				>> $file_completion
				echo '		1) COMPREPLY=($('$(echo compgen)' -W "'$(echo $(get_options $CURRENT_CLI))'" -- ${cur})) ;;'	>> $file_completion
				echo '		2)'																								>> $file_completion
				echo '		case ${prev} in'																				>> $file_completion
				echo '			_commandtofill) COMPREPLY=($('$(echo compgen)' -W "_optionstofill" -- ${cur})) ;;'			>> $file_completion
				echo '		esac ;;'																						>> $file_completion
				echo '		*) COMPREPLY=() ;;'																				>> $file_completion
				echo '	esac'																								>> $file_completion
				echo '	}'																									>> $file_completion
				echo ''																										>> $file_completion
				echo "complete -F _$NAME_LOWERCASE $NAME_ALIAS"																>> $file_completion
				echo "complete -F _$NAME_LOWERCASE $NAME_LOWERCASE"															>> $file_completion

				ln -sf $file_completion $file_completion_alias_1
				ln -sf $file_completion $file_completion_alias_2

			# else
			elif [ "$(ls $dir_commands/$file_command)" ] && [ -f "$file_completion" ] && [ -z "$(cat $file_completion | grep "$command)")" ]; then
				# Duplicate the line and make it unique with the "new" word to find and replace it with automatics values
				sed -i 's|\(_commandtofill.*\)|\1\n\1new|' $file_completion
				sed -i "s|_commandtofill\(.*new\).*|\t\t\t$command\1|" $file_completion
				sed -i "s|_optionstofill\(.*\)new|$(get_options $dir_commands/$file_command)\1|" $file_completion

				# Add the subcommand itself to the completion
				sed -i "s|\(1) COMPREPLY.*\)\"|\1 $command\"|" $file_completion
			fi

			if [ -f "$file_completion" ] && [ -f "$file_completion_alias_1" ] && [ -f "$file_completion_alias_2" ]; then
				log_info "completion ready."
			else
				log_error "completion not ready."
			fi

		else
			log_error "completion directory not found."
		fi
	fi
}




# Dynamically delete completion of subcommands
# Usage: delete_completion <file_command>
delete_completion() {

	local file_command="$1"
	local command="$(echo $(basename $file_command))"


	# if [ -f "$file_command" ]; then
		if [ -f "$file_completion" ]; then
			# Delete the option of the subcommand
			sed -i "/$command)/d" $file_completion

			# Delete the subcommand itself from the main options
			sed -i "s| $command||" $file_completion
		fi
	# else
	# 	log_error "unknown '$file_command'."
	# fi
}




# Calculate checksum of a given file
# Usages:
#  file_checksum <file path>
#  file_checksum <file URL>
file_checksum() {

	if [ "$(echo $1 | grep -e '^http')" ]; then
		local url="$1"

		if [ "$(exists_command "curl")" = "exists" ]; then
			curl -sk $url | cksum -a sha1 | sed 's/^.*= //'
		elif [ "$(exists_command "wget")" = "exists" ]; then
			wget -q -O - --no-check-certificate $url | cksum -a sha1 | sed 's/^.*= //'
		else
			log_error "can't get '$url' remote checksum with curl or wget."
		fi
	else
		cat $1 | cksum -a sha1 | sed 's/^.*= //'
	fi
}




# Get "API", "raw" or the "default web" Github URL from the others one, or return the given URL because it could be a non Github repo
# Usage: match_url_repository <url> <want: github_api|github_raw|github_web>
match_url_repository() {

	local url="$1"
	local want="$2"


	# Displayed the asked URL according to $want
	get_url() {
		local project="$1"

		if [ "$want" = "github_api" ]; then
			echo "https://api.github.com/repos/$project"
		elif [ "$want" = "github_raw" ]; then
			echo "https://raw.githubusercontent.com/$project"
		elif [ "$want" = "github_web" ]; then
			echo "https://github.com/$project"	
		fi
	}


	# https://api.github.com/repos/maintainer/repository
	if [ "$(echo $url | grep 'com' | grep 'github' | grep 'api')" ]; then
		project="$(echo $url  | cut -d "/" -f 5-6)"
		get_url "$project"

	# https://raw.githubusercontent.com/maintainer/repository
	elif [ "$(echo $url | grep 'com' | grep 'github' | grep 'raw')" ]; then
		project="$(echo $url  | cut -d "/" -f 4-5)"
		get_url "$project"

	# https://github.com/maintainer/repository
	elif [ "$(echo $url | grep 'com' | grep 'github')" ]; then
		project="$(echo $url  | cut -d "/" -f 4-5)"
		get_url "$project"

	# Finally just echo the given URL because it probably means that it's hosted on a basic directory listing web server
	else
		echo $url
	fi
}


# Helper functions - end
# --- --- --- --- --- --- ---




# Delete the installed command from the system
# Usages: 
#  delete_cli
#  delete_cli "exclude_main"
delete_cli() {
	
	# $exclude_main permits to not delete main command "$NAME_ALIAS" and "$NAME_LOWERCASE".
	#	(i) This is useful in case when the CLI tries to update itself, but the latest release is not accessible.
	#	/!\ Unless it can happen that the CLI destroys itself, and then the user must reinstall it.
	#	(i) Any new update will overwrite the "$NAME_ALIAS" and "$NAME_LOWERCASE" command, so it doesn't matter to not delete it during update.
	#	(i) It's preferable to delete all others files since updates can remove files from olders releases 
	local exclude_main="$1"

	if [ "$(exists_command "$NAME_ALIAS")" != "exists" ]; then
		log_info "$NAME is not installed on your system."
	else
		detect_cli

		if [ "$exclude_main" = "exclude_main" ]; then
			# Delete everything except main files and directories
			
			# The "find" command below permits to delete everything in $dir_src_cli except:
			# - main CLI file
			# - "core" directory (because some functions needed for main CLI file are stored in it)
			#
			# Notes: 
			# - "exec rm -rv {} +" is the part that permits to remove the files and directory
			# - "mindepth 1" permits to avoid the $dir_src_cli directory to be itself deleted
			#
			# This command can be used to list concerned files and directories : 
			# find $dir_src_cli -mindepth 1 -maxdepth 1 ! -name "$NAME_LOWERCASE.sh" -print
			# find $dir_src_cli -mindepth 1 -maxdepth 1 ! -name "$NAME_LOWERCASE.sh" -exec rm -rv {} + 2&> /dev/null
			find $dir_src_cli -mindepth 1 -maxdepth 1 -not -name "$NAME_LOWERCASE.sh" -not -name "commands" -exec rm -rf {} +
			# find $dir_src_cli -mindepth 1 -maxdepth 1 -not -name "$NAME_LOWERCASE.sh" -exec rm -rf {} +

		else
			# Delete everything
			rm -rf $file_completion
			rm -rf $file_completion_alias_1
			rm -rf $file_completion_alias_2
			rm -rf $file_main_alias_1
			rm -rf $file_main_alias_2
			rm -rf $dir_src_cli
			rm -rf $dir_log
			rm -rf $dir_config
		fi

		if [ -f "$file_main" ]; then
			if [ "$exclude_main" = "exclude_main" ]; then
				log_info "all sources removed excepted $file_main."
			else
				log_error "$NAME $VERSION located at $(posix_which $NAME_ALIAS) has not been uninstalled." && exit
			fi
		else
			# Simple echo here and not a display function, because there will no more logs files
			echo "uninstallation completed."
		fi
	fi
}




# Delete the installed systemd units from the system
delete_systemd() {

	if [ "$(exists_command "$NAME_ALIAS")" = "exists" ] && [ "$(exists_command "systemctl")" = "exists" ]; then

		# Stop, disable and delete all systemd units
		for file in $(ls $dir_systemd/$NAME_LOWERCASE* | grep ".timer"); do
			if [ -f $file ]; then
				log_info "$file found."

				local unit="$(basename "$file")"

				systemctl -q stop $unit
				systemctl -q disable $unit
				rm -f $file

				if [ -f $file ]; then
					log_error "$file not removed."
				else
					log_info "$file removed."
				fi
			else
				log_error "$file not found."
			fi
		done

		systemctl -q daemon-reload
	fi
}




# Check if all the files and directories that compose the CLI exist 
# Usages:
#  verify_files
#  verify_files <file to test>
verify_files() {

	log_info  "checking if required files and directories are available on the system."

	local file_to_test="$1"
	if [ -z "$file_to_test" ]; then
		file_to_test="$CURRENT_CLI"
	fi

	# local filters_example="text1\|text2\|text3\|text4" 
	local filters_wanted="=" 
	local filters_unwanted="local \|tmp/" # the space is important for "local " otherwise it can hide some /usr/local/ paths, but the goal is just to avoid local functions variables declarations

	local found=0
	local missing=0
	local total=0

	# Just init variable to set it local
	local previous_path


	# Automatically detect every files and directories used in the CLI (every paths that we want to test here must be used through variables from this file)
	while read -r line; do
		if [ -n "$(echo $line | grep -v '^#' | grep "$filters_wanted" | grep -v "$filters_unwanted" | grep "file_" | grep -v "\$file")" ] || [ -n "$(echo $line | grep -v '^#' | grep "$filters_wanted" | grep -v "$filters_unwanted" | grep "dir_" | grep -v "\$dir")" ]; then

			local path_variable="$(echo $line | cut -d "=" -f 1 | sed s/"export "//)"

			# Just init variable to set it local
			local path_value
			eval path_value=\$$path_variable

			if [ -n "$path_value" ]; then
				if [ "$previous_path" != "$path_variable" ]; then

					if [ -f "$path_value" ]; then
						# log_success "found file -> $path_variable -> $path_value"
						echo "found file -> $path_value" | append_log
						found=$((found+1))
					elif [ -d "$path_value" ]; then
						# log_success "found dir  -> $path_variable -> $path_value"
						echo "found dir. -> $path_value" | append_log
						found=$((found+1))
					else
						# log_error "miss.      -> $path_variable -> $path_value"
						echo "miss.      -> $path_value" | append_log
						missing=$((missing+1))
					fi
				
					total=$((total+1))
				fi
			fi

			# Store current path as the next previous path to be able to avoid tests duplication
			previous_path="$path_variable"

		fi
	done < "$file_to_test"

	log_info "$found/$total paths found."

	if [ "$missing" != "0" ]; then
		log_error "at least one file or directory is missing."
	fi
}




# Check if all the required commands are available on the system
# Usages: 
#  verify_dependencies <file to test>
#  verify_dependencies <file to test> "print-missing-required-command-only"
verify_dependencies() {

	local file_to_test="$1"
	if [ -z "$file_to_test" ]; then
		file_to_test="$CURRENT_CLI"
	fi	

	local print_missing_required_command_only="$2"
	if [ "$print_missing_required_command_only" = "print-missing-required-command-only" ]; then
		print_missing_required_command_only="true"
	else
		log_info "checking if required commands are available on the system."
	fi

	
	# Must store the commands in a file to be able to use the counters
	local file_tmp_all="$dir_tmp/$NAME_LOWERCASE-commands-all"
	local file_tmp_required="$dir_tmp/$NAME_LOWERCASE-commands-required"
	local file_tmp_external="$dir_tmp/$NAME_LOWERCASE-commands-external"

	local found=0
	local missing=0
	local missing_required=0
	local total=0


	# Permits to find all the commands listed in a file (1 line = 1 command)
	# Usage: find_command <file>
	find_command() {
		local file_tmp="$1"
		local type="$2"		# "required" or "external" command

		while read -r command; do
			if [ "$(exists_command "$command")" = "exists" ]; then

				if [ "$print_missing_required_command_only" != "true" ]; then
					# log_info "found ($type) $command"
					echo "found ($type) $command" | append_log
				fi

				found=$((found+1))
			else 
				if [ "$print_missing_required_command_only" != "true" ]; then
					# log_info "miss. ($type) $command"
					echo "miss. ($type) $command" | append_log
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
	# - Remove text from this pattern: "text"
	# - Remove this pattern (to avoid unique words that starts a line and could be detected as a command):
	#       echo " \
	#         text
	#         text
	#         text
	#       " | sed
	local list1="$(cat $file_to_test \
		| sed 's/#.*$//' \
		| sed -n '/echo \" \\/, /\" \| sed /!p' \
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

	# Get "command" from this pattern: while command text
	local list5="$(cat $file_to_test \
		| sed 's/#.*$//' \
		| grep 'while' \
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


	# Automatically detect all external commands
	# Get "command" from this pattern: exists_command "command"
	cat $file_to_test \
		| sed 's/#.*$//' \
		| grep 'exists_command "' \
		| sed 's/.*exists_command "\([a-z-]*\)".*/\1/' \
		| grep -v 'exists_command' \
		| sort -ud > $file_tmp_external


	# Get required commands
	# local commands_required="$(diff --changed-group-format='%<' --unchanged-group-format='' $file_tmp_all $file_tmp_external | cut -d " " -f 2)"
	local commands_required="$(comm -23 $file_tmp_all $file_tmp_external)"
	echo "$commands_required" | sort -d > $file_tmp_required



	find_command $file_tmp_required "required"
	find_command $file_tmp_external "external"


	if [ "$print_missing_required_command_only" != "true" ]; then
		
		log_info "$found/$total commands found."	

		if [ "$missing_required" = "0" ] && [ "$missing" != "0" ]; then
			log_error "at least one external command is missing but will not prevent proper functioning."
		elif [ "$missing_required" != "0" ]; then
			log_error "at least one required command is missing."
		fi
	else
		echo $missing_required		
	fi


	rm $file_tmp_all
	rm $file_tmp_required
	rm $file_tmp_external
}




# Declare config file and default values
# Usage: declare_config_file
declare_config_file() {

	local file="$1"

	# Create temporary config file to be able to copy new options to the current config file
	echo " \
		# This is the main $NAME configuration file.
		# Here are provided defaults options, and their values can be changed according to your needs.
		# This file can meet several modifications within futures updates.
		# Any value configured here will remain after updates.
		# Any comment starting with '#' that are not part of the CLI will be removed.

		# How to use ?
		# A single space is necessary to match options with their values:
		# <option> <value>

		# [option] cli_url
		# Declare remote repository of the CLI itself to get futures updates.
		cli_url "https://github.com/$NAME_LOWERCASE-project/$NAME_LOWERCASE"

		# [option] display_loglevel
		# Display various information during CLI execution.
		# Available values: error,success,info,debug
		# All the values can be used at the same time. Don't set any whitespace.
		display_loglevel error,success,info
		" | sed 's/^[ \t]*//' > "$file"
}




# This function will install the new config file given within new versions, while keeping user configured values
# Usage: rotate_config_file
rotate_config_file() {

	local file_config_current="$file_config"
	# local file_config_tmp="$archive_dir_tmp/config/$NAME_LOWERCASE.conf"
	local file_config_tmp="$dir_tmp/$NAME_LOWERCASE.conf"

	while read -r line; do
		local first_char="$(echo $line | cut -c1-1)"

		# Avoid reading comments and empty lines
		if [ "$first_char" != "#" ] && [ "$first_char" != "" ]; then

			option=$(echo $line | cut -d " " -f 1)
			value=$(echo $line | cut -d " " -f 2)

			# Replacing options values in temp config file with current configured values
			# sed here using "|" instead of "/" to be able to store URL in the values without getting a sed error
			sed -i "s|^$option.*|$line|g" $file_config_tmp

		fi	
	done < "$file_config_current"

	cp $file_config_tmp $file_config_current

}




# # Permits to set an option in the main config file to activate or not the automation of a sub command 
# # Usage: command_config_activation <command> <description> <option>
# command_config_activation() {

# 	local command="$1"
# 	local description="$2"
# 	local option="$3"


# 	echo "" >> $file_config
# 	echo $description >> $file_config

# 	set_config_value $file_config $command $option

# 	echo "" >> $file_config
# }




# # Display all sources from sourceslist
# # Usage: display_sourceslist <sourceslist file>
# display_sourceslist() {

# 	local file="$1"

# 	grep '^http' $file
# }




# Install required directories and files related to subcommands
# Usage: sourceslist_install_structure
sourceslist_install_structure() {

	# Ensure that sources directory exists
	if [ ! -d "$dir_sourceslist" ]; then
		log_info "$dir_sourceslist not found, creating it."
		mkdir -p $dir_sourceslist
	fi

	# # Ensure that sources list exists for CLI
	# if [ ! -f "$file_sourceslist_cli" ] || [ -z "$file_sourceslist_cli" ]; then
	# 	log_info "$file_sourceslist_cli not found, creating it."
	# 	echo "$URL_RAW" > $file_sourceslist_cli
	# fi

	# Ensure that sources list exists for subcommands
	if [ ! -f "$file_sourceslist_subcommands" ] || [ -z "$file_sourceslist_subcommands" ]; then
		log_info "$file_sourceslist_subcommands not found, creating it."
		echo "$(match_url_repository "https://github.com/$NAME_LOWERCASE-project/commands" github_raw)/refs/heads/main/commands" > $file_sourceslist_subcommands
	fi

	# Ensure that registry exists for subcommands
	if [ ! -f "$file_registry" ]; then
		echo -n "" > $file_registry
	fi
}




# List available commands from repository
# Usage:
#  subcommand_list
#  subcommand_list <local>
#  subcommand_list <refresh-only>
subcommand_list() {

	local list_tmp="$dir_tmp/$NAME_LOWERCASE-commands-list"
	# local list_installed_tmp="$dir_tmp/$NAME_LOWERCASE-commands-installed"

	local installed="[installed]"
	local updatable="[update available]"


	# # Detect installed subcommands
	# if [ -d "$dir_commands" ] && [ ! -z "$(ls $dir_commands)" ]; then
	# 	ls $dir_commands > $list_installed_tmp
	# fi


	# If "local" is not precised in arguments, then it means that we want to list remotes command too
	if [ "$1" != "local" ]; then

		sourceslist_install_structure


		# Clean existing registry (it will be updated with fresh values)
		echo -n "" > $file_registry


		if [ -f "$file_sourceslist_subcommands" ] && [ -s "$file_sourceslist_subcommands" ]; then

			for url in $(grep '^http' $file_sourceslist_subcommands); do
				
				# In case of commands repository is on Github, getting accurate URL
				# (because api.github.com and raw.githubusercontent.com have themselves their usages, and we need to always have api.github.com for this usecase)
				if [ "$(echo $url | grep '.com' | grep 'github' | grep 'raw.')" ]; then
					project="$(echo $url  | cut -d "/" -f 4-5)"
					end_of_url="$(echo $url  | cut -d "/" -f 9-99)"
					url="https://api.github.com/repos/$project/contents/$end_of_url"
				fi


				loading_process "verify_repository_reachability $url"
				if [ -f "$file_repository_reachable_tmp" ] && [ "$(cat $file_repository_reachable_tmp)" = "true" ]; then

					if [ "$(exists_command "curl")" = "exists" ]; then
						loading_process "curl -sLk $url" > $list_tmp
					elif [ "$(exists_command "wget")" = "exists" ]; then			
						loading_process "wget -q --no-check-certificate $url -O $list_tmp"
					else
						log_error "can't list remotes commands with curl or wget."
					fi
				fi
				rm -f $file_repository_reachable_tmp


				if [ -f "$list_tmp" ]; then
					# If commands are from a Github repository...
					# URL will always be "api.github.com" thanks to the hook just before
					if [ "$(echo $url | grep '.com' | grep 'github' | grep 'api.')" ]; then
						while read -r line; do
							if [ "$(echo $line | grep 'download_url')" ]; then
								# And get back the raw URL to be able to download the script from sourceslist + calculate checksum
								local real_url="$(echo $line | grep 'download_url' | cut -d '"' -f 4)"
								local checksum="$(file_checksum $real_url)"

								echo $line \
									| cut -d "\"" -f 4 \
									| cut -d "/" -f 8 \
									| grep -iw "\.$subcommands_allowed_extensions" \
									| sed "s|$| $real_url $checksum|" \
									| sort -u >> $file_registry
							fi
						done < $list_tmp
					else
						# ...Or from a basic web server with directory listing
						while read -r line; do

							local file_name="$(echo $line \
								| grep -oP '(?<=href=")[^"]*' \
								| sed '/\/.*/d' \
								| sed '/^\(?.=\).*/d' \
								| grep -iw "\.$subcommands_allowed_extensions")"

							# Get the entire file URL to be able to calculate checksum
							local real_url="$url/$file_name"
							local checksum="$(file_checksum $real_url)"

							echo $line \
								| grep -oP '(?<=href=")[^"]*' \
								| sed '/\/.*/d' \
								| sed '/^\(?.=\).*/d' \
								| grep -iw "\.$subcommands_allowed_extensions" \
								| sed "s|$| $real_url $checksum|" \
								| sort -u >> $file_registry
						done < $list_tmp

						# cat $list_tmp \
						# 	| grep -oP '(?<=href=")[^"]*' \
						# 	| sed '/\/.*/d' \
						# 	| sed '/^\(?.=\).*/d' \
						# 	| grep -iw "\.$subcommands_allowed_extensions" \
						# 	| sed "s/\.[$subcommands_allowed_extensions]*//" \
						# 	| sed "s|$| $url|" \
						# 	| sort -u >> $file_registry
					fi

					rm -f $list_tmp
				fi

			done


			# # Detect remotes subcommands
			# if [ -f "$file_registry" ]; then
			# 	cat $file_registry | sed 's/ .*//' >> $list_installed_tmp
			# fi

		else
			log_error "'$file_sourceslist_subcommands' is empty."
		fi
	fi

	# # Detect installed subcommands
	# if [ -d "$dir_commands" ] && [ ! -z "$(ls $dir_commands)" ]; then
	# 	ls $dir_commands >> $list_installed_tmp
	# fi


	# If "refresh-only" is precised in arguments, then it means that we only want to refresh the registry and not display the list
	if [ "$1" != "refresh-only" ]; then


		# Finally display all the subcommands and specify if already installed
		if [ -f "$file_registry" ] && [ -s "$file_registry" ]; then

			log_info "reading registry."
			
			while read -r line; do
				if [ "$line" != "" ]; then

					# local command_formatted="$(echo $line | sed 's/\.\(.*\)/ [\1]/')"
					local command_formatted="$(echo $line | sed 's|\.\(.*\) http.*| [\1]|')"
					# local command_formatted="$(echo $line | sed 's| .*||' | sed 's|\(.*\)\.\(.*\)|[\2] \1|')"
					# local command_formatted=$command

					local file_command="$(echo $line | sed 's| .*||')"

					# Checking if the subcommand is already installed
					if [ -f "$dir_commands/$file_command" ]; then

						local command_checksum_known="$(file_checksum "$dir_commands/$file_command")"
						local command_checksum_remote="$(file_checksum $(get_config_value $file_registry $file_command 2))"

						if [ "$command_checksum_known" = "$command_checksum_remote" ]; then
							echo "$command_formatted $installed"
						else
							echo "$command_formatted $installed $updatable"
						fi

					else
						echo "$command_formatted"
					fi

					
				fi
			done < $file_registry | sort -ud

			# rm -f $list_installed_tmp
		else
			log_error "no command found."
		fi


		# # Finally display all the subcommands and specify if already installed
		# if [ -f "$list_installed_tmp" ] && [ -s "$list_installed_tmp" ]; then

		# 	log_info "reading registry."
			
		# 	while read -r command; do
		# 		if [ "$command" != "" ]; then

		# 			local command_formatted="$(echo $command | sed 's/\.\(.*\)/ [\1]/')"

		# 			# Checking if the subcommand is already installed
		# 			if [ -f "$dir_commands/$command" ]; then

		# 				local command_checksum_known="$(file_checksum "$dir_commands/$command")"
		# 				local command_checksum_remote="$(file_checksum $(get_config_value $file_registry $command 2))"

		# 				if [ "$command_checksum_known" = "$command_checksum_remote" ]; then
		# 					echo "$command_formatted $installed"
		# 				else
		# 					echo "$command_formatted $installed $updatable"
		# 				fi
		# 			else
		# 				echo "$command_formatted"
		# 			fi

					
		# 		fi
		# 	done < $list_installed_tmp | sort -d

		# 	# rm -f $list_installed_tmp
		# else
		# 	log_error "no command installed."
		# fi
	fi

}




# Get a command from repository
# Usage: subcommand_get <command>
subcommand_get() {

	local command="$1"
	local file_command="$dir_commands/$command.sh"
	# local file_command="$dir_commands/$command.$subcommands_allowed_extensions"



	subcommand_install() {
		# Ensure that structure exists
		sourceslist_install_structure

		# # Ensure that registry is not empty to get the URL of the command
		# if [ "$(cat $file_registry)" = "" ]; then
		# 	subcommand_list
		# fi

		# Refresh list according to sources list (repositories might be commented or removed since last time)
		subcommand_list refresh-only

		local url="$(get_config_value $file_registry $command.sh)"
		download_file $url $file_command

		if [ -f "$file_command" ]; then
			chmod 554 $file_command
			chown $OWNER:$OWNER $file_command

			# Detect if the command needs to be initialised
			if [ "$(cat $file_command | grep -v '^#' | grep 'init_command()')" ]; then
				$CURRENT_CLI $command init_command
			fi

			log_success "command '$command' installed."

			# Detect if the command have a help command
			if [ "$(cat $file_command | grep -v '^#' | grep 'display_help()')" ]; then
				log_info "'$NAME_ALIAS $command --help' to display usage."
			fi
		else
			log_error "command '$command' not installed."
		fi
	}



	# Creating command directory if not exists
	if [ ! -d "$dir_commands" ]; then
		mkdir $dir_commands

		# Set commands files executable for users + root
		chmod 554 -R $dir_commands
		chown $OWNER:$OWNER $dir_commands
	fi


	if [ -z "$command" ]; then
		echo "please specify a command from the list below." | append_log
		subcommand_list

	elif [ -f "$file_command" ]; then

		subcommand_list refresh-only

		
		# Detect if another version of the subcommand is available
		# This also allow to detect if a different file is available on a different repository (and it's impacted by the order of URL in the sources list, the first URL have the priority)
		local command_checksum_known="$(file_checksum $file_command)"
		local command_checksum_remote="$(file_checksum $(get_config_value $file_registry $command 2))"

		if [ "$command_checksum_known" != "$command_checksum_remote" ]; then
			echo "'$command' new version detected." | append_log

			subcommand_install
		else
			echo "'$command' already up to date." | append_log
		fi

	else

		subcommand_install
	fi
}




# Remove an installed command
# Usages: 
#  subcommand_delete <command>
#  subcommand_delete <command> <-y>
subcommand_delete() {

	local command="$1"
	local file_command="$dir_commands/$command.sh"
	# local file_command="$dir_commands/$command.$subcommands_allowed_extensions"

	local confirmation="$2"


	if [ -f "$file_command" ]; then

		if [ "$confirmation" != "-y" ]; then
			read -p "$question_continue" confirmation
		else
			confirmation="yes"
		fi


		if [ "$(sanitize_confirmation $confirmation)" = "yes" ]; then
			rm -f "$file_command"

			# # Delete the related sub command options from the main config file
			# sed -i "/\[command\] $command/,/^\s*$/{d}" $file_config


			# Delete completion configuration of the subcommand
			delete_completion $file_command

			if [ -f "$file_command" ]; then
				log_error "command '$command' not removed."
			else
				log_success "command '$command' removed."
			fi
		else
			echo "uninstallation aborted." | append_log
		fi
	else
		log_error "command '$command' not found."
	fi

}




# Get the template to write a new subcommand
# Usage: subcommand_new <name> <author>
subcommand_new() {

	local file_subcommand="$dir_commands/$1.sh"


	if [ -f "$file_subcommand" ]; then
		echo "$file_subcommand already exists." | append_log
	else
		echo " \
			#!/bin/sh


			export allow_helper_functions="true"
			command_name=\$(echo \$(basename \$1))




			# Display help
			# Usage: display_help
			display_help() {
				echo \" \\
					# to fill
					# to fill
					# to fill
				\" | sed 's/^[ \\\t]*//'

			}




			# Install requirements of the subcommand
			# This function is intended to be used from \$CURRENT_CLI with this syntax: \$CURRENT_CLI \$command init_command
			# (it will only work if init_command is available as an argument with the others options)
			# Usage: \$CURRENT_CLI \$subcommand init_command
			init_command() {
				echo 'to fill or to remove: create file, automation or anything that needs to be in place during the install of the subcommand'
				# echo "tmp text" > \$dir_tmp/\$file_tmp
				# \$HELPER create_automation \$command_name
				# \$HELPER create_completion \$command_name
			}




			echo 'the work goes here'




			if [ ! -z "\$2" ]; then
				case "\$2" in
					init_command)	init_command ;;
					--help)		display_help ;;
					*)		\$HELPER display_error "unknown option '$2' from '$1' command."'\\\n'"\$USAGE" && exit ;;
				esac
			else
				display_help
			fi




			# Properly exit
			exit

			#EOF" | sed 's/\t\t\t//' > "$file_subcommand"


			chown $OWNER:$OWNER $file_subcommand
			chmod +x $file_subcommand
		fi

}




# Function to get the latest available version from the remote repository
# Usage: get_latest_version
get_latest_version() {

	# local cli_url="$(get_config_value $file_config cli_url)"
	local cli_url="$1"

	# Check from Github if the repository is a Github URL
	if [ "$(echo $cli_url | grep 'github' | grep 'com')" ]; then

		local url_latest="$(match_url_repository $cli_url github_api)/releases/latest"

		if [ "$(exists_command "curl")" = "exists" ]; then
			# echo "$(curl -s "$url_latest" | grep tag_name | cut -d \" -f 4)"
			local version_found="$(curl -s "$url_latest" | grep tag_name | cut -d \" -f 4)"

		elif [ "$(exists_command "wget")" = "exists" ]; then
			# echo "$(wget -q -O- "$url_latest" | grep tag_name | cut -d \" -f 4)"
			local version_found="$(wget -q -O- "$url_latest" | grep tag_name | cut -d \" -f 4)"
		fi
	else
		log_error "can't get version from $url_latest."
	fi

	# Get current $VERSION if can't reach the remote version in case of API reach limit to avoid having none data where this function is used
	if [ -z "$version_found" ]; then
		echo $VERSION
	else
		echo $version_found
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
# Usages:
#  update_cli
#  update_cli <force>
update_cli() {

	local downloaded_cli="$dir_tmp/$NAME_LOWERCASE.sh"
	local cli_url="$(get_config_value $file_config cli_url)"
	local force="$1"


	# Ensure the $cli_url value is starting with HTTP, unless the rest of the function will not works due to automatic values calculations from URL format
	if [ "$(echo $cli_url | grep -v '^http')" ]; then
		cli_url="$(echo 'http://'$cli_url)"
	fi
	

	# Function to update the CLI
	# Usage: update_process
	update_process() {

		log_info "starting self update."


		# Get the URL of the file to download
		# If the remote repository is Github
		if [ "$(echo $cli_url | grep 'github' | grep 'com')" ]; then
			local url_file_to_download="$(match_url_repository $cli_url github_raw)/refs/tags/$(get_latest_version $cli_url)/$NAME_LOWERCASE.sh"

		# If the remote repository is a basic directory listing web server
		else
			local url_file_to_download="$cli_url"
		fi


		if [ ! -z "$url_file_to_download" ]; then
	
			# Download the file from the configured URL
			download_file "$url_file_to_download" "$downloaded_cli"

			if [ -f "$downloaded_cli" ]; then
				# Delete old files
				delete_cli "exclude_main"
				
				# Execute the installation from the downloaded file 
				chmod +x "$downloaded_cli"
				"$downloaded_cli" -i
			else
				log_error "file '$downloaded_cli' not found, aborting."
			fi
		fi

		log_info "end of self update."
	}


	# # Get the URL of the file to download
	# # If the remote repository is Github
	# if [ "$(echo $cli_url | grep 'github' | grep 'com')" ]; then
	# 	local url_file_to_download="$(match_url_repository $cli_url github_raw)/refs/tags/$(get_latest_version $cli_url)/$NAME_LOWERCASE.sh"

	# # If the remote repository is a basic directory listing web server
	# else
	# 	local url_file_to_download="$cli_url"
	# fi


	# Option to force update (just bypass the version check)
	# If the newest version already installed, it will just install it again
	if [ "$force" = "force" ]; then
		log_info "using force option."
		update_process
	else
		# Testing if a new version exists on the current publication to avoid reinstall if not.
		if [ "$(get_latest_version $cli_url)" = "$VERSION" ]; then
			log_error "latest version is already installed ($VERSION)."

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
#  install_cli <url of remote repository>
install_cli() {

	# Overwrite the cli_url option from the config file
	local url="$1"

	# Test if all required commands are on the system before install anything
	if [ "$(verify_dependencies "$CURRENT_CLI" "print-missing-required-command-only")" = "0" ]; then

		# Must store the log text in a variable because the display_loglevel option doesn't exist for now (because config file doesn't exist)
		local future_log_start_install="starting self installation"

		# detect_cli



		# Config directory installation
		# Checking if the config directory exists and create it if doesn't exists
		if [ ! -d "$dir_config" ]; then
			# Must store the log text in a variable because the display_loglevel option doesn't exist for now (because config file doesn't exist)
			local future_log_dir_config="$dir_config not found, creating it."

			mkdir -p $dir_config
		fi


		# Must testing if config file exists to avoid overwrite user customizations 
		if [ ! -f "$file_config" ]; then
			# Must store the log text in a variable because the display_loglevel option doesn't exist for now (because config file doesn't exist)
			local future_log_file_config="$file_config not found, creating it. "

			declare_config_file "$file_config"
		else
			log_info "$file_config already exists, installing new file and inserting current configured options."

			declare_config_file "$dir_tmp/$NAME_LOWERCASE.conf"
			rotate_config_file
		fi


		# Test again if config file exists to be 100% sure to be able to use the display_loglevel 
		if [ -f "$file_config" ]; then
			if [ ! -z "$future_log_start_install" ]; then
				log_info "$future_log_start_install"
			fi
			if [ ! -z "$future_log_dir_config" ]; then
				log_info "$future_log_dir_config"
			fi
			if [ ! -z "$future_log_file_config" ]; then
				log_info "$future_log_file_config"
			fi
		fi


		# Depending on what version an update is performed, it can happen that cp can't overwrite a previous symlink
		# Remove them to allow installation of the CLI
		if [ -f "$file_main_alias_1" ] || [ -f "$file_main_alias_2" ]; then
			rm -f $file_main_alias_1
			if [ ! -f "$file_main_alias_1" ]; then
				log_info "file '$file_main_alias_1' removed."
			fi

			rm -f $file_main_alias_2
			if [ ! -f "$file_main_alias_2" ]; then
				log_info "file '$file_main_alias_2' removed."
			fi
		fi


		# Sources files installation
		if [ ! -d "$dir_src_cli" ]; then
			log_info "$dir_src_cli not found, creating it."
			mkdir -p $dir_src_cli
		fi

		# Download + install the CLI from another repository...
		# ...from the given URL
		if [ "$(echo $url | grep '^http')" ]; then		
			set_config_value $file_config "cli_url" $url
			update_cli "force"

		# ...from an official but not "main" repository by using a shortcut
		elif [ "$url" = "unstable" ] || [ "$url" = "dev" ]; then

			local publication="$url"

			# Get the URL that allows to get the last version number
			local url="$(match_url_repository https://github.com/$NAME_LOWERCASE-project/$NAME_LOWERCASE-$publication github_api)"
			local latest_version_of_repository="$(get_latest_version $url)"

			# Get the URL that allows to get the CLI file of the given version found before
			local url="$(match_url_repository https://github.com/$NAME_LOWERCASE-project/$NAME_LOWERCASE-$publication github_raw)/refs/tags/$latest_version_of_repository/$NAME_LOWERCASE.sh"

			set_config_value $file_config "cli_url" "$url"
			update_cli "force"

		# Or do the basic offline installation
		else
			cp -f $CURRENT_CLI $file_main
		fi

		if [ -f "$file_main" ]; then
			log_info "file '$file_main' installed."
		fi


		# Create aliases to use this script as a CLI
		# (-f to force overwrite existing)
		ln -sf $file_main $file_main_alias_1
		ln -sf $file_main $file_main_alias_2
		if [ -f "$file_main_alias_1" ]; then
			log_info "file '$file_main_alias_1' installed."
		fi
		if [ -f "$file_main_alias_2" ]; then
			log_info "file '$file_main_alias_2' installed."
		fi


		# Creating License file
		echo "$(cat $CURRENT_CLI | grep -A 21 "MIT License" | head -n 21)" > "$dir_src_cli/LICENSE.md"


		# Autocompletion installation
		create_completion $CURRENT_CLI


		# Delete all automations because some of them might have changed
		# if [ "$(ls $dir_systemd/$NAME_LOWERCASE*)" ]; then
		if [ "$(ls $dir_systemd/$NAME_LOWERCASE*)" ]; then
			rm -f $dir_systemd/$NAME_LOWERCASE*
		fi

		# Reinstall all automations and completion of the subcommands
		if [ -d "$dir_commands" ]; then
			if [ "$(ls $dir_commands)" ]; then
				for command in $dir_commands/*; do

					# echo $command
					# echo $dir_commands/$command

					local command_name="$(echo $command | sed 's|^.*/\(.*\)\..*|\1|')"

					# Ensure the command needs to be initialized
					if [ "$(cat $command | grep 'init_command()')" ]; then

						# Create automations
						for automation in "$(cat $command | grep create_automation | grep -v '^#' | sed 's|^.*$HELPER ||' | sed 's|$command_name|'$command_name'|')"; do
							$automation
						done
						
						# Create completion
						for completion in "$(cat $command | grep create_completion | grep -v '^#' | sed 's|^.*$HELPER ||' | sed 's|$command_name|'$command_name'|')"; do
							$completion
						done
					fi
				done
			fi
		fi

		# Self update automation
		create_automation "--self-update" "self-update" "automatically update $NAME CLI."


		# Install sourceslist
		sourceslist_install_structure


		# Remove unwanted files from the installed sources (keep only main, sub commands and .md files)
		# find $dir_src_cli -mindepth 1 -maxdepth 1 -not -name "$NAME_LOWERCASE.sh" -not -name "*.md" -not -name "commands" -exec rm -rf {} +


		# Set the rights rights ;)
		chmod 555 -R $dir_src_cli				# Set everyting in read+exec by default
		chmod 555 $file_main					# Set main file executable for everyone (autcompletion of the command itself requires it)
		chmod 444 -R "$dir_src_cli/"*.md		# Set .md files read-only for everyone
		chmod +rw -R $dir_config				# Allow users to edit the configuration


		# Success message
		if [ "$(exists_command "$NAME_ALIAS")" = "exists" ]; then
			log_success "'$NAME_ALIAS' $($NAME_ALIAS --version) installed."
		else
			# Remove config dir that might have been created
			rm -rf "$dir_config"
			log_error "$NAME installation failed."
		fi


		# Clear temporary files & directories
		rm -rf $dir_tmp/$NAME_LOWERCASE*


		log_info "end of self installation."

	else
		verify_dependencies
	fi

}




# The options (except --help) must be called with root
case "$1" in
	-i|--self-install)				loading_process "install_cli $2" ;;		# Critical option, see the comments at function declaration for more info	
	-u|--self-update)
		if [ -z "$2" ]; then
									loading_process "update_cli"			# Critical option, see the comments at function declaration for more info
		else
			case "$2" in
				-f|--force)			loading_process "update_cli force" ;;	# Shortcut to quickly reinstall the CLI
			esac
		fi ;;
	--self-delete)					loading_process "delete_systemd" && loading_process "delete_cli" ;;
	--logs)							get_logs "$file_log_main" ;;
	-l|--list)						loading_process "subcommand_list $2" ;;
	-g|--get)						loading_process "subcommand_get $2" ;;
	# -g|--get)						loading_process "subcommand_update $2" ;;
	-d|--delete)					subcommand_delete $2 $3 ;;
	-n|--new)						subcommand_new $2 $3 ;;
	verify)
		if [ -z "$2" ]; then
									loading_process "verify_dependencies $3";  loading_process "verify_files"; loading_process "verify_repository_reachability $(match_url_repository $(get_config_value $file_config cli_url) github_raw)"
		else
			case "$2" in
				-f|--files)			loading_process "verify_files $3" ;;
				-d|--dependencies)	loading_process "verify_dependencies $3" ;;
				# -r|--repository)	loading_process "verify_repository_reachability "$URL_RAW/main/$NAME_LOWERCASE.sh""; loading_process "verify_repository_reachability "$URL_API/tarball/$VERSION"" ;;
				-r|--repository)	loading_process "verify_repository_reachability $(match_url_repository $(get_config_value $file_config cli_url) github_raw)" ;;
				*)					log_error "unknown option [$1] '$2'." && echo "$USAGE" && exit ;;
			esac
		fi ;;
	# 'self' is a word used in many operations for the CLI, it's preferable to not allow it in subcommand name
	self)							log_error "reserved operation." && exit ;;
	# Since "export -f" is not available in Shell, the helper command below permits to use commands from this file in sub scripts
	helper)
		# The $allow_helper_functions variable must be exported as "true" in sub scripts that needs the helper functions
		# This permits to avoid these commands to be used directly from the command line by the users
		if [ "$allow_helper_functions" != "true" ]; then
			log_error "reserved operation."
		else
			if [ -z "$2" ]; then
				log_error "unknown option [$1] '$2'." && echo "$USAGE" && exit
			else
				case "$2" in
					append_log)						append_log "$3" ;;
					create_automation)				create_automation "$3" ;;
					create_completion)				create_completion "$3" ;;
					log_error)						log_error "$3" "$4" ;;
					log_info)						log_info "$3" "$4" ;;
					log_success)					log_success "$3" "$4" ;;
					download_file)					download_file "$3" "$4" "$5" ;;
					exists_command)					exists_command "$3" ;;
					file_checksum)					file_checksum "$3" ;;
					get_config_value)				get_config_value "$3" "$4" ;;
					get_logs)						get_logs "$3" ;;
					loading_process)				loading_process "$3" ;;
					match_url_repository)			match_url_repository "$3" "$4" ;;
					sanitize_confirmation)			sanitize_confirmation "$3" ;;
					set_config_value)				set_config_value "$3" "$4" "$5" ;;
					*)								log_error "unknown option [$1] '$2'." && echo "$USAGE" && exit ;;
				esac
			fi
		fi ;;
	*)
		# Dynamically get availables commands or display error in case of not found
		# if [ -d $dir_commands ] && [ "$1" = "$(find $dir_commands/ -name "$1*" -printf "%f\n")" ]; then
		# if [ -d $dir_commands ] && [ "$1" = "$(find $dir_commands/ -name "$1*" -printf "%f\n" | sed "s|.sh||")" ]; then
		# if [ -d $dir_commands ] && [ "$1" = "$(ls $dir_commands | grep "$1")" ]; then
		if [ -d $dir_commands ] && [ "$1" = "$(ls $dir_commands | grep "$1" | sed "s|.sh||")" ]; then
			"$dir_commands/$1.sh" "$@"
		else
			log_error "unknown command '$1'." && echo "$USAGE" && exit
		fi
		;;
esac


# Properly exit
exit

#EOF