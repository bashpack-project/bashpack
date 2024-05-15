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


#URL="http://localhost"													# for local web server							
URL="https://api.github.com/repos/bashpack-project/bashpack/tarball"	# for Github
# URL="https://github.com/bashpack-project/bashpack/archive/refs/heads"	# for Github
VERSION="0.2.15"

NAME="Bashpack"
NAME_LOWERCASE=$(echo "$NAME" | tr A-Z a-z)
NAME_ALIAS="bp"

USAGE="Usage: sudo $NAME_ALIAS [COMMAND] [OPTION]..."$'\n'"$NAME_ALIAS --help"


export yes="@(yes|Yes|yEs|yeS|YEs|YeS|yES|YES|y|Y)"




# The --help option can be called without root
# Display usage in case of empty option
if [[ -z "$@" ]]; then
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
				&&		echo "" \
				&&		echo "" \
				&&		exit ;;
				esac
		;;
		--help) echo "$USAGE" \
		&&		echo "" \
		&&		echo "$NAME is a user-friendly Linux toolbox." \
		&&		echo "It has been designed for unexperimented Linux users and also for IT teams who needs to ensure security on their Linux laptop park." \
		&&		echo "You can easily setup automations with the differents options." \
		&&		echo "" \
		&&		echo "Features:" \
		&&		echo " (available)	Unified Linux updates (packages)." \
		&&		echo " (incoming)	Unified Linux updates (firmwares)." \
		&&		echo " (incoming)	Linux firewall security (close ports with nftables - Docker compatible)." \
		&&		echo " (incoming)	Routes over VPN to one or many points (OpenVPN compatible)." \
		&&		echo "" \
		&&		echo "" \
		&&		echo "Options:" \
		&&		echo " -i, --self-install	install (or reinstall) $NAME on your system as the command '$NAME_ALIAS'." \
		&&		echo " -u, --self-update	update your current $NAME installation to the latest available version." \
		&&		echo "     --self-delete	delete $NAME from your system." \
		&&		echo "     --get-logs   	display systemd logs." \
		&&		echo "     --when   		display systemd next service cycle." \
		&&		echo "     --help   		display this information." \
		&&		echo "     --version		display version." \
		&&		echo "" \
		&&		echo "" \
		&&		echo "Commands:" \
		&&		echo " update [OPTION]	use '$NAME_ALIAS update --help' for the command options." \
		&&		echo "" \
		&&		echo "" \
		&&		echo "Written in Bash, and it's a pack." \
		&&		echo "Version $VERSION" \
		&&		exit ;;
	esac
fi




# Ask for root
set -e
if [ "$(id -u)" != "0" ]; then
	echo "Must be runned as root." 1>&2
	exit 1
fi




# Loading animation so we know the process has not crashed
# Usage : loading "<command that takes time>"
loading() {
	${1} & local pid=$!
	local loader="\|/-"
	local i=1

	while ps -p $pid > /dev/null; do
		printf "\b%c" "${loader:i++%4:1}"
		sleep 0.12
	done

	# Delete the loader character displayed after the loading has ended 
	printf "\b%c" " "

	echo ""
}
export -f loading




# Function to search for commands on the system.
# Usage : exists_command <command>
exists_command() {
	local command=${1}

	if ! which $command > /dev/null; then
		echo "$command: Error: command not found"
	else
		echo "exists"
	fi
}
export -f exists_command




# Error function.
# Usage : error_file_not_downloaded <file> <file_url>
error_file_not_downloaded() {
	local file=${1}
	local file_url=${2}

	echo "Error: $file not found. Can you reach $file_url ?"
}




dir_tmp="/tmp"
dir_bin="/usr/local/sbin"
dir_src="/usr/local/src/$NAME_LOWERCASE"
dir_systemd="/lib/systemd/system"

archive_tmp="$dir_tmp/$NAME_LOWERCASE-$VERSION.tar.gz"
archive_dir_tmp="$dir_tmp/$NAME_LOWERCASE" # Make a generic name for tmp directory, so all versions will delete it

file_main="$dir_bin/$NAME_LOWERCASE"
file_main_alias="$dir_bin/$NAME_ALIAS"

# bash-completion doc: https://github.com/scop/bash-completion/tree/master?tab=readme-ov-file#faq
# Force using /etc/bash_completion.d/ in case of can't automatically detect it on the system
if [[ $(exists_command "pkg-config") = "exists" ]]; then
	dir_autocompletion="$(pkg-config --variable=compatdir bash-completion)"
else
	dir_autocompletion="/etc/bash_completion.d"
fi
file_autocompletion="$dir_autocompletion/$NAME_LOWERCASE"

