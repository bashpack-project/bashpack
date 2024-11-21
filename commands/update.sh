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



continue_question="Do you want to continue? [y/N] "




# # Usage : text_error_cant_install <manager>
# install_package_error() {
# 	echo "Error: could not be installed with ${1}."
# }




# # Function to install packages on the system (and package managers also, because package managers are packages themselves).
# # Package manager order to search packages candidates: Apt -> Snapcraft -> Error "not found"
# # Usage : install_package <manager> <package>
# install_package() {
# 	local manager=${1}
# 	local package=${2}

# 	echo ""
# 	echo "Installing $package with $manager...  "
# 	echo ""

# 	if ([ $manager = "apt" ] && [ $($HELPER exists_command "apt") = "exists" ]) || [ $($HELPER exists_command "apt") = "exists" ]; then
# 		apt install -y $package
# 	elif ([ $manager = "snap" ] && [ $($HELPER exists_command "snap") = "exists" ]) || [ $($HELPER exists_command "snap") = "exists" ]; then
# 		snap install $package
# 	else
# 		echo "$package: Error: package not found."
# 	fi

# 	echo ""
# }




# # Function to delete packages on the system.
# # Package manager order to search packages candidates: Apt -> Snapcraft -> Error "not found"
# # Usage : delete_package $package <$manager> <yes>
# delete_package() {
# 	local package=${1}
# 	local manager=${2}

# 	echo ""
# 	if [ "$manager != "" ]; then
# 		echo "Uninstalling $package with $manager...  "
# 	else
# 		echo "Uninstalling $package with the default system manager...  "
# 	fi
# 	echo ""

# 	if ([ $manager = "apt" ] && [ $($HELPER exists_command "apt") = "exists" ]) || [ $($HELPER exists_command "apt") = "exists" ]; then
# 		apt remove -y $package
# 	elif ([ $manager = "snap" ] && [ $($HELPER exists_command "snap") = "exists" ]) || [ $($HELPER exists_command "snap") = "exists" ]; then
# 		snap remove $package
# 	else
# 		echo "$package: Error: package not found."
# 	fi
# }




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

	$HELPER display_info "updating with APT." "$file_log_update"

	if [ "$($HELPER exists_command "dpkg")" = "exists" ]; then
		dpkg --configure -a								| $HELPER append_log "$file_log_update"
	fi

	apt update											| $HELPER append_log "$file_log_update"
	apt install --fix-broken $install_confirmation		| $HELPER append_log "$file_log_update"
	apt full-upgrade $install_confirmation				| $HELPER append_log "$file_log_update"

	# Ensure to delete all old packages & their configurations
	apt autopurge $install_confirmation					| $HELPER append_log "$file_log_update"

	# Just repeat to check if everything is ok
	apt full-upgrade $install_confirmation				| $HELPER append_log "$file_log_update"


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
	$HELPER display_info "updating with Snap." "$file_log_update"
	# upgrade_with_snapcraft $install_confirmation
	upgrade_with_snapcraft $install_confirmation | $HELPER append_log "$file_log_update"
fi




# Update DNF packages (using YUM as fallback if DNF doesn't exist)
if [ "$($HELPER exists_command "dnf")" = "exists" ]; then
	$HELPER display_info "updating with DNF." "$file_log_update"

	# dnf upgrade $install_confirmation
	dnf upgrade $install_confirmation | $HELPER append_log "$file_log_update"


elif [ "$($HELPER exists_command "yum")" = "exists" ]; then
	$HELPER display_info "updating with YUM." "$file_log_update"

	# yum upgrade $install_confirmation
	yum upgrade $install_confirmation | $HELPER append_log "$file_log_update"

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
					install_package apt fwupd

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
