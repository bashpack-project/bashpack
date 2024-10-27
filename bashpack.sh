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




# Display a warning in case of using the script and not a command installed on the system
if [ $0 = "./$file_main" ]; then
	echo "Warning: you are currently using '$0' which is located in $(pwd)."
fi




export VERSION="2.0.0"

export NAME="Bashpack"
export NAME_LOWERCASE="$(echo "$NAME" | tr A-Z a-z)"
export NAME_UPPERCASE="$(echo "$NAME" | tr a-z A-Z)"
export NAME_ALIAS="bp"

BASE_URL="https://api.github.com/repos/$NAME_LOWERCASE-project"

USAGE="Usage: sudo $NAME_ALIAS [COMMAND] [OPTION]..."'\n'"$NAME_ALIAS --help"




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
				&&		echo " - APT (https://wiki.debian.org/Apt) - will be detected, but not installed." \
				&&		echo " - Canonical Snapcraft (https://snapcraft.io) - will be detected, but not installed." \
				&&		echo " - Firmwares with fwupd (https://github.com/fwupd/fwupd) - will be installed during execution of this script." \
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
				&&		echo " -f, --files				verify that all files composing the CLI are presents." \
				&&		echo " -d, --download				test to download archive from remote repository." \
				&&		echo " -r, --repository-reachability		check if remote repository is reachable." \
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
		&&		echo "Commands:" \
		&&		echo " update [OPTION]	update everything on your system. '$NAME_ALIAS update --help' for options." \
		&&		echo " verify [OPTION]	verify the current $NAME installation health. '$NAME_ALIAS verify --help' for options." \
		&&		echo "" \
		&&		echo "$NAME $VERSION" \
		&&		exit ;;
	esac
fi




# Ask for root
set -e
if [ "$(id -u)" != "0" ]; then
	display_error "must be runned as root." 1>&2
	exit 1
fi




dir_tmp="/tmp"
dir_bin="/usr/local/sbin"
dir_systemd="/lib/systemd/system"



export dir_config="/etc/$NAME_LOWERCASE"
dir_src_cli="/usr/local/src/$NAME_LOWERCASE"



export archive_tmp="$dir_tmp/$NAME_LOWERCASE-$VERSION.tar.gz"
export archive_dir_tmp="$dir_tmp/$NAME_LOWERCASE" # Make a generic name for tmp directory, so all versions will delete it



# Checking if helper.sh exists. 
# If not, using the temp file.
# This should be useful only during an installation
if [ -f "$dir_src_cli/core/helper.sh" ]; then
	. "$dir_src_cli/core/helper.sh"
elif [ -f "$archive_dir_tmp/core/helper.sh" ]; then
	. "$archive_dir_tmp/core/helper.sh"
fi



file_main="$dir_src_cli/$NAME_LOWERCASE.sh"
file_main_alias_1="$dir_bin/$NAME_LOWERCASE"
file_main_alias_2="$dir_bin/$NAME_ALIAS"



# bash-completion doc: https://github.com/scop/bash-completion/tree/master?tab=readme-ov-file#faq
# Force using /etc/bash_completion.d/ in case of can't automatically detect it on the system
if [ "$(exists_command "pkg-config")" = "exists" ]; then
	dir_autocompletion="$(pkg-config --variable=compatdir bash-completion)"
else
	dir_autocompletion="/etc/bash_completion.d"
fi
file_autocompletion="$dir_autocompletion/$NAME_LOWERCASE"



file_systemd_update="$NAME_LOWERCASE-updates"
file_systemd_timers="$file_systemd_update.timer"



export file_config=$NAME_LOWERCASE".conf"
# Since 1.2.0 the main config file has been renamed from $NAME_LOWERCASE_config to $NAME_LOWERCASE.conf
# The old file is not needed anymore and must be removed
if [ -f "$dir_config/"$NAME_LOWERCASE"_config" ]; then
	rm -f "$dir_config/"$NAME_LOWERCASE"_config"
fi



file_current_publication=$dir_config"/.current_publication"



