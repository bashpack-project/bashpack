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




# Overwrite relatives paths with their absolutes values to ensure right tests results
file_config=$dir_config"/"$NAME_LOWERCASE"_config"
file_systemd_update="$dir_systemd/$NAME_LOWERCASE-updates"

# Creating variables for systemd timers since they are in a list in the main CLI file
file_systemd_timers_update="$dir_systemd/$file_systemd_update.timer"

# Permit to check if files exist or not
check_files() {

	local number_exists=0
	local number_notfound=0

	local directories=(
		$dir_bin
		$dir_src
		$dir_systemd
		$dir_config
		$dir_autocompletion
	)

	local files=(
		$file_main
		$file_main_alias
		$file_autocompletion
		$file_systemd_update
		$file_systemd_timers_update
		$file_current_publication
		$file_config
	)


	for directory in "${directories[@]}"; do
		if [ -d $directory ]; then
			echo "[TEST] EXISTS		-> $directory"
			number_exists=$(number_exists + 1)
		else
			echo "[TEST] NOT FOUND	-> $directory"
			number_notfound=$(number_notfound + 1)
		fi
	done


	for file in "${files[@]}"; do
		if [ -f $file ]; then
			echo "[TEST] EXISTS		-> $file"
			number_exists=$(number_exists + 1)
		else
			echo "[TEST] NOT FOUND	-> $file"
			number_notfound=$(number_notfound + 1)
		fi
	done


	echo ""
	echo "Exist: $number_exists | Not found: $number_notfound"

}


# Properly exit
exit