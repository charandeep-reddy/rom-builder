#!/bin/bash
# Read-only snapshot of a running build. Changes nothing, touches nothing.
#   bash watch-build.sh /path/to/build.log
# Run it twice some minutes apart and compare the step counts to get the pace.

LOG="${1:?usage: watch-build.sh /path/to/build.log}"

echo "time: $(date '+%F %T')"
last=$(grep -E '^\[ *[0-9]+% [0-9]+/[0-9]+\]' "$LOG" 2>/dev/null | tail -n 1 | cut -c1-140)
echo "latest step: ${last:-none yet (analysis stage prints nothing)}"
grep -q 'BUILD EXIT CODE' "$LOG" 2>/dev/null && echo "RESULT: $(grep 'BUILD EXIT CODE' "$LOG" | tail -n 1)"

echo "processes:"
# Exact process-name matches: `pgrep -f` can match its own command line and give a false "running".
for p in soong_ui soong_build siso ckati ninja; do pgrep -a -x "$p" 2>/dev/null | cut -c1-70 | head -1 | sed 's/^/  /'; done
pgrep -c -x 'clang\+\+-real' >/dev/null 2>&1 && echo "  clang++ jobs: $(pgrep -c -x 'clang++-real')"
pgrep -c -x 'ld.lld' >/dev/null 2>&1 && echo "  linker running (large link, uses several GB of RAM)"

free -m | awk '/Mem/{printf "RAM used %d MB, available %d MB\n",$3,$7} /Swap/{printf "swap used %d MB, free %d MB\n",$3,$4}'
df -h / | awk 'NR==2{print "disk free " $4}'

# Stuck vs slow: a working analysis stage shows soong_build CPU and swap traffic.
if pgrep -f 'bin/soong_build' >/dev/null 2>&1; then
  echo "soong_build is running. swap traffic (KB/s si/so, 3 samples):"
  vmstat 1 3 | tail -3 | awk '{print "  si="$7" so="$8}'
fi
