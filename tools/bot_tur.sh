#!/bin/sh
# Plays N bot runs headless under the shared lock and throttle and prints the telemetry lines.
# usage: tools/bot_tur.sh <runs> <speed> [extra game args]
n=${1:-1}
speed=${2:-8}
shift 2 2>/dev/null
i=1
while [ "$i" -le "$n" ]; do
	echo "== run $i"
	flock /var/tmp/hayatta-kalma-agir.lock systemd-run --user --scope --quiet -p CPUQuota=200% nice -n 19 \
		timeout 400 godot --headless --path "$(dirname "$0")/.." -- --bot --once --speed="$speed" "$@" 2>&1 | grep --line-buffered -E "^T |ERROR|SCRIPT"
	i=$((i + 1))
done
