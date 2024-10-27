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



. "core/helper.sh"



firewall_config="$dir_config/firewall.conf"
firewall_allowed=$(get_config_value "$dir_config/$file_config" "firewall")



disable_firewall() {
	systemctl stop nftables.service
}




# This script is based on nftables, it can't work without it.
# Testing if nftables is installed on the system, try to install it if not, or exit.
install_firewall() {
	if [[ $(exists_command "nft") != "exists" ]]; then
		echo "Error: nftables not found on the system but is required to configure your firewall with $NAME."
		
		if [[ $(exists_command "apt") = "exists" ]]; then
			echo "Installing nftables with APT..."
			echo "Warning: if iptables is installed, nftables will replace it. "
			echo "Warning: be sure to keep a copy of your currents firewall rulesets."
			read -p "$continue_question" install_confirmation_nftables

			if [[ $install_confirmation_nftables = $yes ]]; then
				apt install -y nftables
				systemctl enable nftables.service
				systemctl restart nftables.service
			else
				# Exit to avoid doing anything else with this script without nftables installed
				exit
			fi
			
		else
			echo "Error: nftables could not been installed with APT."

			# Exit to avoid doing anything else with this script without nftables installed
			exit
		fi

	fi
}



	
# Configure the firewall
create_firewall() {
	
	# now=$(date +%y-%m-%d_%H-%M-%S)
	nftables_file="/etc/nftables.conf"
	nftables_dir="/etc/bashpack/firewall/"
	nftables_file_backup=$nftables_dir"nftables.conf_backup_$now"


	# # Making sure to use nftables
	# apt install -y nftables
	# systemctl enable nftables.service
	# systemctl restart nftables.service

	# Making sure the nftables.conf file exists
	nft list ruleset > $nftables_file

	# Making a backup of your current nftables ruleset
	mkdir -p $nftables_dir
	chmod 755 $nftables_dir
	cp $nftables_file $nftables_file_backup

	echo ""
	echo "A backup of your current nftables firewall ruleset has been saved to "$nftables_file_backup"."
	echo ""

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

	# Deleting current ruleset to get a clean firewall and avoid any issues
	nft flush ruleset

	# Adding the inet filter table to the current firewall
	nft add table inet filter

	# Creating $NAME_UPPERCASE-PREROUTING chain
	# Eveything is closed inbound by default
	nft add chain inet filter $NAME_UPPERCASE-PREROUTING { type filter hook prerouting priority -199\; policy drop\; }
	nft add rule inet filter $NAME_UPPERCASE-PREROUTING ct state related,established counter accept
	nft add rule inet filter $NAME_UPPERCASE-PREROUTING iifname lo counter accept
	# Allowing Docker containers to see each others & to reach internet (works with or without Docker bridges) (this rule is created even if Docker is not installed to anticipate any futures Docker installations)
	nft add rule inet filter $NAME_UPPERCASE-PREROUTING ip saddr 172.0.0.0/8 counter accept
	# Inbound customs rules below
	#nft add rule inet filter $NAME_UPPERCASE-PREROUTING tcp dport <PORT> counter accept

	# Creating $NAME_UPPERCASE-POSTROUTING 
	# Eveything is open outbound by default
	nft add chain inet filter $NAME_UPPERCASE-POSTROUTING { type filter hook postrouting priority -300\; policy accept\; }


	# Saving the new nftables ruleset
	nft list ruleset > $nftables_file

	# Restarting firewall
	systemctl restart nftables.service

	# Restarting Docker (if Docker is installed) to force it using nftables instead of iptables
	if [[ $(exists_command "docker") = "exists" ]]; then
		systemctl restart docker.service
	fi


	echo "Success! New firewall configured."


}


if [[ $firewall_allowed == 1 || $firewall_allowed == 2 ]]; then
	install_firewall
	create_firewall
else 
	echo "Error: firewall management is disabled in $firewall_config"
fi


#EOF