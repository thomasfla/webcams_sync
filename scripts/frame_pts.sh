#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'EOF'
Usage: ./scripts/frame_pts.sh VIDEO FRAME_INDEX

Print best-effort timestamp (epoch seconds) for a specific frame index.
EOF
  exit 0
fi

if [[ $# -ne 2 ]]; then
  echo "Usage: ./scripts/frame_pts.sh VIDEO FRAME_INDEX" >&2
  exit 1
fi

VIDEO="$1"
FRAME_INDEX="$2"

if ! [[ "$FRAME_INDEX" =~ ^[0-9]+$ ]]; then
  echo "FRAME_INDEX must be a non-negative integer, got: $FRAME_INDEX" >&2
  exit 1
fi

PTS="$(
  ffprobe -v error -select_streams v:0 -show_frames \
    -show_entries frame=best_effort_timestamp_time \
    -of csv=p=0 "$VIDEO" \
  | awk -F',' -v n="$FRAME_INDEX" 'NR==n+1 && $1!="N/A"{print $1; exit}'
)"

if [[ -z "$PTS" ]]; then
  echo "No timestamp found for frame index $FRAME_INDEX in $VIDEO" >&2
  exit 1
fi

echo "$PTS"
