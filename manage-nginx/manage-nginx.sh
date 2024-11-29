#!/bin/bash
source logger.lib

# Colors
RED='\x1b[0;31;1m'
GRN='\x1b[0;32;1m'
YLW='\x1b[0;33;1m'
BLU='\x1b[0;34;1m'
MAG='\x1b[0;35;1m'
RST='\x1b[0m'

DEPS="nginx certbot systemctl dig find grep whoami certbot sed curl openssl"
ARGS="$*"
ARG_COUNT=$(echo "$ARGS" | wc -w)

ACTION="$1"
DNS="$2"
DSTIP="$3"
IP=""
IP_REGEX="^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$"

check_deps "$DEPS"

function correct_usage_create() {
	warn "Usage 1: ${GRN}sudo $0 --create example.com 192.168.x.yz:port"
}
function correct_usage_delete() {
	warn "Usage 2: ${GRN}sudo $0 --delete example.com"
}
function correct_usage_check() {
	warn "Usage 3: ${GRN}sudo $0 --check"
}

function nginx_reload() {
	debug "Reloading Nginx ..."
	nginx -t &> /dev/null && systemctl reload nginx || die "Failed to reload Nginx. (nginx -t failed)"
}

function nxrelink() {
        rm -rf /etc/nginx/sites-enabled/* || die "Failed to remove config symlinks."
        local CONFIGS=$(find /etc/nginx/sites-available -type f | grep "\.conf")
        for CONFIG in $CONFIGS; do
                trace "Relinking config $(basename ${CONFIG}) ..."
                chmod 755 $CONFIG || die "Failed to set permissions for $CONFIG."
                ln -s $CONFIG /etc/nginx/sites-enabled/ || die "Failed to create symlink for $CONFIG."
        done
        nginx_reload
}

function what_is_my_ip() {
	debug "Sending a reuqest to determine our current public IP address ..."
	IP=$(curl -s 'https://ifconfig.me' || die "Failed to request from https://ifconfig.me")
	if [[ $IP =~ $IP_REGEX ]]; then
		info "Success. Our IP is ${GRN}$IP${WHI}.${RST}"
	else
		die "An IP '${IP}' is not an IP address."
	fi
}

function check_first_arg() {
	debug "Checking sanity of arguments ..."
	if [ "${1}" != "--create" ] && [ "${1}" != "--delete" ] && [ "${1}" != "--check" ]; then
		die "1st argument must be either ${GRN}--create${WHI}, ${GRN}--delete${WHI} or ${GRN}--check${WHI}.${RST}"
	fi
	if [ "${1}" == "--create" ] && [ "$ARG_COUNT" -ne 3 ]; then
		correct_usage_create
		exit 1
	fi
	if [ "${1}" == "--delete" ] && [ "$ARG_COUNT" -ne 2 ]; then
		correct_usage_delete
		exit 1
	fi
	if [ "${1}" == "--check" ] && [ "$ARG_COUNT" -ne 1 ]; then
		correct_usage_check
		exit 1
	fi
}

# Work directory
W="/etc/nginx/sites-available"

# Work config
WCFG="${W}/${DNS}.conf"

function check_if_dns_record_exists() {
	local OUR_IP="86.57.245.73"
	info "Checking DNS A record ..."

	A_RECORD=$(dig +short "${DNS}")
	if [[ "${A_RECORD}" == "${IP}" ]]; then
		return 0
	else
		die "No proper DNS A record found."
    fi
}

function check_if_self_signed_keys_present_and_create_them_if_not() {
	local KEYDIR="/etc/nginx/keys"
	local KEYFILE="${KEYDIR}/private.key"
	local CERTFILE="${KEYDIR}/certificate.crt"
	local REQFILE="${KEYDIR}/request.csr"
	[[ -d "${KEYDIR}" ]] || mkdir -p "${KEYDIR}"
	# This function is a workaround
	# These files are needed as placeholders for the real certbot certificates in the future
	debug "Checking whether self-signed certs are in place ..."
	[[ -f "${KEYFILE}" ]] && [[ -f "${CERTFILE}" ]] && [[ -f "${REQFILE}" ]] || (
		trace "Generating private RSA key ..."
		openssl genrsa -out "${KEYFILE}" 2048 || die "Failed to generate ${KEYFILE}"
		trace "Creating a request file ..."
		openssl req -new -key "${KEYFILE}" -subj "/C=US/ST=State/L=City/O=Organization/CN=yourdomain.com" -out "${REQFILE}" || die "Failed to generate ${REQFILE}"
		trace "Creating a certificate file ..."
		openssl x509 -req -days 365000 -in "${REQFILE}" -signkey "${KEYFILE}" -out "${CERTFILE}" || die "Failed to generate ${CERTFILE}"
	)
}

function sanity_checks() {
        [[ "$(whoami)" != "root" ]] && die "Run this as root user."
        local SITESA="/etc/nginx/sites-available"
        local SITESE="/etc/nginx/sites-enabled"
        [ -d "${SITESA}" ] || mkdir -p "${SITESA}"
        [ -d "${SITESE}" ] || mkdir -p "${SITESE}"
        [[ "$ARG_COUNT" -ne 1 ]] && [[ "$ARG_COUNT" -ne 2 ]] && [[ "$ARG_COUNT" -ne 3 ]] && (
        	correct_usage_create
        	correct_usage_delete
        	correct_usage_check
        	exit 1
        )
        check_first_arg "$ACTION"
        what_is_my_ip
        check_if_self_signed_keys_present_and_create_them_if_not
}

function prepare_config() {
	debug "Preparing the config ..."
	cp "./template-configs/sample.conf" "${WCFG}" || die "No sample.conf found."
	sed -i "s/fqdn-placeholder/${DNS}/g;s/ipaddr-placeholder/${DSTIP}/g" "${WCFG}" || die "${WCFG} for sed not found."
	nxrelink || return 1
}

function deploy_certs() {
	debug "Generating certificates ..."
	certbot --nginx --domain "${DNS}" || die "CertBot failed."
	sed -i '2,5d' "${WCFG}" || die "No ${WCFG} in deploy_certs()"
	nxrelink || die "Failed Nginx test."
}

function reminder() {
	info "Remember to place the config appropriately."
}

function inactivate_configs() {
	local INACTIVE_CONFIGS_DIR="/etc/nginx/inactive-configs"
	if ! [[ -d "$INACTIVE_CONFIGS_DIR" ]]; then
		mkdir -p "$INACTIVE_CONFIGS_DIR" || die "Failed to create ${INACTIVE_CONFIGS_DIR}."
	fi
	local CONFIGS_TO_INACTIVATE=$(grep "$DNS" -riIn /etc/nginx/sites-available | cut -d ':' -f1 | sort | uniq)
	WC=$(echo "${CONFIGS_TO_INACTIVATE}" | wc -w)
	[[ "${WC}" -eq 0 ]] && warn "No configs were found for ${DNS}."
	for CFG_TARGET in $CONFIGS_TO_INACTIVATE; do
		info "Moving $CFG_TARGET to $INACTIVE_CONFIGS_DIR"
		mv "${CFG_TARGET}" "${INACTIVE_CONFIGS_DIR}" || die "Failed to move config."
	done
}

function delete_certificates() {
	debug "Deleting ${DNS} certificate ..."
	certbot delete --non-interactive --cert-name "${DNS}" || die "CertBot failed."
	nxrelink
}

sanity_checks
[ "${1}" == "--create" ] && (
	prepare_config || die "Prepare stage failed."
	deploy_certs
	reminder
)

[ "${1}" == "--delete" ] && (
	ask_confirmation "Do you really want to deactivate ${DNS}?"
	inactivate_configs
	delete_certificates
)
