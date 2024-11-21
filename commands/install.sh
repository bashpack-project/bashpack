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



# Install packages on the system
# Usage : install_package <package>
install_package() {

	local package="${1}"
	local manager=""

	# Don't do anything if the package is already installed
	if [ "$($HELPER exists_command $package)" = "exists" ]; then
		$HELPER display_success "package '$package' already installed."
	else

		$HELPER display_info "starting package '$package' installation."

		# Test every supported package managers until finding a compatible
		if [ "$($HELPER exists_command apt)" = "exists" ]; then
			apt install -y $package	| $HELPER append_log
			manager="apt"

		elif [ "$($HELPER exists_command dnf)" = "exists" ]; then
			dnf install $package	| $HELPER append_log
			manager="dnf"

		elif [ "$($HELPER exists_command yum)" = "exists" ]; then
			yum install $package	| $HELPER append_log
			manager="yum"

		elif [ "$($HELPER exists_command snap)" = "exists" ]; then
			snap install $package	| $HELPER append_log
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





# # Delete package from the system
# # Usage : delete_package <package>
# delete_package() {

# 	local package="${1}"


# 	# Need to create automatic package manager detection from where the package has been intalled


# }



install_package "${1}"

# $HELPER "loading" $(install_package ${1})



# Properly exit
exit

#EOF
