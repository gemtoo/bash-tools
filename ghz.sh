#!/bin/bash
source /etc/init.d/functions.sh

TATE=$(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor | uniq)

switch() {
	
	if [ $TATE == powersave ]; then
		ebegin "Switching to performance mode"
		doas -- cpupower frequency-set -g performance && eend $?
	elif [ $TATE == performance ]; then
		ebegin "Switching to powersave mode"
		doas -- cpupower frequency-set -g powersave && eend $?
	elif [ $TATE != performance ]; then
		ebegin "Switching to powersave mode"
		doas -- cpupower frequency-set -g powersave && eend $?
	fi
}

switch
