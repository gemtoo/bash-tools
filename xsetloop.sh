#!/bin/sh

while true; do
	#LAY=$(setxkbmap -query | sed -e "s/.*:.....//;1d;2d")
	LAY=$(xset -q | grep LED | awk '{ print $10 }')
	if [ "$LAY" -eq "00000000" ]; then
	    LAY="en"
	else
	    LAY="ru"
	fi
	VOL=$(amixer get Master | tail -n1 | sed -r 's/.*\[(.*)%\].*/\1/')
	DF=$(df -h | grep "/dev/dm-0" | tr -s '[:space:]' | cut -d " " -f4)

	SHOW=$(doas -- wg show)
	ON=$(echo "$SHOW" | wc -l)
	INTERFACE=$(echo "$SHOW" | grep interface | cut -d " " -f2)
	BAT=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep percentage | sed "s/ //g" | cut -d ':' -f2)
	if [ $ON -gt 1 ]; then
		xsetroot -name "      $INTERFACE - $BAT - <$DF> - Vol. $VOL - [$LAY] - $(TZ='Europe/Moscow' date '+%B %d, %A') - $(TZ='Europe/Moscow' date '+%H:%M:%S')"
	else
		xsetroot -name "      OFF - $BAT - <$DF> - Vol. $VOL - [$LAY] - $(TZ='Europe/Moscow' date '+%B %d, %A') - $(TZ='Europe/Moscow' date '+%H:%M:%S')"
	fi
	sleep 0.5
done
