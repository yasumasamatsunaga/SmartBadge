#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Generated test pattern — no downloaded or copyrighted samples required.
ffmpeg -hide_banner -loglevel error -y \
  -f lavfi -i 'testsrc2=size=1280x720:rate=30:duration=11' -an \
  -c:v libx264 -pix_fmt yuv420p "$tmp/source.mp4"

bash ./scripts/convert.sh "$tmp/source.mp4" "$tmp/output.mp4" 1 9 none 270 270
frames="$(ffprobe -v error -select_streams v:0 -show_entries stream=nb_frames -of default=noprint_wrappers=1:nokey=1 "$tmp/output.mp4")"
codec="$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$tmp/output.mp4")"
profile="$(ffprobe -v error -select_streams v:0 -show_entries stream=profile -of default=noprint_wrappers=1:nokey=1 "$tmp/output.mp4")"
[[ "$frames" == 216 && "$codec" == h264 && "$profile" == 'Constrained Baseline' ]]
echo 'Smoke test passed.'
