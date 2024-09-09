#!/bin/bash
# Usage: generate QR code ./qr.sh "string"
CONTENT="$1"

qrencode --type=ANSIUTF8 "${CONTENT}"
