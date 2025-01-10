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



export allow_helper_functions="true"


# command_name=$(echo $(basename $1))
# file_log="$dir_log/$CURRENT_SUBCOMMAND.log"


question_accept_install="Do you want to automatically accept installations during the process? [y/N] "




# Display help
# Usage: display_help
display_help() {
	echo "$USAGE"
	echo ""
	echo "Supported package managers:"
	echo " - APT (https://wiki.debian.org/Apt)"
	echo " - DNF (https://rpm-software-management.github.io/)"
	echo " - YUM (http://yum.baseurl.org/)"
	echo " - Canonical Snapcraft (https://snapcraft.io)"
	echo " - Firmwares with fwupd (https://github.com/fwupd/fwupd)"
	echo ""
	echo "Arguments:"
	echo " install"
	echo " update"
	echo ""
	echo "Options:"
	echo " -y, --assume-yes 	enable automatic installations without asking during the execution."
	echo "     --ask    		ask to manually write your choice about updates installations confirmations."
	echo "     --get-logs		display logs."
	echo "     --when   		display next update cycle."
	echo ""
	echo "$NAME $VERSION"
}




# Clear user choice to the simple "-y" option or leave it empty.
# It will be used as-it with the differents commands.
# Examples :
# - user input is not required	: apt upgrade -y
# - user input is required		: apt upgrade
confirm_installation() {
	if [ "$($HELPER sanitize_confirmation $install_confirmation)" = "yes" ]; then
		install_confirmation="-y"
		$HELPER display_info "all installations will be automatically accepted."
	else
		# Not "-y", so it means "no", and no = empty
		install_confirmation=""
		$HELPER display_info "installations will not be automatically accepted, you'll have to specify your choice for each steps."
	fi
}




# Install packages on the system
# Usage : install_package <package>
install_package() {

	local package="${1}"
	local manager=""

	confirm_installation


	# Don't do anything if the package is already installed
	if [ "$($HELPER exists_command $package)" = "exists" ]; then
		$HELPER display_info "package '$package' already installed."
	else

		$HELPER display_info "starting package '$package' installation."

		# Test every supported package managers until finding a compatible
		if [ "$($HELPER exists_command apt)" = "exists" ]; then
			apt install $install_confirmation $package | $HELPER append_log "$file_LOG_CURRENT_SUBCOMMAND"
			manager="apt"

		elif [ "$($HELPER exists_command dnf)" = "exists" ]; then
			dnf install $package
			manager="dnf"

		elif [ "$($HELPER exists_command yum)" = "exists" ]; then
			yum install $package
			manager="yum"

		elif [ "$($HELPER exists_command snap)" = "exists" ]; then
			snap install $package
			manager="snap"

		fi


		# Display if package has been installed or not
		if [ "$($HELPER exists_command $package)" = "exists" ]; then
			$HELPER display_success "package '$package' has been installed with '$manager'."
		else
			$HELPER display_error "package '$package' has not been installed with '$manager'."
		fi
	fi
}




