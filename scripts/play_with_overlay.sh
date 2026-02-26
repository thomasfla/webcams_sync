#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'EOF'
Usage: ./scripts/play_with_overlay.sh VIDEO

Open interactive playback with frame index and PTS overlay.

Optional env:
  FONT_FILE=/path/to/font.ttf (default: DejaVuSans)
EOF
  exit 0
fi

if [[ $# -ne 1 ]]; then
  echo "Usage: ./scripts/play_with_overlay.sh VIDEO" >&2
  exit 1
fi

VIDEO="$1"
FONT_FILE="${FONT_FILE:-/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf}"

ffplay -vf "drawtext=fontfile=${FONT_FILE}:text='frame=%{n}  pts=%{pts} s':x=10:y=10:box=1:boxcolor=black@0.5:fontcolor=white" "$VIDEO"
