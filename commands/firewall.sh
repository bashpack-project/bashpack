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
# file_LOG_CURRENT_SUBCOMMAND="$dir_log/$CURRENT_SUBCOMMAND.log"
# file_CONFIG_CURRENT_SUBCOMMAND="$dir_config/$CURRENT_SUBCOMMAND.conf"


firewall_allowed="$($HELPER get_config_value "$file_CONFIG_CURRENT_SUBCOMMAND" "$CURRENT_SUBCOMMAND")"


file_nftables="/etc/nftables.conf"
dir_nftables="/etc/$NAME/$CURRENT_SUBCOMMAND"
file_nftables_backup="$dir_nftables/nftables.conf_backup_$now"




# Display help
# Usage: display_help
display_help() {
	echo "$USAGE"
	echo ""
	echo "Configure the firewall of your system."
	echo "Custom rules can be added from '$file_CONFIG_CURRENT_SUBCOMMAND'."
	echo ""
	echo "Options:"
	echo " -i, --install	install the ruleset written at $file_CONFIG_CURRENT_SUBCOMMAND."
	echo " -d, --display	display the current ruleset."
	echo " -r, --restart	restart the firewall."
	echo "     --disable	disable the firewall."
	echo "     --restore	rollback a previous ruleset version."
	echo ""
	echo "$NAME $VERSION"
}




# Install requirements of the sub command
# This function is intended to be used from $CURRENT_CLI with $CURRENT_CLI $command init_command
# (it will only work is init_command is available as an argument with the others options)
# Usage: $CURRENT_CLI $command init_command
init_command() {

	# Create option in the main config file to enable automatic firewall management
	if [ -z "$(cat $file_config | grep "\[command\] $CURRENT_SUBCOMMAND")" ]; then
		echo "
			# [command] $CURRENT_SUBCOMMAND
			# This option allow $NAME to manage the firewall of the system.
			# Default ruleset: [inbounds any block] and [outbounds any allow]. You can edit custom rules in the firewall.conf file.
			# - 0 = do not manage the firewall with $NAME
			# - 1 = use your custom ruleset and reset the firewall every hour and every boot (useful for workstations)
			# - 2 = use your custom ruleset and keep it forever (useful for servers)
			$CURRENT_SUBCOMMAND 0
			" | sed 's/^[ \t]*//' >> $file_config
	fi
}




# Create the custom inbound ruleset file
if [ ! -f "$file_CONFIG_CURRENT_SUBCOMMAND" ]; then
	echo "# Customs inbound rules can be added below" > "$file_CONFIG_CURRENT_SUBCOMMAND"
	echo "# Every lines will automatically be wrapped inside the well formatted nftables command 'nft add rule inet filter $NAME_UPPERCASE-PREROUTING [LINE] counter accept'" >> "$file_CONFIG_CURRENT_SUBCOMMAND"
	echo "# Examples of rules that can be copied, pasted and adapted:" >> "$file_CONFIG_CURRENT_SUBCOMMAND"
	echo "#tcp dport <PORT>" >> "$file_CONFIG_CURRENT_SUBCOMMAND"
	echo "#ip saddr <CIDR>" >> "$file_CONFIG_CURRENT_SUBCOMMAND"
	echo "#ip6 saddr <CIDR>" >> "$file_CONFIG_CURRENT_SUBCOMMAND"
	chmod 755 "$file_CONFIG_CURRENT_SUBCOMMAND"
fi




# Display the current ruleset
# Usage: display_firewall
display_firewall() {
	if [ "$($HELPER exists_command "nft")" = "exists" ]; then
		nft list ruleset
	fi
}




# Disable the current ruleset
# Usage: status_firewall
status_firewall() {
	if [ "$($HELPER exists_command "systemctl")" = "exists" ]; then
		 systemctl is-active nftables.service
	fi
}




# Disable the current ruleset
# Usage: disable_firewall
disable_firewall() {
	if [ "$($HELPER exists_command "systemctl")" = "exists" ]; then
		systemctl stop nftables.service
	fi
}




# Restart the current ruleset
# Usage: restart_firewall
restart_firewall() {
	if [ "$($HELPER exists_command "systemctl")" = "exists" ]; then
		systemctl restart nftables.service
		
		if [ "$(status_firewall)" = "active" ]; then
			$HELPER display_success "firewall has restarted"
		else
			$HELPER display_error "firewall has not restarted"
		fi

	fi
}




# Backup the current ruleset
# Usage: backup_firewall
backup_firewall() {
	if [ "$($HELPER exists_command "nft")" = "exists" ]; then
		# Making a backup of your current nftables ruleset
		mkdir -p $dir_nftables
		chmod 755 $dir_nftables
		nft list ruleset > $file_nftables_backup

		$HELPER display_info "a backup of your current nftables firewall ruleset has been saved to "$file_nftables_backup"."
	fi
}




