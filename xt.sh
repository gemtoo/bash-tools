#!/bin/bash
# Unarchiver script
source /etc/init.d/functions.sh

ARC="$1"

die() {
	eerror "$@"
	exit 1
}

checks() {	
	[[ -f $ARC ]] || die "${ARC} is not a valid file."
	ARC="$(readlink -f "$ARC")"

	DEPS="tar bunzip2 gunzip unzip 7z"
	for DEP in $DEPS; do
		[ "$(command -v ${DEP})" ] || die "Dependency ${DEP} not found."
	done
}

run() {
	ebegin "Unpacking $(basename $ARC)"
	case "$ARC" in
	    *.tar.bz2)   tar xjf "$ARC"     ;;
	    *.tar.gz)    tar xzf "$ARC"     ;;
	    *.tar.xz)    tar xf "$ARC"     ;;
	    *.bz2)       bunzip2 "$ARC"     ;;
	    *.rar)       unrar e "$ARC"     ;;
	    *.gz)        gunzip "$ARC"      ;;
	    *.tar)       tar xf "$ARC"      ;;
	    *.tbz2)      tar xjf "$ARC"     ;;
	    *.tgz)       tar xzf "$ARC"     ;;
	    *.zip)       unzip "$ARC"       ;;
	    *.7z)        7z x "$ARC"        ;;
    	*)           eend "Unrecognized archive format of $(basename $ARC)" ;;
	esac
	eend $?
}

checks && run
