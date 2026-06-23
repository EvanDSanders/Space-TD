#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"


# blend_file="PhysPlane.blend"
blend_file="StarShip 5.blend"

# blend_file="${1:-}"
# if [[ -z "$blend_file" ]]; then
#   blend_file="$(find . -maxdepth 1 -name '*.blend' -print -quit)"
# fi

if [[ -z "$blend_file" ]]; then
  echo "No .blend file found. Pass one as an argument." >&2
  exit 1
fi


rm -rf ./Objects

# blender -b "$blend_file" --python AutoExport.py
blenderEXP -b "$blend_file" --python AutoExport.py
