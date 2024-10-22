#!/bin/bash
source /etc/init.d/functions.sh
FILE="$1"

checks() {
	DEPS="ffmpeg convert"

	for DEP in $DEPS; do
		ebegin "Checking for ${DEP}" && [ "$(command -v ${DEP})" ] ; eend $? || exit
	done
}

run() {
	ebegin "Converting $FILE to $FILE.gif"
	ffmpeg -loglevel info -i "$FILE" -vf scale=460:-1 -r 10 -f image2pipe -vcodec ppm - | convert -delay 5 -loop 0 - "$FILE.gif"
	eend $?
}

checks && run
