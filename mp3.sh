#!/bin/bash
# Download mp3 via URL.
URL="$1"

yt-dlp --skip-playlist-after-errors 5000 --verbose --windows-filenames --no-warnings --no-write-info-json --no-embed-metadata --extract-audio --output "%(title)s.mp3" --replace-in-metadata "title" "[ ]" "_" --audio-format mp3 --audio-quality 0 "${URL}"
