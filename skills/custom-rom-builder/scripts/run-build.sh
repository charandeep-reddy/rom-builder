#!/bin/bash
# Run a LineageOS-style build in YOUR OWN terminal (recommended: inside tmux).
#
#   DEVICE=<codename> [TREE=~/android/lineage] [JOBS=4] [LOG=~/android/build.log] bash run-build.sh
#
# Safe to run again: finished compile steps are kept (the analysis stage repeats).
# Ends with a line "BUILD EXIT CODE: n" in the log. Read THAT, not a task's status.

set -u
: "${DEVICE:?set DEVICE=<codename>, for example DEVICE=marble}"
TREE="${TREE:-$HOME/android/lineage}"
JOBS="${JOBS:-4}"
LOG="${LOG:-$(dirname "$TREE")/build.log}"

cd "$TREE" || { echo "source tree not found: $TREE"; exit 1; }

# Some AI-tool shells define grep as a wrapper (ugrep) that breaks LineageOS envsetup.
unset -f grep 2>/dev/null || true

# shellcheck disable=SC1091
source build/envsetup.sh
breakfast "$DEVICE" || { echo "breakfast failed for $DEVICE"; exit 1; }

if command -v ccache >/dev/null 2>&1; then
  export USE_CCACHE=1
  export CCACHE_EXEC="$(command -v ccache)"
fi

# 'm' is a real executable; 'mka' is a shell function and cannot run under nice/systemd-inhibit.
cmd=(m bacon "-j${JOBS}")
if command -v systemd-inhibit >/dev/null 2>&1; then
  cmd=(systemd-inhibit --what=sleep:idle --who=rom-build --why=ROM-build "${cmd[@]}")
fi

nice -n 10 "${cmd[@]}" 2>&1 | tee -a "$LOG"
echo "BUILD EXIT CODE: ${PIPESTATUS[0]}" | tee -a "$LOG"