# Restore a backuped ruleset
# Usage: restore_firewall
restore_firewall() {

	# Ask user to select a file from the backup list
	ls -l "$dir_nftables"
	local restoration_file
	read -p "Enter the file name to restore: " restoration_file

	cp "$dir_nftables/$restoration_file" "$file_nftables"
	
	restart_firewall
}




# This script is based on nftables, it can't work without it.
# Testing if nftables is installed on the system, try to install it if not, or exit.
# Usage: install_firewall
install_firewall() {
	if [ "$($HELPER exists_command "nft")" != "exists" ]; then
		$HELPER display_error "nftables not found on the system but is required to configure your firewall with $NAME."
		
		if [ "$($HELPER exists_command "apt")" = "exists" ]; then
			$HELPER display_info "Installing nftables with APT..."
			$HELPER display_info "Warning: if iptables is installed, nftables will replace it. "
			$HELPER display_info "Warning: be sure to keep a copy of your currents non nftables firewall rulesets."
			read -p "$question_continue" install_confirmation_nftables

			if [ "$($HELPER sanitize_confirmation $install_confirmation_nftables)" = "yes" ]; then
				apt install -y nftables
				systemctl enable nftables.service
				restart_firewall
			else
				# Exit to avoid doing anything else with this script without nftables installed
				exit
			fi
			
		else
			$HELPER display_error "nftables could not been installed with APT."

			# Exit to avoid doing anything else with this script without nftables installed
			exit
		fi

	fi
}



	
# Configure the firewall
create_firewall() {

	# --------------------------
	# Here is what this script will erase and recreate :
	#
	# table inet filter
	#	chain $NAME_UPPERCASE-PREROUTING type filter hook prerouting priority -199; policy drop;
	#		ct state related,established counter accept
	#		iifname lo counter accept
	#	chain $NAME_UPPERCASE-OUTPUT
	#		type filter hook output priority -300; policy accept;
	#
	# Documentation here: https://wiki.nftables.org/wiki-nftables/index.php/Netfilter_hooks
	# --------------------------

	backup_firewall

	# Deleting current ruleset to get a clean firewall and avoid any issues
	nft flush ruleset

	# Adding the inet filter table to the current firewall
	nft add table inet filter

	# Creating $NAME_UPPERCASE-PREROUTING chain
	# Eveything is closed inbound by default
	nft add chain inet filter $NAME_UPPERCASE-PREROUTING { type filter hook prerouting priority -199\; policy drop\; }
	nft add rule inet filter $NAME_UPPERCASE-PREROUTING ct state related,established counter accept
	nft add rule inet filter $NAME_UPPERCASE-PREROUTING iifname lo counter accept
	
	# Inbound customs rules below
	while read -r line; do
		local first_char="$(echo $line | cut -c1-1)"

		# Avoid reading comments and empty lines
		if [ "$first_char" != "#" ] && [ "$first_char" != "" ]; then
			nft add rule inet filter $NAME_UPPERCASE-PREROUTING "$line" counter accept
		fi	
	done < "$file_CONFIG_CURRENT_SUBCOMMAND"

	# Creating $NAME_UPPERCASE-POSTROUTING 
	# Eveything is open outbound by default
	nft add chain inet filter $NAME_UPPERCASE-POSTROUTING { type filter hook postrouting priority -300\; policy accept\; }


	# Saving the new nftables ruleset
	nft list ruleset > "$file_nftables"

	# Restarting firewall
	restart_firewall

	# Restarting Docker (if installed) to force it using nftables instead of iptables
	if [ "$($HELPER exists_command "docker")" = "exists" ]; then
		systemctl restart docker.service
	fi


	$HELPER display_success "new firewall configured."
}





# case "$function_to_launch" in
# 	display)	display_firewall ;;
# 	restart)	restart_firewall ;;
# 	install)
# 				if [ "$firewall_allowed" = "1" ] || [ "$firewall_allowed" = "2" ]; then
# 					install_firewall
# 					create_firewall
# 				else 
# 					$HELPER display_error "firewall management is disabled or misconfigured in $file_CONFIG_CURRENT_SUBCOMMAND"
# 				fi ;;
# 	disable)	disable_firewall ;;
# 	restore)	restore_firewall ;;
# 	*) exit ;;
# esac




if [ ! -z "$2" ]; then
	case "$2" in
		-i|--install)
						if [ "$firewall_allowed" = "1" ] || [ "$firewall_allowed" = "2" ]; then
							install_firewall
							create_firewall
						else 
							$HELPER display_error "firewall management is disabled or misconfigured in $file_CONFIG_CURRENT_SUBCOMMAND"
						fi ;;
		-d|--display)	display_firewall ;;
		-r|--restart)	restart_firewall ;;
		--disable)		disable_firewall ;;
		--restore)		restore_firewall ;;
		--help)			display_help ;;
		init_command)	init_command ;;
		*)				$HELPER display_error "unknown option '$2' from '$1' command."'\n'"$USAGE" && exit ;;
	esac
else
	display_help
fi



# Properly exit
exit

#EOF