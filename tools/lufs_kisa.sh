#!/bin/sh
# Short effects are below the 400 ms gate of EBU R128, so measure each one looped back to back for 4 s.
for f in "$@"; do
  i=$(ffmpeg -hide_banner -nostats -threads 2 -stream_loop 200 -i "file:$f" -t 4 -af ebur128 -f null - 2>&1 | awk '/Integrated loudness/{s=1} s&&/ I:/{print $2}')
  echo "$(basename -- "$f" .wav) $i"
done
