#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'EOF'
Usage: ./scripts/show_frame_with_ts.sh VIDEO FRAME_INDEX [OUT_IMAGE]

Extract a frame by index, read its timestamp, and display it with timestamp in the window title.
EOF
  exit 0
fi

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage: ./scripts/show_frame_with_ts.sh VIDEO FRAME_INDEX [OUT_IMAGE]" >&2
  exit 1
fi

VIDEO="$1"
FRAME_INDEX="$2"
OUT_IMAGE="${3:-/tmp/frame_${FRAME_INDEX}.png}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! [[ "$FRAME_INDEX" =~ ^[0-9]+$ ]]; then
  echo "FRAME_INDEX must be a non-negative integer, got: $FRAME_INDEX" >&2
  exit 1
fi

TS="$("$SCRIPT_DIR/frame_pts.sh" "$VIDEO" "$FRAME_INDEX")"

ffmpeg -v error -y -i "$VIDEO" -vf "select=eq(n\,${FRAME_INDEX})" -vsync 0 -frames:v 1 "$OUT_IMAGE"
ffplay -v error -loop 1 -framerate 1 -window_title "frame=${FRAME_INDEX}  ts=${TS}" "$OUT_IMAGE"
