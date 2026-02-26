#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'EOF'
Usage: ./scripts/show_frame.sh VIDEO FRAME_INDEX [OUT_IMAGE]

Extract a frame by index and display it with ffplay.
EOF
  exit 0
fi

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage: ./scripts/show_frame.sh VIDEO FRAME_INDEX [OUT_IMAGE]" >&2
  exit 1
fi

VIDEO="$1"
FRAME_INDEX="$2"
OUT_IMAGE="${3:-/tmp/frame_${FRAME_INDEX}.png}"

if ! [[ "$FRAME_INDEX" =~ ^[0-9]+$ ]]; then
  echo "FRAME_INDEX must be a non-negative integer, got: $FRAME_INDEX" >&2
  exit 1
fi

ffmpeg -v error -y -i "$VIDEO" -vf "select=eq(n\,${FRAME_INDEX})" -vsync 0 -frames:v 1 "$OUT_IMAGE"
ffplay -v error -loop 1 -framerate 1 -i "$OUT_IMAGE" -window_title "frame n=$FRAME_INDEX"
