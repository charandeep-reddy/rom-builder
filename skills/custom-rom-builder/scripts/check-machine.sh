#!/bin/bash
# Read-only machine check for an Android (LineageOS) build. Changes nothing.
# Usage: bash check-machine.sh [source_dir]
# Heuristics come from one measured build (see references/low-ram-builds.md); treat as starting points.

DIR="${1:-$HOME}"
ram_kb=$(awk '/MemTotal/{print $2}' /proc/meminfo)
swap_kb=$(awk '/SwapTotal/{print $2}' /proc/meminfo)
ram_gb=$(( ram_kb / 1024 / 1024 ))
swap_gb=$(( swap_kb / 1024 / 1024 ))
threads=$(nproc)
free_gb=$(df -BG --output=avail "$DIR" 2>/dev/null | tail -1 | tr -dc '0-9')

echo "RAM:     ${ram_gb} GB"
echo "Swap:    ${swap_gb} GB"
echo "Threads: ${threads}"
echo "Disk free at ${DIR}: ${free_gb} GB"
command -v powerprofilesctl >/dev/null && echo "Power profile: $(powerprofilesctl get 2>/dev/null)"
[ -r /sys/class/power_supply/AC/online ] && echo "On AC power: $(cat /sys/class/power_supply/AC/online)"
echo

total=$(( ram_gb + swap_gb ))
echo "== Assessment =="
if [ "$total" -lt 72 ]; then
  need=$(( 80 - total ))
  echo "RAM+swap is ${total} GB. Aim for about 80 GB for the Soong analysis stage (lineage-24 class)."
  echo "Add about ${need} GB of swap (temporary is fine), for example:"
  echo "  sudo fallocate -l ${need}G /swapfile2 && sudo chmod 600 /swapfile2 && sudo mkswap /swapfile2 && sudo swapon /swapfile2"
else
  echo "RAM+swap is ${total} GB: close to or above the ~80 GB target, enough for the analysis stage (the reference build peaked near 68 GB)."
fi

if [ "${free_gb:-0}" -lt 400 ]; then
  echo "Disk free is ${free_gb} GB. The wiki asks for 400 GB for lineage-21 and later (source ~190 GB + out/ + ccache). Tight: keep ccache small (20 GB) and clean out/ between experiments."
else
  echo "Disk free is ${free_gb} GB: meets the wiki's 400 GB guidance."
fi

# Starting job count: about 1 job per 3 GB of RAM, between 2 and half the threads, at least 2.
j=$(( ram_gb / 3 )); [ "$j" -lt 2 ] && j=2
half=$(( threads / 2 )); [ "$half" -lt 2 ] && half=2
[ "$j" -gt "$half" ] && j=$half
echo "Suggested starting -j for the compile stage: ${j} (heuristic, UNVERIFIED; -j does not affect the analysis stage; a restart repeats it, so choose before the first run)"
[ "$ram_gb" -lt 32 ] && echo "RAM is under 32 GB: run in your own terminal, not as an AI tool's background task (it may be stopped under memory pressure)."
