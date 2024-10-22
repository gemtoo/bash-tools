#!/bin/bash

source logger.lib

SERVERS="77.90.41.244:22"
TARGET_WORKDIR='/root/docker-setups/wireguard'
TARGET_WORKFILE="${TARGET_WORKDIR}/docker-compose.yml"
ROOT_DIRS=$(ls -d */)

function check_targets() {
	for SERVER in $SERVERS; do
		info "Sanity checking target: $SERVER ..."
		local IP=$(echo "$SERVER" | cut -d ':' -f1)
		local PORT=$(echo "$SERVER" | cut -d ':' -f2)
    	ssh -p ${PORT} root@${IP} "(
    		[[ -d ${TARGET_WORKDIR} ]] || (
    			echo -e 'No ${TARGET_WORKDIR} found on target.'
    			exit 1
    		)
    		command -v docker &>/dev/null || (
    			echo -e 'Docker is not installed on target.'
    			exit 1
    		)
    	)"
    done
}

function check_target() {
		info "Sanity checking target: $1 ..."
		local IP=$(echo "$1" | cut -d ':' -f1)
		local PORT=$(echo "$1" | cut -d ':' -f2)
    	ssh -p ${PORT} root@${IP} "(
    		[[ -d ${TARGET_WORKDIR} ]] || (
    			echo -e 'No ${TARGET_WORKDIR} found on target.'
    			exit 1
    		)
    		command -v docker &>/dev/null || (
    			echo -e 'Docker is not installed on target.'
    			exit 1
    		)
    	)"
}

function remove_empty_locks() {
	local LOCKFILES=$(find . -type f | grep ".lock")
	for LOCKFILE in $LOCKFILES; do
		[[ "$(cat $LOCKFILE)" == "" ]] && (
			warn "Dead lockfile ${LOCKFILE} removed."
			rm -vrf "$LOCKFILE"
		)
	done
}

function restart_wireguard_on_targets() {
	for SERVER in $SERVERS; do
		local IP=$(echo "$SERVER" | cut -d ':' -f1)
		local PORT=$(echo "$SERVER" | cut -d ':' -f2)
		info "Restarting WireGuard on ${SERVER} ..."
		ssh -p ${PORT} root@${IP} "docker compose -f ${TARGET_WORKFILE} down && docker compose -f ${TARGET_WORKFILE} up -d"
	done
}

function download_target_configs() {
	remove_empty_locks
	local IP=$(echo "$1" | cut -d ':' -f1)
	local PORT=$(echo "$1" | cut -d ':' -f2)
	info "Downloading configs from server $SERVER ..."
	rsync -e "ssh -p ${PORT}" -avhPHAXx --delete "root@${IP}:${TARGET_WORKDIR}/" "${IP}/"
}

function upload_target_configs() {
	local IP=$(echo "$1" | cut -d ':' -f1)
	local PORT=$(echo "$1" | cut -d ':' -f2)
	info "Uploading configs to server $SERVER ..."
	rsync -e "ssh -p ${PORT}" -avhPHAXx --delete "${IP}/" "root@${IP}:${TARGET_WORKDIR}/"
}

function hire() {
	[[ "$1" == "" ]] && die "Can't hire the void. Need at least 1 argument to the hire()."
	for SERVER in $SERVERS; do
		download_target_configs "$SERVER"
		local IP=$(echo "$SERVER" | cut -d ':' -f1)
		local PORT=$(echo "$SERVER" | cut -d ':' -f2)
		SERVER_PEERS=$(ls "$IP" | grep --color=never "peer")
		for SERVER_PEER in $SERVER_PEERS; do
			local LOCKFILE="${IP}/${SERVER_PEER}/.lock"
			if ! [[ -f "${IP}/${SERVER_PEER}/.lock" ]]; then
				info "${IP}/${SERVER_PEER} has no lock. Locking for user $1."
				local WGCONFDIR="./wg-configs/${1}"
				mkdir -p "${WGCONFDIR}"
				cp "${IP}/${SERVER_PEER}/${SERVER_PEER}.conf" "${WGCONFDIR}/${IP}.conf"
				echo "$1" > "$LOCKFILE"
				upload_target_configs "$SERVER"
				break
			fi
		done
	done
}

function fire() {
	[[ "$1" == "" ]] && die "Can't fire the void. Need at least 1 argument to the hire()."
	local LOCKFILES=$(find . -type f | grep ".lock")
	for LOCKFILE in $LOCKFILES; do
		local LOCKDIR=$(echo "$LOCKFILE" | sed "s/.lock//")
		trace "Checking $LOCKFILE ..."
		grep "$1" "$LOCKFILE" &> /dev/null && (
			info "Deleting $LOCKDIR and configs related to $1."
			rm -rf "$LOCKDIR"
			local WGCONFDIR="./wg-configs/${1}"
			rm -rf "${WGCONFDIR}"
		)
	done
	restart_wireguard_on_targets
	for SERVER in $SERVERS; do
		upload_target_configs "$SERVER"
	done
}

function rename_for_humans() {
	info "Renaming configs for human readability ..."
	find wg-configs -type f | grep --color=never "\.conf" | xargs rename -a "77.90.41.244" "lamborghini"
}

ARGS="$@"

[[ "$(echo "$@" | wc -w)" != 2 ]] && die "Received not 2 arguments."
check_deps "ssh rsync rename"
[[ "$1" == "--hire" ]] && check_targets && hire "$2"
[[ "$1" == "--fire" ]] && check_targets && fire "$2"
rename_for_humans
# Implement no action if person to fire does not exist
# When hiring implement checks if lock for user is already present
