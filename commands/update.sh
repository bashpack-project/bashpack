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



# . "core/helper.sh"
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

# 	if ([ $manager = "apt" ] && [ $($current_cli helper exists_command "apt") = "exists" ]) || [ $($current_cli helper exists_command "apt") = "exists" ]; then
# 		apt install -y $package
# 	elif ([ $manager = "snap" ] && [ $($current_cli helper exists_command "snap") = "exists" ]) || [ $($current_cli helper exists_command "snap") = "exists" ]; then
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

# 	if ([ $manager = "apt" ] && [ $($current_cli helper exists_command "apt") = "exists" ]) || [ $($current_cli helper exists_command "apt") = "exists" ]; then
# 		apt remove -y $package
# 	elif ([ $manager = "snap" ] && [ $($current_cli helper exists_command "snap") = "exists" ]) || [ $($current_cli helper exists_command "snap") = "exists" ]; then
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
if [ "$($current_cli helper sanitize_confirmation $install_confirmation)" = "yes" ]; then
	install_confirmation="-y"
	$current_cli helper display_info "all installations will be automatically accepted."
else
	# Not "-y", so it means "no", and no = empty
	install_confirmation=""
	$current_cli helper display_info "installations will not be automatically accepted, you'll have to specify your choice for each steps."
fi




# Update APT packages
if [ "$($current_cli helper exists_command "apt")" = "exists" ]; then
	$current_cli helper display_info "updating with APT."

	if [ "$($current_cli helper exists_command "dpkg")" = "exists" ]; then
		dpkg --configure -a
	fi
	apt update
	apt install --fix-broken $install_confirmation
	apt full-upgrade $install_confirmation

	# Ensure to delete all old packages & their configurations
	apt autopurge $install_confirmation
	
	# Just repeat to check if everything is ok
	apt full-upgrade $install_confirmation

	echo ""
	echo ""
fi




# Update Snapcraft packages
# Usage : upgrade_with_snapcraft <-y>
upgrade_with_snapcraft() {
	# List available updates & ask for update if found any (or auto update if <-y>).
	if [ "$(snap refresh --list | grep -v "All snaps up to date.")" ]; then

		snap refresh --list

		if [ "${1}" = "-y" ]; then
			snap refresh
		else
			read -p "$continue_question" install_confirmation_snapcraft

			if [ "$install_confirmation_snapcraft" = "$yes" ]; then
				snap refresh
			fi
		fi
	fi
}

if [ "$($current_cli helper exists_command "snap")" = "exists" ]; then
	$current_cli helper display_info "updating with Snap."
	upgrade_with_snapcraft $install_confirmation
fi




# Update YUM packages
if [ "$($current_cli helper exists_command "yum")" = "exists" ]; then
	$current_cli helper display_info "updating with YUM."

	yum upgrade $install_confirmation

	echo ""
	echo ""
fi




# Update firmwares with fwupd
# Checking if the system is bare-metal (and not virtualized) with the "systemd-detect-virt" command and if not bare-metal, firmwares will not be updated.
if [ "$($current_cli helper exists_command "systemd-detect-virt")" = "exists" ]; then
		if [ "$(systemd-detect-virt)" = "none" ]; then

				# Process to firmware updates with fwupdmgr
				if [ "$($current_cli helper exists_command "fwupdmgr")" = "exists" ]; then

						$current_cli helper display_info "updating with fwupd (firmwares)."
						fwupdmgr upgrade $install_confirmation
				else

					$current_cli helper display_info "starting firmwares updates (fwupd)."
					install_package apt fwupd

					if [ "$($current_cli helper exists_command "fwupdmgr")" = "exists" ]; then
						fwupdmgr upgrade $install_confirmation
					fi
				fi
		fi
else
	$current_cli helper display_error "can't detect if your system is bare-metal with the command 'systemd-detect-virt', will not upgrade firmwares."
fi




# Properly exit
exit

#EOF
