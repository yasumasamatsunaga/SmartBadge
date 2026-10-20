#!/usr/bin/env bash
set -euo pipefail

# SmartBadge EB180TSL-family MP4 conversion profile, based on physical-device testing.
# Usage: convert.sh INPUT OUTPUT [START_SECONDS=0] [DURATION_SECONDS=9] [CROP=none] [WIDTH=270] [HEIGHT=270]
# CROP is width:height:x:y in pixels after FFmpeg's automatic rotation.

usage() {
  cat >&2 <<'EOF'
Usage: scripts/convert.sh INPUT OUTPUT [START_SECONDS=0] [DURATION_SECONDS=9] [CROP=none] [WIDTH=270] [HEIGHT=270]

Example (tested Pac-Man maze crop; input file must be provided separately):
  scripts/convert.sh source.mkv badge.mp4 52 9 550:624:365:57 232 264

Example (keep the source aspect ratio, within a 270 x 270 safe area):
  scripts/convert.sh my-video.mp4 badge.mp4 0 9 none 270 270
EOF
}

if (( $# < 2 || $# > 7 )); then usage; exit 2; fi
input="$1"
output="$2"
start="${3:-0}"
duration="${4:-9}"
crop="${5:-none}"
content_width="${6:-270}"
content_height="${7:-270}"

command -v ffmpeg >/dev/null || { echo 'Error: ffmpeg is required' >&2; exit 1; }
command -v ffprobe >/dev/null || { echo 'Error: ffprobe is required' >&2; exit 1; }
[[ -f "$input" ]] || { echo "Error: input not found: $input" >&2; exit 1; }
[[ "$output" == *.mp4 ]] || { echo 'Error: output must have .mp4 extension' >&2; exit 2; }
[[ "$start" =~ ^[0-9]+$ ]] || { echo 'Error: START_SECONDS must be an integer >= 0' >&2; exit 2; }
[[ "$duration" =~ ^[1-9][0-9]*$ ]] || { echo 'Error: DURATION_SECONDS must be an integer >= 1' >&2; exit 2; }
if [[ "$crop" != none && ! "$crop" =~ ^[1-9][0-9]*:[1-9][0-9]*:[0-9]+:[0-9]+$ ]]; then
  echo 'Error: CROP must be none or WIDTH:HEIGHT:X:Y' >&2
  exit 2
fi
for value in "$content_width" "$content_height"; do
  [[ "$value" =~ ^[1-9][0-9]*$ ]] || { echo 'Error: WIDTH and HEIGHT must be positive integers' >&2; exit 2; }
  (( value <= 360 && value % 2 == 0 )) || { echo 'Error: WIDTH and HEIGHT must be even and <= 360' >&2; exit 2; }
done

# Crop a source-specific rectangle, then preserve the aspect ratio for generic input.
if [[ "$crop" == none ]]; then
  vf="scale=${content_width}:${content_height}:force_original_aspect_ratio=decrease:flags=lanczos"
else
  vf="crop=${crop},scale=${content_width}:${content_height}:flags=lanczos"
fi
vf+=",pad=360:360:(ow-iw)/2:(oh-ih)/2:black,fps=24,format=yuv420p"
expected_frames=$((duration * 24))

ffmpeg -hide_banner -loglevel error -y \
  -ss "$start" -i "$input" -map 0:v:0 -an \
  -vf "$vf" -frames:v "$expected_frames" \
  -c:v libx264 -profile:v baseline -level:v 3.0 \
  -pix_fmt yuv420p -crf 20 -g 48 -bf 0 \
  -movflags +faststart "$output"

# Validate the produced file; this cannot prove playback on physical hardware.
actual_frames="$(ffprobe -v error -select_streams v:0 -show_entries stream=nb_frames -of default=noprint_wrappers=1:nokey=1 "$output")"
if [[ "$actual_frames" != "$expected_frames" ]]; then
  echo "Error: expected $expected_frames frames, got $actual_frames (source may be too short)" >&2
  exit 1
fi
ffprobe -v error -select_streams v:0 \
  -show_entries stream=codec_name,profile,width,height,r_frame_rate,nb_frames,pix_fmt:format=duration,size \
  -of default=noprint_wrappers=1 "$output"
echo "Generated $output"
