#!/bin/bash
# Wireguard kill-switch

source /etc/init.d/functions.sh

die() {
	eend "${@}"
	exit 1
}

checks () {
	ebegin "Running as root"
	if [ $(id -u) -eq 0 ]; then
		eend $?
	else
		eend $?
		die "This script requires root privileges."
		exit 2
	fi
}



run() {

SHOW=$(wg show)
ON=$(echo "$SHOW" | wc -l)
# Allowed LAN IPs for connections
LANS="192.168.219.0/24"
# Yggdrasil network
ALLOWED_INTERFACES="tun0"

if [ $ON -gt 1 ]; then
		INTERFACE=$(echo "$SHOW" | grep interface | cut -d " " -f2)
		ENDPOINT=$(echo "$SHOW" | grep endpoint | cut -d ":" -f2 | sed "s/ //")
		ALLOWED_INTERFACES="${ALLOWED_INTERFACES} ${INTERFACE}"

		ebegin "Resetting UFW rules"
		ufw --force reset &> /dev/null || die "Failed to reset UFW rules"
		eend $?

		ebegin "Denying all outgoing"
		ufw default deny outgoing &> /dev/null || die "Failed to set rule" ; eend $?
		ebegin "Denying all incoming"
		ufw default deny incoming &> /dev/null || die "Failed to set rule" ; eend $?
		for IFCE in $ALLOWED_INTERFACES; do
			ebegin "Allowing out on ${INTERFACE} from any to any"
			ufw allow out on ${IFCE} from any to any &> /dev/null || die "Failed to set rule" ; eend $?
			ebegin "Allowing in on ${INTERFACE} from any to any"
			ufw allow in on ${IFCE} from any to any &> /dev/null || die "Failed to set rule" ; eend $?
		done
		ebegin "Allowing in from ${ENDPOINT} to any"
		ufw allow in from ${ENDPOINT} to any &> /dev/null || die "Failed to set rule" ; eend $?
		ebegin "Allowing out from any to ${ENDPOINT}"
		ufw allow out from any to ${ENDPOINT} &> /dev/null || die "Failed to set rule" ; eend $?
		for LAN in $LANS; do
			ebegin "Allowing to on ${LAN}"
			ufw allow out to "${LAN}" &> /dev/null || die "Failed to allow out on LAN" ; eend $?
			ebegin "Allowing from on ${LAN}"
			ufw allow from "${LAN}" &> /dev/null || die "Failed to allow in on LAN" ; eend $?
		done

		ufw allow 53 &> /dev/null || die "Failed to set rule" ; eend $?
		ufw enable &> /dev/null || die "Failed to enable UFW" ; eend $?
		ufw status || die "Failed to check status" ; eend $?

	else
		die "No active Wireguard tunnel detected."
	fi
}

checks && run