file_systemd_update="$NAME_LOWERCASE-updates"
file_systemd_timers=(
	"$file_systemd_update.timer"
)




COMMAND_UPDATE="$dir_src/update.sh"
COMMAND_MAN="$dir_src/man.sh"
COMMAND_SYSTEMD_LOGS="journalctl -e _SYSTEMD_INVOCATION_ID=`systemctl show -p InvocationID --value $file_systemd_update.service`"
COMMAND_SYSTEMD_STATUS="systemctl status $file_systemd_update.timer"




# Delete the installed command from the system
delete_cli() {
	
	local files=(
		$dir_src
		$file_autocompletion
		$file_main_alias
		$file_main
	)
	

	if [[ $(exists_command "$NAME_ALIAS") != "exists" ]]; then
		echo "$NAME $VERSION is not installed on your system."
	else
		# Delete all files listed in $files 
		for file in "${files[@]}"; do
			rm -rf $file
			if [ -f $file ]; then
				echo "Error: $file has not been removed."
			else
				echo "Deleted: $file"
			fi
		done
	fi

	echo ""

	if [ -f $file_main ]; then
		echo "Error: $NAME $VERSION located at $(which $NAME_ALIAS) has not been uninstalled."
	else
		echo "Success! $NAME $VERSION has been uninstalled."
	fi

	echo ""
}




# Delete the installed systemd units from the system
delete_systemd() {

	if [[ $(exists_command "$NAME_ALIAS") != "exists" ]]; then
		echo "$NAME $VERSION is not installed on your system."
	else
		# Delete systemd units
		# Checking if systemd is installed (and do nothing if not installed because it means the OS doesn't work with it)
		if [[ $(exists_command "systemctl") = "exists" ]]; then

			# Stop, disable and delete systemd timers
			for unit in "${file_systemd_timers[@]}"; do
				
				local file="$dir_systemd/$unit"

				if [ -f $file ]; then

					systemctl stop $unit
					systemctl disable $unit					
					rm -f $file

					if [ -f $file ]; then
						echo "[delete] Error: $file has not been removed."
					else
						echo "Deleted: $file"
					fi

				else
					echo "[delete] Error: $file not found."
				fi
			done

			# Delete everything related to this script remaining in systemd directory
			rm -f $dir_systemd/$NAME_LOWERCASE*

			ls -al $dir_systemd | grep bashpack

			systemctl daemon-reload
		fi
	fi
}




delete_all() {
	delete_systemd && delete_cli
}




# Download releases archives from the repository
# Usages :
# - download_cli <latest>
# - download_cli <n.n.n>
download_cli() {
	
	# local archive_name="$NAME_LOWERCASE-${1}.tar.gz"	# for basic web server
	# local archive_url="$URL/$archive_name"				# for basic web server
	local archive_url=${1}								# for Github


	# Prepare tmp directory
	rm -rf $archive_dir_tmp
	mkdir $archive_dir_tmp


	# Download source scripts
	# Try to download with curl if exists
	echo -n "Downloading sources from $archive_url "
	if [[ $(exists_command "curl") = "exists" ]]; then
		echo -n "with curl...   "
		loading "curl -sL $archive_url -o $archive_tmp"
		
	# Try to download with wget if exists
	elif [[ $(exists_command "wget") = "exists" ]]; then
		echo -n "with wget...  "
		loading "wget -q $archive_url -O $archive_tmp"
		
	else
		error_file_not_downloaded $archive_name $archive_url
	fi

	# "tar --strip-components 1" permit to extract sources in /tmp/bashpack and don't create a new directory /tmp/bashpack/bashpack
	tar -xf $archive_tmp -C $archive_dir_tmp --strip-components 1 

}




# Detect if the command has been installed on the system
detect_cli() {
	if [[ $(exists_command "$NAME_LOWERCASE") = "exists" ]]; then
		if [[ ! -z $($NAME_LOWERCASE --version) ]]; then
			echo "$NAME $($NAME_ALIAS --version) detected at $(which $NAME_LOWERCASE)"
		fi
	fi

	echo ""
}




