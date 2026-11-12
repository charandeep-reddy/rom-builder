# Running and monitoring a multi-hour build

Learned over one 12+ hour build with an AI assistant watching. The assistant should be quiet, accurate and economical.

## Who runs the build

The user, in their own terminal (ideally inside tmux), with `scripts/run-build.sh`. The assistant watches the log read-only. Reason: AI tools may stop background jobs under memory pressure, and the analysis stage triggers it. A job started by the tool was stopped twice (at 49% and again in the analysis stage).

## What to watch (cheap shell loop, no polling by the model)

A small loop that exits on the first interesting event, re-armed after each event (watch tools may expire after about 30 minutes):

| Event | Trigger used | Response |
|---|---|---|
| Build ended | log contains `BUILD EXIT CODE` | Read the real code; verify the zip (below) |
| Process gone | no `run-build.sh` and no `siso`/`soong_ui` | Read the log tail; find the first real error; tell the user |
| Low swap | free swap under 8 GB (6 GB earlier) | Add a swap file (see below) |
| Low disk | free under 30-45 GB, depending on stage | Free space (see below) |
| Compile started | first `[ NN% x/y ]` line after the silent analysis | Report pace and ETA |
| Periodic pace | every 20-30 min | Report steps done, steps/min, ETA |

## Pace and ETA

pace = (steps_now - steps_before) / minutes. ETA = remaining_steps / pace. Pace varied 225-910 steps/min over one build (light steps are fast, heavy C++/links are slow, packaging is slow again). Always give a range and say which side it leans to.
When a restarted build resumes, the step total drops (finished steps are skipped). That is the proof that progress was kept.

## Reporting rules that mattered

1. **Read the clock (`date`) before quoting a time.** Never estimate "now" from elapsed minutes: one update stated the wrong time and the user caught it. Put the current time at the top of every progress update, and an estimated finish time.
2. **A task's "completed" or "exit 0" is not the build result.** Read `BUILD EXIT CODE` in the log.
3. **`pgrep -f <name>` can match its own command line** (and the shell wrapper that contains the name). Use exact matching (`pgrep -x siso`) or list processes and read them before saying "still running".
4. Quote real numbers (RAM available, swap free, disk free, latest step) and say what is normal vs worrying. No guessing.
5. Keep messages short while waiting; do not poll.

## Actions, in order of preference (keep the build alive; pausing is the last resort)

**Low swap:** create another file (seconds): `sudo fallocate -l 16G /swapfileN && sudo chmod 600 /swapfileN && sudo mkswap /swapfileN && sudo swapon /swapfileN`. Remember it costs disk.
**Low disk:** 1) clear ccache (`ccache -C`; freed about 10 GB; safe, only slows future rebuilds); 2) remove temporary swap files, but only when RAM is free (not while the linker or analysis is running): `sudo swapoff FILE` (can take minutes), verify with `swapon --show`, then `sudo rm FILE`; 3) delete only things you created.
**Last resort:** `kill -STOP <pid>` pauses a runaway process without losing state; `kill -CONT <pid>` resumes. It does not free memory.

## Build finished: verify before saying "done"

- Log's last line `BUILD EXIT CODE: 0` and "build completed successfully".
- No build processes left (exact-name match).
- The output zip exists, has a `.sha256sum`, and passes `python3 -I -c "import zipfile,sys; print(zipfile.ZipFile(sys.argv[1]).testzip())" file.zip` (prints `None` when OK).
- Do not flash. Ask the user what to do next.

## Disk at the end

The last 15% (system/vendor/super images, target files, zip) wrote 20-30 GB quickly. Free space before this stage if the margin is under about 40 GB.

## Monitor pitfalls seen
- "[100% 1/1] bootstrap blueprint" is the line BEFORE analysis, not the compile stage. Detect compile start with a progress line that has many steps (exclude ` 1/1]`).
- Alert thresholds must match the situation: a fixed "disk < 12 GB" alert fired every minute once temporary swap files used the disk. Re-arm with the real floor. Monitors expire at 30 min and must be re-armed.
- Exit code 141 in an appended log is stale (SIGPIPE from an earlier Ctrl+C); count the exit-code lines before and after the run.
