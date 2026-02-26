import sys, time
from datetime import datetime, timezone

hz = 100
period = 1.0 / hz

t_next = time.monotonic()
while True:
    ns = time.time_ns()
    sec = ns / 1e9
    sys.stdout.write(f"\r{sec:.3f}")
    sys.stdout.flush()

    t_next += period
    dt = t_next - time.monotonic()
    if dt > 0:
        time.sleep(dt)