# Workaround that permit to download the stable release in case of first installation or installation from a version that didn't had the config file
# (If the config file doesn't exist, it cannot detect the publication where it's supposed to be written)
# Also:
# - create a temp config file that permit to get new config file names in case of rename in new versions
# - "manually" declare the current publication in case of new config file has been renamed and the publication can't be detected
if [ ! -f "$dir_config/$file_config" ]; then
	if [ -f $file_current_publication ]; then
		echo "publication "$(cat $file_current_publication) > "$dir_config/$file_config"
	else
		mkdir -p "$dir_config"
		echo "publication main" > "$dir_config/$file_config"
	fi
fi

# Depending on the chosen publication, the repository will be different:
# - Main (= stable) releases:	https://github.com/$NAME_LOWERCASE-project/$NAME_LOWERCASE
# - Unstable releases:			https://github.com/$NAME_LOWERCASE-project/$NAME_LOWERCASE-unstable
# - Dev releases:				https://github.com/$NAME_LOWERCASE-project/$NAME_LOWERCASE-dev
PUBLICATION="$(get_config_value "$dir_config/$file_config" "publication")"
case $PUBLICATION in
	unstable)	URL="$BASE_URL/$NAME_LOWERCASE-unstable" ;;
	dev)		URL="$BASE_URL/$NAME_LOWERCASE-dev" ;;
	main)		URL="$BASE_URL/$NAME_LOWERCASE" ;;
	*)			display_error "publication $PUBLICATION not found in [main|unstable|dev] at $dir_config/$file_config. Using default 'main' publication." && URL="$BASE_URL/$NAME_LOWERCASE" ;;
esac
export URL # Export URL to be usable on tests




COMMAND_UPDATE="commands/update.sh"
COMMAND_MAN="commands/man.sh"
COMMAND_VERIFY="commands/tests.sh"
COMMAND_FIREWALL="commands/firewall.sh"	
COMMAND_SYSTEMD_LOGS="journalctl -e _SYSTEMD_INVOCATION_ID=`systemctl show -p InvocationID --value $file_systemd_update.service`"
COMMAND_SYSTEMD_STATUS="systemctl status $file_systemd_update.timer"




# Delete the installed command from the system
# Usages: 
# - delete_cli
# - delete_cli "exclude_main"
delete_cli() {
	
	# $exclude_main permit to not delete main command "bp" and "bashpack".
	#	(i) This is useful in case when the CLI tries to update itself, but the latest release is not accessible.
	#	/!\ Unless it can happen that the CLI destroys itself, and then the user must reinstall it.
	#	(i) Any new update will overwrite the "bp" and "bashpack" command, so it doesn't matter to not delete it during update.
	#	(i) It's preferable to delete all others files since updates can remove files from olders releases 
	local exclude_main=${1}

	# if [ "$exclude_main" = "exclude_main" ]; then
	# 	local files="$dir_src_cli" "$file_autocompletion"
	# else
	# 	local files="$dir_src_cli" "$file_autocompletion" "$dir_config" "$file_main_alias_1" "$file_main_alias_2"
	# fi
	



	# if [ "$(exists_command "$NAME_ALIAS")" != "exists" ]; then
	# 	display_error "$NAME $VERSION is not installed on your system."
	# else
	# 	# Delete all files listed in $files 
	# 	for file in "${files[@]}"; do
		
		
	# 		rm -rf $file


	# 		if [ -f "$file" ]; then
	# 			display_error "$file has not been deleted."
	# 		else
	# 			display_success "$file deleted"
	# 		fi
	# 	done
	# fi



	# if [ "$(exists_command "$NAME_ALIAS")" != "exists" ]; then
	# 	display_error "$NAME $VERSION is not installed on your system."
	# else
	# 	# Delete all files listed in $files 
	# 	for file in "${files[@]}"; do
	# 		rm -rf $file
	# 		if [ -f $file ]; then
	# 			display_error "$file has not been removed."
	# 		else
	# 			display_success "deleted: $file"
	# 		fi
	# 	done
	# fi


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
			# find $dir_src_cli -mindepth 1 -maxdepth 1 ! -name "$NAME_LOWERCASE.sh" ! -name "core" -print
			find $dir_src_cli -mindepth 1 -maxdepth 1 ! -name "$NAME_LOWERCASE.sh" ! -name "core" -exec rm -rv {} + 2&> /dev/null
			
		else
			# Delete everything

			rm -rf $dir_config
			rm -rf $file_autocompletion
			rm -rf $file_main_alias_1
			rm -rf $file_main_alias_2
			rm -rf $dir_src_cli
		fi

		if [ -f "$file_main" ]; then
			if [ "$exclude_main" = "exclude_main" ]; then
				display_success "$NAME $VERSION has been uninstalled ($file_main has been kept)."
			else
				display_error "$NAME $VERSION located at $(posix_which $NAME_ALIAS) has not been uninstalled." && exit
			fi
		else
			display_success "$NAME $VERSION has been uninstalled."
		fi
		
	fi








}




