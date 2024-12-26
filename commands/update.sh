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
file_log="$dir_log/updates.log"




if [ ! -z "$2" ]; then
	case "$2" in
		-y|--assume-yes)	install_confirmation="yes" ;;
		--ask)				read -p "Do you want to automatically accept installations during the process? [y/N] " install_confirmation ;;
		# --when)				$COMMAND_UPDATE_SYSTEMD_STATUS | grep Trigger: | awk '$1=$1' ;;
		# --get-logs)			get_logs $file_log ;;
		--help)				echo "$USAGE" \
								&& echo "" \
								&& echo "Supported package managers:" \
								&& echo " - APT (https://wiki.debian.org/Apt)" \
								&& echo " - DNF (https://rpm-software-management.github.io/)" \
								&& echo " - YUM (http://yum.baseurl.org/)" \
								&& echo " - Canonical Snapcraft (https://snapcraft.io)" \
								&& echo " - Firmwares with fwupd (https://github.com/fwupd/fwupd)" \
								&& echo "" \
								&& echo "Options:" \
								&& echo " -y, --assume-yes 	enable automatic installations without asking during the execution." \
								&& echo "     --ask    		ask to manually write your choice about updates installations confirmations." \
								&& echo "     --get-logs		display logs." \
								&& echo "     --when   		display next update cycle." \
								&& echo "" \
								&& echo "$NAME $VERSION" \
								&& exit ;;
		*)					$HELPER display_error "unknown option '$2' from '$1' command."'\n'"$USAGE" && exit ;;
	esac
fi





# Clear user choice to the simple "-y" option or leave it empty.
# It will be used as-it with the differents commands.
# Examples :
# - user input is not required	: apt upgrade -y
# - user input is required		: apt upgrade
if [ "$($HELPER sanitize_confirmation $install_confirmation)" = "yes" ]; then
	install_confirmation="-y"
	$HELPER display_info "all installations will be automatically accepted."
else
	# Not "-y", so it means "no", and no = empty
	install_confirmation=""
	$HELPER display_info "installations will not be automatically accepted, you'll have to specify your choice for each steps."
fi




# Update APT packages
if [ "$($HELPER exists_command "apt")" = "exists" ]; then

	$HELPER display_info "updating with APT." "$file_log"

	if [ "$($HELPER exists_command "dpkg")" = "exists" ]; then
		dpkg --configure -a								| $HELPER append_log "$file_log"
	fi

	apt update											| $HELPER append_log "$file_log"
	apt install --fix-broken $install_confirmation		| $HELPER append_log "$file_log"
	apt full-upgrade $install_confirmation				| $HELPER append_log "$file_log"

	# Ensure to delete all old packages & their configurations
	apt autopurge $install_confirmation					| $HELPER append_log "$file_log"

	# Just repeat to check if everything is ok
	apt full-upgrade $install_confirmation				| $HELPER append_log "$file_log"


	# apt update
	# apt install --fix-broken $install_confirmation
	# apt full-upgrade $install_confirmation

	# # Ensure to delete all old packages & their configurations
	# apt autopurge $install_confirmation
	
	# # Just repeat to check if everything is ok
	# apt full-upgrade $install_confirmation

	echo ""
	echo ""
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
			read -p "$continue_question" install_confirmation_snapcraft

			if [ "$install_confirmation_snapcraft" = "$yes" ]; then
				snap refresh
			fi
		fi
	fi

	rm -f $file_tmp_updates_available
}

if [ "$($HELPER exists_command "snap")" = "exists" ]; then
	$HELPER display_info "updating with Snap." "$file_log"
	# upgrade_with_snapcraft $install_confirmation
	upgrade_with_snapcraft $install_confirmation | $HELPER append_log "$file_log"
fi




# Update DNF packages (using YUM as fallback if DNF doesn't exist)
if [ "$($HELPER exists_command "dnf")" = "exists" ]; then
	$HELPER display_info "updating with DNF." "$file_log"

	# dnf upgrade $install_confirmation
	dnf upgrade $install_confirmation | $HELPER append_log "$file_log"


elif [ "$($HELPER exists_command "yum")" = "exists" ]; then
	$HELPER display_info "updating with YUM." "$file_log"

	# yum upgrade $install_confirmation
	yum upgrade $install_confirmation | $HELPER append_log "$file_log"

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

					$NAME_ALIAS install fwupd

					if [ "$($HELPER exists_command "fwupdmgr")" = "exists" ]; then
						fwupdmgr upgrade $install_confirmation
					fi
				fi
		fi
else
	$HELPER display_error "can't detect if your system is bare-metal with the command 'systemd-detect-virt', will not upgrade firmwares."
fi




# Properly exit
exit

#EOF
