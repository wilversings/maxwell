#!/bin/bash
# measure_memory.sh - RSS + GPU memory sampler for measure_memory.qml.
#
# Launches a measure_memory[_bare].qml run as a direct child process and
# polls /proc/<pid>/status (VmRSS/VmHWM) and /proc/<pid>/fdinfo
# (drm-memory-vram/drm-memory-gtt, AMD's per-process GPU accounting -
# requires the amdgpu driver; adapt the fdinfo parsing for other vendors)
# every INTERVAL seconds, writing a timestamped CSV. Must launch the QML
# process as its own direct child: reading another process's fdinfo is
# blocked on this kind of system regardless of matching uid. See
# MEMORY_ANALYSIS.md for how this was used and what it found.
#
# Usage:
#   ./measure_memory.sh <label> <interval_seconds> -- <qml-qt6 command...>
#
# Examples:
#   ./measure_memory.sh bare 0.5 -- qml-qt6 measure_memory_bare.qml
#   ./measure_memory.sh gif_steady 0.5 -- qml-qt6 measure_memory.qml gif 1 8000
#   ./measure_memory.sh 3d_steady 0.5 -- qml-qt6 measure_memory.qml 3d 1 8000
#   ./measure_memory.sh 3d_custom_steady 0.5 -- qml-qt6 measure_memory.qml 3d-custom 1 8000
#   ./measure_memory.sh cycle_test 0.5 -- qml-qt6 measure_memory.qml cycle 7 12000
#
# Output: <label>.csv (ts_ms,vmrss_kb,vmhwm_kb,vram_kb,gtt_kb) and
# <label>.log (the QML process's stdout/stderr) in the current directory.
set -uo pipefail

if [ $# -lt 3 ]; then
    echo "Usage: $0 <label> <interval_seconds> -- <command...>" >&2
    exit 1
fi

LABEL="$1"; shift
INTERVAL="$1"; shift
if [ "$1" == "--" ]; then shift; fi

CSV="${LABEL}.csv"
LOG="${LABEL}.log"

echo "ts_ms,vmrss_kb,vmhwm_kb,vram_kb,gtt_kb" > "$CSV"

"$@" > "$LOG" 2>&1 &
PID=$!
echo "Launched PID=$PID for label=$LABEL: $*" >&2

while kill -0 "$PID" 2>/dev/null; do
    TS=$(date +%s%3N)
    STATUS="/proc/$PID/status"
    if [ ! -r "$STATUS" ]; then break; fi
    VMRSS=$(grep -m1 '^VmRSS:' "$STATUS" | awk '{print $2}')
    VMHWM=$(grep -m1 '^VmHWM:' "$STATUS" | awk '{print $2}')
    VRAM=""
    GTT=""
    for f in /proc/$PID/fdinfo/*; do
        [ -r "$f" ] || continue
        if grep -q '^drm-driver:.*amdgpu' "$f" 2>/dev/null; then
            VRAM=$(grep -m1 '^drm-memory-vram:' "$f" | awk '{print $2}')
            GTT=$(grep -m1 '^drm-memory-gtt:' "$f" | awk '{print $2}')
            break
        fi
    done
    echo "${TS},${VMRSS:-},${VMHWM:-},${VRAM:-},${GTT:-}" >> "$CSV"
    sleep "$INTERVAL"
done

wait "$PID" 2>/dev/null
echo "Process $PID exited. CSV: $CSV  LOG: $LOG" >&2
