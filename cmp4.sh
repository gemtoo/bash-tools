#!/bin/bash
# Compress mp4 while saving quality
source /etc/init.d/functions.sh
FILE="$1"

checks() {
	DEPS="ffmpeg"

	for DEP in $DEPS; do
		ebegin "Checking for ${DEP}" && [ "$(command -v ${DEP})" ] ; eend $? || exit
	done
}

run() {
	ebegin "Optimizing $FILE"
	ffmpeg -i ${FILE} -vcodec libx265 -crf 28 ${FILE}-opt.mp4 && mv -v ${FILE}-opt.mp4 ${FILE}
	eend $?
}

checks && run
