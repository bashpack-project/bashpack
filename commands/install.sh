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




# Clear user choice to the simple "-y" option or leave it empty.
# It will be used as-it with the differents commands.
# Examples :
# - user input is not required	: apt install -y
# - user input is required		: apt install
if [ "$($HELPER sanitize_confirmation $install_confirmation)" = "yes" ]; then
	install_confirmation="-y"
	$HELPER display_info "all installations will be automatically accepted."
else
	# Not "-y", so it means "no", and no = empty
	install_confirmation=""
	$HELPER display_info "installations will not be automatically accepted, you'll have to specify your choice for each steps."
fi





# Install packages on the system
# Usage : install_package <manager> <package>
install_package() {

	local manager="${1}"
	local package="${2}"
	

	if [ "$($HELPER exists_command $manager)" = "exists" ]; then

		if [ "$manager" = "apt" ]; then
			apt install $package $install_confirmation
		fi

		
		if [ "$manager" = "dnf" ]; then
			dnf install $package $install_confirmation
		fi

		
		if [ "$manager" = "yum" ]; then
			yum install $package $install_confirmation
		fi

		
		if [ "$manager" = "snap" ]; then
			snap install $package $install_confirmation
		fi

		if [ "$($HELPER exists_command $package)" = "exists" ]; then
			display_success "package '$package' has been installed with '$manager'."
		else
			display_error "package '$package' has not been installed with '$manager'."
		fi

	fi

}





# # Delete package from the system
# # Usage : delete_package <package>
# delete_package() {

# 	local package="${1}"


# 	# Need to create automatic package manager detection from where the package has been intalled


# }




install_package $1 $2



# Properly exit
exit

#EOF
