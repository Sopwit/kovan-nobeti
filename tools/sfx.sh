#!/bin/sh
# Peak-normalise each raw effect, trim leading silence, convert to mono WAV. Run from the project root.
# It overwrites assets/audio/<name>.wav, including the effects that tools/sentez.py generates.
for f in kaynak/s_*.mp3; do
  n=$(basename "$f" .mp3); n=${n#s_}
  max=$(ffmpeg -v info -threads 2 -i "$f" -af volumedetect -f null - 2>&1 | grep max_volume | sed 's/.*max_volume: //; s/ dB//')
  [ -n "$max" ] || { echo "$n: could not measure, skipped" >&2; continue; }
  gain=$(awk -v m="$max" 'BEGIN{printf "%.1f", -1.5 - m}')
  ffmpeg -v error -y -threads 2 -i "$f" -af "volume=${gain}dB,silenceremove=start_periods=1:start_threshold=-40dB:start_silence=0.003,afade=t=in:d=0.003" -ac 1 -ar 44100 -threads 2 "assets/audio/$n.wav"
  d=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "assets/audio/$n.wav")
  v=$(ffmpeg -v info -threads 2 -i "assets/audio/$n.wav" -af volumedetect -f null - 2>&1 | grep -E 'mean_volume' | sed 's/.*] //')
  echo "$n raw_max=$max gain=$gain dur=$d $v"
done
