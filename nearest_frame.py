#!/usr/bin/env python3
"""
Find and extract the nearest frame to a given timestamp (epoch seconds) based on PTS.

Works best with files recorded using:
  -use_wallclock_as_timestamps 1 -copyts

Usage examples:
  ./nearest_frame.py cam0_copyts.mkv 1772097498.033
  ./nearest_frame.py cam0_copyts.mkv 1772097498.033 --show
  ./nearest_frame.py cam0_copyts.mkv 1772097498.033 --out /tmp/frame.png
"""

import argparse
import math
import subprocess
import sys
from decimal import Decimal

def run(cmd: list[str]) -> str:
    p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if p.returncode != 0:
        raise RuntimeError(f"Command failed:\n  {' '.join(cmd)}\n\nstderr:\n{p.stderr.strip()}")
    return p.stdout

def iter_pts_seconds(video_path: str):
    # best_effort_timestamp_time for each frame; may include extra CSV fields; take first column.
    cmd = [
        "ffprobe", "-v", "error",
        "-select_streams", "v:0",
        "-show_frames",
        "-show_entries", "frame=best_effort_timestamp_time",
        "-of", "csv=p=0",
        video_path,
    ]
    out = run(cmd)
    for line in out.splitlines():
        line = line.strip()
        if not line or line == "N/A":
            continue
        first = line.split(",")[0].strip()
        try:
            yield float(first)
        except ValueError:
            continue

def find_nearest_frame(video_path: str, target_ts: float):
    best = None  # (abs_diff, frame_index, pts)
    for idx, pts in enumerate(iter_pts_seconds(video_path)):
        d = abs(pts - target_ts)
        if best is None or d < best[0]:
            best = (d, idx, pts)
    if best is None:
        raise RuntimeError("No frame timestamps found (file may have no video stream).")
    return best  # diff, idx, pts

def extract_frame(video_path: str, frame_idx: int, out_path: str):
    cmd = [
        "ffmpeg",
        "-v", "error",
        "-y",                    # overwrite output without asking
        "-i", video_path,
        "-vf", f"select=eq(n\\,{frame_idx})",
        "-vsync", "0",
        "-frames:v", "1",
        out_path,
    ]
    run(cmd)


def show_image(path: str, title: str):
    cmd = [
        "ffplay", "-v", "error",
        "-loop", "1", "-framerate", "1",
        "-window_title", title,
        path,
    ]
    subprocess.run(cmd)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("video", help="Input video file")
    ap.add_argument("timestamp", help="Target timestamp in epoch seconds (float ok)")
    ap.add_argument("--out", default=None, help="Output image path (default: /tmp/frame_<n>.png)")
    ap.add_argument("--show", action="store_true", help="Display the extracted frame using ffplay")
    args = ap.parse_args()

    try:
        target = float(args.timestamp)
    except ValueError:
        ap.error("timestamp must be a number (epoch seconds)")

    diff, idx, pts = find_nearest_frame(args.video, target)

    out_path = args.out or f"/tmp/frame_{idx}.png"
    extract_frame(args.video, idx, out_path)

    # Print result (machine- and human-friendly)
    print(f"target_ts={target:.6f}")
    print(f"nearest_frame={idx}")
    print(f"frame_ts={pts:.6f}")
    print(f"abs_diff_s={diff:.6f}")
    print(f"output={out_path}")

    if args.show:
        title = f"frame={idx}  ts={pts:.6f}  diff={diff:.3f}s"
        show_image(out_path, title)

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)
