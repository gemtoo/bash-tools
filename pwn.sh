#!/bin/bash
source /etc/init.d/functions.sh
FILE="$1"

ebegin "Passing ownership of $FILE to $USER"
doas -- chown -Rv $USER:$USER $FILE
eend
