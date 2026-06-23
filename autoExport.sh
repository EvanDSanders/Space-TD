#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

function run() {
  sleep 1
  notify-send "Exporting StarShip"
  ./export.sh
}

while :; do
    inotifywait "./StarShip 5.blend" && run
    sleep 1
done
