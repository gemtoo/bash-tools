#!/bin/bash
LINK="$1"

yt-dlp --skip-playlist-after-errors 5000 --verbose --windows-filenames --no-warnings --no-write-info-json --no-embed-metadata --output "%(title)s" --replace-in-metadata "title" "[ ]" "_" --format "bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]" ${LINK}
