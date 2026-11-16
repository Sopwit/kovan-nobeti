#!/bin/sh
# Print integrated loudness (LUFS), loudness range and true peak for each file.
for f in "$@"; do
  r=$(ffmpeg -hide_banner -nostats -threads 2 -i "$f" -af ebur128=peak=true -f null - 2>&1 | awk '/Integrated loudness/{s=1} s&&/ I:/{i=$2} s&&/LRA:/{l=$2} s&&/Peak:/{p=$2} END{print "I=" i " LUFS  LRA=" l "  TP=" p " dBFS"}')
  echo "$(basename "$f")  $r"
done
