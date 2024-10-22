#!/bin/bash
source /etc/init.d/functions.sh
FILE="$1"

ebegin "Chmoding $FILE to 755"
doas -- chmod -Rv 755 $FILE
eend
