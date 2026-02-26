#!/usr/bin/env bash
set -euo pipefail

DEFAULT_CAM_DEV="/dev/v4l/by-id/usb-GENERAL_GENERAL_WEBCAM_JH0319_20200710_v012-video-index0"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'EOF'
Usage: ./scripts/record_cam.sh [CAM_DEV] [OUT_VIDEO]

Record webcam video with wall-clock timestamps in frame PTS.

Arguments:
  CAM_DEV    V4L2 device path (default: repo-specific by-id webcam path)
  OUT_VIDEO  Output MKV path (default: cam0_copyts.mkv)
EOF
  exit 0
fi

CAM_DEV="${1:-$DEFAULT_CAM_DEV}"
OUT_VIDEO="${2:-cam0_copyts.mkv}"

ffmpeg -hide_banner -loglevel info -y \
  -use_wallclock_as_timestamps 1 \
  -copyts \
  -fflags nobuffer -flags low_delay \
  -thread_queue_size 64 \
  -f v4l2 -input_format yuyv422 -framerate 30 -video_size 320x240 \
  -i "$CAM_DEV" \
  -an \
  -c:v libx264 -preset ultrafast -tune zerolatency \
  -x264-params bframes=0:scenecut=0 \
  -g 60 -keyint_min 60 \
  "$OUT_VIDEO"
