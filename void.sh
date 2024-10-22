#!/bin/bash
source /etc/init.d/functions.sh
GR='\x1b[32;1m'
RS='\x1b[0m'
DATE=$(date --rfc-3339=s | sed "s/ //g;s/://g")

FILE="$1"
printf "\n"
doas -- mv "$FILE" void-work-"${DATE}" && printf "${GR}*${RS} Work renamed to ${GR}void-work-$DATE${RS}.\n" || echo "unrename" $> /dev/null
FILECOUNT=$(doas -- find void-work-$DATE -type f | wc -l)
doas -- find void-work-$DATE -type f | { I=0; while read; do printf "${GR}*${RS} Total ${GR}$((++I))${RS} file(s) to erase.\r"; done; echo "";}
printf "${GR}*${RS} Erased ${GR}0/$FILECOUNT${RS}.\r"
doas -- wipe -VvzfrnX -p1 "void-work-$DATE" 2>&1 | \
{ I=0; while read; do printf "${GR}*${RS} Erased ${GR}$((++I))/$FILECOUNT${RS}\r"; done; echo "";}
eend
printf "\n"