# Update packages on the system
# Usage : update_packages
update_packages() {

	confirm_installation

	if [ "$($HELPER exists_command "apt")" = "exists" ]; then

		$HELPER display_info "updating with APT." "$file_LOG_CURRENT_SUBCOMMAND"

		if [ "$($HELPER exists_command "dpkg")" = "exists" ]; then
			dpkg --configure -a										| $HELPER append_log $file_LOG_CURRENT_SUBCOMMAND
		fi

		apt update													| $HELPER append_log "$file_LOG_CURRENT_SUBCOMMAND"
		apt install --fix-broken $install_confirmation				| $HELPER append_log "$file_LOG_CURRENT_SUBCOMMAND"
		apt full-upgrade $install_confirmation						| $HELPER append_log "$file_LOG_CURRENT_SUBCOMMAND"
		
		# Ensure to delete all old packages & their configurations
		apt autopurge $install_confirmation							| $HELPER append_log "$file_LOG_CURRENT_SUBCOMMAND"
		
		# Just repeat to check if everything is ok
		apt full-upgrade $install_confirmation						| $HELPER append_log "$file_LOG_CURRENT_SUBCOMMAND"
	fi




	# Update Snapcraft packages
	# Usage : upgrade_with_snapcraft <-y>
	upgrade_with_snapcraft() {

		local file_tmp_updates_available="$dir_tmp/$NAME_LOWERCASE-snap"

		# Send Snap output in file to avoid some display issues
		snap refresh --list > $file_tmp_updates_available 2>&1
		cat $file_tmp_updates_available

		# List available updates & ask for update if found any (or auto update if <-y>).
		if [ "$(cat $file_tmp_updates_available | grep -v "All snaps up to date.")" ]; then

			# snap refresh --list

			if [ "${1}" = "-y" ]; then
				snap refresh
			else
				read -p "$question_accept_install" install_confirmation_snapcraft

				if [ "$install_confirmation_snapcraft" = "$yes" ]; then
					snap refresh
				fi
			fi
		fi

		rm -f $file_tmp_updates_available
	}

	if [ "$($HELPER exists_command "snap")" = "exists" ]; then
		$HELPER display_info "updating with Snap." "$file_LOG_CURRENT_SUBCOMMAND"
		# upgrade_with_snapcraft $install_confirmation
		upgrade_with_snapcraft $install_confirmation
	fi




	# Update DNF packages (using YUM as fallback if DNF doesn't exist)
	if [ "$($HELPER exists_command "dnf")" = "exists" ]; then
		$HELPER display_info "updating with DNF." "$file_LOG_CURRENT_SUBCOMMAND"

		# dnf upgrade $install_confirmation
		dnf upgrade $install_confirmation


	elif [ "$($HELPER exists_command "yum")" = "exists" ]; then
		$HELPER display_info "updating with YUM." "$file_LOG_CURRENT_SUBCOMMAND"

		# yum upgrade $install_confirmation
		yum upgrade $install_confirmation

	fi




	# Update firmwares with fwupd
	# Checking if the system is bare-metal (and not virtualized) with the "systemd-detect-virt" command and if not bare-metal, firmwares will not be updated.
	if [ "$($HELPER exists_command "systemd-detect-virt")" = "exists" ]; then
			if [ "$(systemd-detect-virt)" = "none" ]; then

					# Process to firmware updates with fwupdmgr
					if [ "$($HELPER exists_command "fwupdmgr")" = "exists" ]; then

							$HELPER display_info "updating with fwupd (firmwares)."
							fwupdmgr upgrade $install_confirmation
					else

						$HELPER display_info "starting firmwares updates (fwupd)."

						install_package fwupd

						if [ "$($HELPER exists_command "fwupdmgr")" = "exists" ]; then
							fwupdmgr upgrade $install_confirmation
						fi
					fi
			fi
	else
		$HELPER display_error "can't detect if your system is bare-metal with the command 'systemd-detect-virt', will not upgrade firmwares."
	fi
}




# Get next update date from the timer used on the system 
# Usage: get_next_update_packages_date
get_next_update_packages_date() {
	if [ "$($HELPER exists_command "systemctl")" = "exists" ]; then
		systemctl list-timers --all | grep "$NAME_LOWERCASE-$2"
	else
		$HELPER display_error "can't get update timer."
	fi
}




if [ ! -z "$2" ]; then
	case "$2" in
		install)
			if [ -z "$4" ]; then
				install_confirmation="no" && install_package "$3"
			else
				case "$4" in
					-y|--assume-yes)	install_confirmation="yes" && install_package "$3" ;;
					--ask)				read -p "$question_accept_install" install_confirmation && install_package "$3" ;;
				esac
			fi
			;;
		update)
			if [ -z "$3" ]; then
				install_confirmation="no" && update_packages
			else
				case "$3" in
					-y|--assume-yes)	install_confirmation="yes" && update_packages ;;
					--ask)				read -p "$question_accept_install" install_confirmation && update_packages ;;
					--when)				get_next_update_packages_date ;;
				esac
			fi
			;;
		--get-logs)	$HELPER get_logs $file_LOG_CURRENT_SUBCOMMAND ;; 
		--help)		display_help ;;
		*)			$HELPER display_error "unknown option '$2' from '$1' command."'\n'"$USAGE" && exit ;;
	esac
else
	display_help
fi



# Properly exit
exit

#EOF
