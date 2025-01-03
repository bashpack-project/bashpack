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




# Display help
# Usage: display_help
display_help() {
	echo "$USAGE"
	echo ""
	echo "A simple command used for testing purposes."
	echo "Custom rules can be added from '$dir_config'."
	echo ""
	echo "$NAME $VERSION"
}


echo "Have you ever seen a P carrying a B ?  "
$HELPER loading_process "sleep 1.3"



	echo "         ,,,		" \
&&	echo "    ,,,,|| _\		" \
&&	echo "   / /  \| 9 \	" \
&&	echo "  $\ \ , \  v/	" \
&&	echo "   / /  \ \,/		" \
&&	echo "   \ \   \_\		" \
&&	echo "    ''''|| |		" \
&&	echo "         \\\|		" \
&&	echo ""




# Properly exit
exit

#EOF