# Delete the installed systemd units from the system
delete_systemd() {

	if [ "$(exists_command "$NAME_ALIAS")" != "exists" ]; then
		echo "$NAME $VERSION is not installed on your system."
	else
		# Delete systemd units
		# Checking if systemd is installed (and do nothing if not installed because it means the OS doesn't work with it)
		if [ $(exists_command "systemctl") = "exists" ]; then

			# Stop, disable and delete systemd timers
			for unit in "${file_systemd_timers[@]}"; do
				
				local file="$dir_systemd/$unit"

				if [ -f $file ]; then

					systemctl stop $unit
					systemctl disable $unit					
					rm -f $file

					if [ -f $file ]; then
						echo "[delete] $NAME failure: $file has not been removed."
					else
						echo "Deleted: $file"
					fi

				else
					echo "[delete] $NAME failure: $file not found."
				fi
			done

			# Delete everything related to this script remaining in systemd directory
			rm -f $dir_systemd/$NAME_LOWERCASE*

			ls -al $dir_systemd | grep $NAME_LOWERCASE

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

	# delete_systemd && delete_cli ${1}
	 delete_cli ${1}
}



# # Detect if the command has been installed on the system
# detect_cli() {
# 	if [ "$(exists_command "$NAME_LOWERCASE")" = "exists" ]; then
# 		if [ ! -z "$($NAME_LOWERCASE --version)" ]; then
# 			echo "$NAME $($NAME_ALIAS --version) detected at $(posix_which $NAME_LOWERCASE)"
# 		fi
# 	fi
# }




# Detect what is the current publication installed
detect_publication() {
	if [ -f $file_current_publication ]; then
		cat $file_current_publication
	else
		display_error "publication not found."
	fi
}




# This function will install the new config file given within new versions, while keeping user configured values
# Usage : install_new_config_file
install_new_config_file() {

	local file_config_current="$dir_config/$file_config"
	local file_config_temp="$archive_dir_tmp/config/$file_config"

	while read -r line; do
		local first_char=`echo $line | cut -c1-1`

		# Avoid reading comments and empty lines
		if [ "$first_char" != "#" ] && [ "$first_char" != "" ]; then

			option=$(echo $line | cut -d " " -f 1)
			value=$(echo $line | cut -d " " -f 2)

			# Replacing options values in temp config file with current configured values
			# /^#/! is to avoid commented lines
			sed -i "/^#/! s/$option.*/$line/g" $file_config_temp

		fi	
	done < "$file_config_current"

	cp $file_config_temp $file_config_current

}




