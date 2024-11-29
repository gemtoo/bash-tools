#!/bin/bash

RED='\x1b[0;31;1m'
GRN='\x1b[0;32;1m'
YLW='\x1b[0;33;1m'
BLU='\x1b[0;34;1m'
MAG='\x1b[0;35;1m'
CYA='\x1b[0;36;1m'
WHI='\x1b[0;37;1m'
RST='\x1b[0m'

# List of domains
DOMAINS=$(/usr/bin/grep -riIn "server_name" /etc/nginx/ | /usr/bin/tr -s '[:space:]' | /usr/bin/cut -d ' ' -f3 | /usr/bin/sed "s/;//g;s/_//g" | sort | uniq | xargs)

# Loop through each domain
for DOMAIN in $DOMAINS; do
        # Send HTTP GET request
        RESPONSE=$(curl -o /dev/null -s -w "%{http_code}" "https://$DOMAIN")
        if [ "$RESPONSE" -eq 0 ]; then
                RESPONSE=$(curl -o /dev/null -s -w "%{http_code}" "http://$DOMAIN")
        fi

        # Check if swagger exists
        if [ "$RESPONSE" -eq 404 ]; then
                RESPONSE=$(curl -o /dev/null -s -w "%{http_code}" "https://$DOMAIN/api")
        fi

        # Check if the response code is not 200
        if [ "$RESPONSE" -ne 200 ] && [ "$RESPONSE" -ne 403 ]; then
                [ "$RESPONSE" -eq 301 ] && echo -e "$DOMAIN ${YLW}$RESPONSE${RST}"
                [ "$RESPONSE" -eq 302 ] && echo -e "$DOMAIN ${YLW}$RESPONSE${RST}"
                [ "$RESPONSE" -eq 303 ] && echo -e "$DOMAIN ${YLW}$RESPONSE${RST}"
                [ "$RESPONSE" -eq 404 ] && echo -e "$DOMAIN ${YLW}$RESPONSE${RST}"
                [ "$RESPONSE" -eq 502 ] && echo -e "$DOMAIN ${RED}$RESPONSE${RST}"
        else
               echo -e "$DOMAIN ${GRN}$RESPONSE${RST}"
        fi
done
