#!/bin/bash
FILE="$1"

doas -- chown -Rv $USER:$USER $FILE
