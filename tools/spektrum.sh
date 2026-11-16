#!/bin/sh
# Spectrogram picture of each music track (0 to 6 kHz), to look for voices.
for n in menu oyun1 oyun2 boss; do
  ffmpeg -v error -y -threads 2 -i assets/audio/muzik_$n.mp3 -filter_threads 2 -lavfi "aresample=12000,showspectrumpic=s=1600x420:legend=0:scale=log:fscale=lin:color=viridis" -threads 2 kaynak/spek_$n.png
done
