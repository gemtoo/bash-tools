#!/bin/bash
#VOL=$(amixer scontents | grep "Master" -A 4 | grep "%" | cut -d ' ' -f5)

plus () {
	#amixer -D pulse sset Master 5%+
	amixer sset Master 5%+
}

minus () {
	#amixer -D pulse sset Master 5%-
	amixer sset Master 5%-
}

#while [ ! $# -eq 0 ]
while true
do
	case "$1" in
		--plus | -p)
			plus
			kill $(pgrep sleep)
			exit
			;;
		--minus | -m)
			minus
			kill $(pgrep sleep)
			exit
			;;
	esac
	shift
done