# Create the command from the downloaded archives
# Works together with install or update functions
create_cli() {

	# Cannot display "Installing $NAME $VERSION..." until the new version is not there.
	# echo "Installing $NAME...  "


	# Process to the installation
	if [ -d "$archive_dir_tmp" ]; then

		
		# Sources files installation
		echo "Installing sources..."
		# cp -R "$archive_dir_tmp/commands" $dir_src_cli
		cp -fRT $archive_dir_tmp $dir_src_cli # -T used to overwrite the source dir and not creating a new inside
		chmod +x -R $dir_src_cli


		# Create an alias so the listed package are clear on the system (-f to force overwrite existing)
		echo "Installing aliases..."
		ln -sf $file_main $file_main_alias_1
		ln -sf $file_main $file_main_alias_2


		# Autocompletion installation
		# Checking if the autocompletion directory exists and create it if doesn't exists
		echo "Installing autocompletion..."
		if [ ! -d "$dir_autocompletion" ]; then
			display_error "$dir_autocompletion not found. Creating it..."
			mkdir $dir_autocompletion
		fi
		cp "$archive_dir_tmp/bash_completion" $file_autocompletion

		
		# Systemd services installation
		# Checking if systemd is installed (and do nothing if not installed because it means the OS doesn't work with it)
		if [ $(exists_command "systemctl") = "exists" ]; then
		
			echo "Installing systemd services..."
		
			# Copy systemd services & timers to systemd directory
			cp -R $archive_dir_tmp/systemd/* $dir_systemd
			systemctl daemon-reload

			# Start & enable systemd timers (don't need to start systemd services because timers are made for this)
			for unit in "${file_systemd_timers}"; do

				local file="$dir_systemd/$unit"

				# Testing if systemd files exists to ensure systemctl will work as expected
				if [ -f "$file" ]; then
					echo "- Starting & enabling $unit..." 
					systemctl restart $unit # Call "restart" and not "start" to be sure to run the unit provided in this current version (unless the old unit will be kept as the running one)
					systemctl enable $unit
				else
					display_error "$file not found."
				fi
			done
		fi


		# Config installation
		# Checking if the config directory exists and create it if doesn't exists
		echo "Installing configuration..."
		if [ ! -d "$dir_config" ]; then
			echo "$dir_config not found. Creating it..."
			mkdir $dir_config
		fi

		# Must testing if config file exists to avoid overwrite user customizations 
		if [ ! -f "$dir_config/$file_config" ]; then
			echo "$dir_config/$file_config not found. Creating it... "
			cp "$archive_dir_tmp/config/$file_config" "$dir_config/$file_config"

		else
			echo "$dir_config/$file_config already exists. Copy new file while leaving current configured options."
			install_new_config_file
		fi
		

		# Creating a file that permit to know what is the current installed publication
		echo "$PUBLICATION" > $file_current_publication

		chmod +rw -R $dir_config


		# Success message
		if [ "$(exists_command "$NAME_ALIAS")" = "exists" ] && [ -f "$file_autocompletion" ]; then
			echo ""
			display_success "$NAME $($NAME_ALIAS --version) ($(detect_publication)) has been installed."
			# echo "Info: autocompletion options might not be ready on your current session, you should open a new tab or manually launch the command: source ~/.bashrc"
		elif [ "$(exists_command "$NAME_ALIAS")" = "exists" ] && [ ! -f "$file_autocompletion" ]; then
			echo ""
			echo "Partial success:"
			echo "$NAME $VERSION has been installed, but auto-completion options could not be installed because $dir_autocompletion does not exists."
			echo "Please ensure that bash-completion package is installed, and retry the installation of $NAME."
		fi

		# Clear temporary files & directories
		rm -rf $dir_tmp/$NAME_LOWERCASE*		# Cleaning also temp files created during update process since create_cli is not called directly during update.


	else
		error_file_not_downloaded $archive_url
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
#
# /!\	This function can only works if a generic name like "bashpack-main.tar.gz" exists and can be used as an URL.
#		By default, 
#			- Github main branch archive is accessible from https://github.com/<user>/<repository>/archive/refs/heads/main.tar.gz
#			- Github latest tarball release is accessible from https://api.github.com/repos/<user>/<repository>/tarball
update_cli() {
	# Download a first time the latest version from the "main" branch to be able to launch the installation script from it to get latest modifications.
	# The install function will download the well-named archive with the version name.
	# (so yes, it means that the CLI is downloaded multiple times)

	local error_already_installed="Latest $NAME version is already installed ($VERSION $(detect_publication))."

	# # Testing if publication has changed to get the latest available version from the chosen publication.
	# # This permit to change the used repository.
	# if [ ! $(detect_publication) = $(get_config_value "$dir_config/$file_config" "publication") ]; then
	# 	download_cli "$URL/tarball" $archive_tmp $archive_dir_tmp
	# fi

	# Testing if a new version exists on the current publication to avoid reinstall if not.
	# This test requires curl, if not usable, then the CLI will be reinstalled at each update.
	if [ "$(curl -s "$URL/releases/latest" | grep tag_name | cut -d \" -f 4)" = "$VERSION" ] && [ "$(detect_publication)" = "$(get_config_value "$dir_config/$file_config" "publication")" ]; then
		echo $error_already_installed
	else

		# download_cli "$URL/tarball" $archive_tmp $archive_dir_tmp

		# # To avoid broken installations, before deleting anything, testing if downloaded archive is a working tarball.
		# # (archive is deleted in create_cli, which is called after in the process)
		# # if ! $NAME_LOWERCASE verify -d | grep -q '$NAME failure:'; then
		# if ! check_repository_reachability | grep -q '$NAME failure:'; then

			# Download latest available version
			download_cli "$URL/tarball" $archive_tmp $archive_dir_tmp

			# Delete current installed version to clean all old files
			delete_all exclude_main
		
			# Execute the install_cli function of the script downloaded in /tmp
			exec "$archive_dir_tmp/$NAME_LOWERCASE.sh" -i
		# else
		# 	# error_tarball_non_working $archive_tmp
		# 	check_repository_reachability
		# fi
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
	# detect_cli

	# if [ ! -d ".git/"]; then
		download_cli "$URL/tarball/$VERSION" $archive_tmp $archive_dir_tmp
	# fi

	create_cli
}




# The options (except --help) must be called with root
case "$1" in
	-i|--self-install)		install_cli ;;		# Critical option, see the comments at function declaration for more info
	-u|--self-update)		update_cli ;;		# Critical option, see the comments at function declaration for more info
	--self-delete)			delete_all ;;
	-p|--publication)		detect_publication ;;
	man)					$COMMAND_MAN ;;
	verify)
		if [ -z "$2" ]; then
			export function_to_launch="check_all" && exec $COMMAND_VERIFY
		else
			case "$2" in
				-f|--files)						export function_to_launch="check_files" && exec $COMMAND_VERIFY ;;
				-d|--download)					export function_to_launch="check_download" && exec $COMMAND_VERIFY ;;
				-r|--repository-reachability)	export function_to_launch="check_repository_reachability" && exec $COMMAND_VERIFY ;;
				*)								display_error "unknown option [$1] '$2'."'\n'"$USAGE" && exit ;;
			esac
		fi ;;
	firewall)
		if [ -z "$2" ]; then
			exec $COMMAND_FIREWALL
		else
			case "$2" in
				-r|--restart)	exec $COMMAND_FIREWALL ;;
				*)				display_error "unknown option [$1] '$2'."'\n'"$USAGE" && exit ;;
			esac
		fi ;;
	update)
		if [ -z "$2" ]; then
			exec $COMMAND_UPDATE
		else
			case "$2" in
				-y|--assume-yes)	export install_confirmation="yes" && exec $COMMAND_UPDATE ;;
				--ask)				read -p "Do you want to automatically accept installations during the process? [y/N] " install_confirmation && export install_confirmation && exec $COMMAND_UPDATE ;;
				--when)				$COMMAND_SYSTEMD_STATUS | grep Trigger: | awk '$1=$1' ;;
				--get-logs)			$COMMAND_SYSTEMD_LOGS ;;
				*)					display_error "unknown option [$1] '$2'."'\n'"$USAGE" && exit ;;
			esac
		fi ;;
	*) display_error "unknown option '$1'."'\n'"$USAGE" && exit ;;
esac


# Properly exit
exit

#EOF