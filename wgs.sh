#!/bin/bash
echo " "
source /etc/init.d/functions.sh

SHOW=$(doas -- wg show)
ON=$(echo "$SHOW" | wc -l)
INTERFACE=$(echo "$SHOW" | grep interface | cut -d " " -f2)

if [ $ON -gt 1 ]; then
	doas -- /etc/init.d/wg-quick.camaro stop
#	ebegin "Detected $INTERFACE tunnel" && eend
#	ebegin "Disabling Wireguard"
#	doas -- wg-quick down $INTERFACE &> /dev/null && eend
#	ebegin "Remembering $INTERFACE in /tmp for future re-enabling"
#	doas -- echo "$INTERFACE" > /var/tmp/wgs-if.txt && eend
#	printf "\n\x1b[31;1minterface\x1b[0m: $(tput setaf 1)off$(tput sgr0)\n"
else
	doas -- /etc/init.d/wg-quick.camaro start
#	ebegin "Enabling Wireguard"
#	doas -- wg-quick up $(cat /var/tmp/wgs-if.txt) &> /dev/null
#	einfo "Tunnel $(doas -- wg show | grep interface | cut -d " " -f2) enabled." && eend
#	echo " "
#	doas -- wg show
fi
#echo " "