# Create the command from the downloaded archives
# Works together with install or update functions
create_cli() {

	# Cannot display "Installing $NAME $VERSION..." until the new version is not there.
	echo ""
	echo "Installing $NAME...  "


	# Process to the installation
	if [ -d $archive_dir_tmp ]; then

		# Make this script a command installed on the system (copy this script to a PATH directory)
		echo "Installing $file_main..."
		cp "$archive_dir_tmp/$NAME_LOWERCASE.sh" $file_main
		chmod +x $file_main


		# Create an alias so the listed package are clear on the system (-f to force overwrite existing)
		echo "Installing $file_main_alias..."
		ln -sf $file_main $file_main_alias


		# Autocompletion installation
		# Checking if the autocompletion directory exists and create it if doesn't exists
		echo "Installing autocompletion..."
		if [ ! -d $dir_autocompletion ]; then
			echo "Error: $dir_autocompletion not found. Creating it... "
			mkdir $dir_autocompletion
		fi
		cp "$archive_dir_tmp/bash_completion" $file_autocompletion
		
		
		# Sources files installation
		echo "Installing commands..."
		cp -R "$archive_dir_tmp/commands" $dir_src
		chmod +x -R $dir_src

		
		# Systemd services installation
		# Checking if systemd is installed (and do nothing if not installed because it means the OS doesn't work with it)
		if [[ $(exists_command "systemctl") = "exists" ]]; then
		
			echo "Installing systemd services..."
		
			# Copy systemd services & timers to systemd directory
			cp -R $archive_dir_tmp/systemd/* $dir_systemd
			systemctl daemon-reload

			# Start & enable systemd timers (don't need to start systemd services because timers are made for this)
			for unit in "${file_systemd_timers[@]}"; do

				local file="$dir_systemd/$unit"

				# Testing if systemd files exists to ensure systemctl will work as expected
				if [ -f $file ]; then
					echo "- Starting & enabling $unit..." 
					systemctl restart $unit # Call "restart" and not "start" to be sure to run the unit provided in this current version (unless the old unit will be kept as the running one)
					systemctl enable $unit
				else
					echo "[install] Error: $file not found."
				fi
			done
		fi


		# Success message
		if [[ $(exists_command "$NAME_ALIAS") = "exists" ]] && [ -f $file_autocompletion ]; then
			echo ""
			echo "Success! $NAME $($NAME_ALIAS --version) has been installed."
			echo ""
			# echo "Info: autocompletion options might not be ready on your current session, you should open a new tab or manually launch the command: source ~/.bashrc"
		elif [[ $(exists_command "$NAME_ALIAS") = "exists" ]] && [ ! -f $file_autocompletion ]; then
			echo ""
			echo "Partial success:"
			echo "$NAME $VERSION has been installed, but auto-completion options could not be installed because $dir_autocompletion does not exists."
			echo "Please ensure that bash-completion package is installed, and retry the installation of $NAME."
		fi


		# Clear temporary files & directories
		rm -f $archive_tmp
		rm -rf $archive_dir_tmp

	else
		error_file_not_downloaded $archive_tmp $archive_url
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
#			- Github latest tarball release is accessible from https://api.github.com/repos/bashpack-project/bashpack/tarball
update_cli() {
	# Download a first time the latest version from the "main" branch to be able to launch the installation script from it to get latest modifications.
	# Ths install function will download the well-named archive with the version name
	# (so yes, it means that we download the CLI twice, and it's why we don't display the output here)
	
	#download_cli "main"									# Github main branch
	#download_cli "main" 2>&1 > /dev/null					# Github main branch
	download_cli "$URL" 2>&1 > /dev/null && delete_all		# Github latest tarball
	#download_cli "$URL"									# Github latest tarball
	
	# # Delete current installed version to clean all old files
	# delete_all

	# Execute the install_cli function of the script downloaded in /tmp
	exec "$archive_dir_tmp/$NAME_LOWERCASE.sh" -i
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

	download_cli "$URL/$VERSION"		# Github latest tarball
	#download_cli $VERSION				# Github main branch

	create_cli
}




# The options (except --help) must be called with root
case "$1" in
	-i|--self-install)	install_cli ;;
	-u|--self-update)	update_cli ;;		# Critical option, see the comments at function declaration for more info
	--self-delete)		delete_all ;;
	--get-logs)			$COMMAND_SYSTEMD_LOGS ;;
	man)				$COMMAND_MAN ;;
	update)
		if [[ -z "$2" ]]; then
			install_confirmation="no" && exec $COMMAND_UPDATE
		else
			# for arg_update in "$@"; do
				case "$2" in
					-y|--assume-yes)	export install_confirmation="yes" && exec $COMMAND_UPDATE ;;
					--ask)				read -p "Do you want to automatically accept installations during the process? [y/N] " install_confirmation && export install_confirmation && exec $COMMAND_UPDATE ;;
					--when)				$COMMAND_SYSTEMD_STATUS | grep Trigger: | awk '$1=$1' ;;
					*)					echo "Error: unknown [update] option '$2'."$'\n'"$USAGE" && exit ;;
				esac
			# done
		fi ;;
	*) echo "Error: unknown option '$1'."$'\n'"$USAGE" && exit ;;
esac



# Properly exit
exit

#EOF
