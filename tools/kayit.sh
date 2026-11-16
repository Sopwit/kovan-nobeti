#!/bin/sh
# Records a short bot clip with Godot's movie writer and tiles frames from it into one contact sheet.
# Runs under the shared lock and throttle. usage: tools/kayit.sh <name> <seconds, at most 20> [game args]
name=$1
# the name is a file stem inside the output folder, never a path
case "$name" in ""|*/*) echo "usage: tools/kayit.sh <name> <seconds> [game args]" >&2; exit 2 ;; esac
secs=${2:-10}
if [ "$#" -ge 2 ]; then shift 2; else shift "$#"; fi
[ "$secs" -le 20 ] || secs=20
out=/var/tmp/kovan/inc
mkdir -p "$out"
rm -f "$out/$name.avi"
root="$(cd "$(dirname "$0")/.." && pwd)"
lock="flock /var/tmp/hayatta-kalma-agir.lock systemd-run --user --scope --quiet -p CPUQuota=200% nice -n 19"
$lock timeout 240 godot --path "$root" --write-movie "$out/$name.avi" --fixed-fps 30 --quit-after $((secs * 30)) -- --bot "$@" >"$out/$name.log" 2>&1 || { echo "recording failed, see $out/$name.log" >&2; exit 1; }
$lock ffmpeg -v error -y -threads 2 -i "file:$out/$name.avi" -threads 2 -filter_threads 2 -vf "fps=2,scale=480:-1,tile=4x5" -frames:v 1 -q:v 3 "$out/$name.jpg"
ls -la "$out/$name.jpg" "$out/$name.avi" | awk '{print $5, $9}'
