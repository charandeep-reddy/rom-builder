---
name: custom-rom-builder
description: Use when planning, building or debugging a custom Android ROM (LineageOS or similar) especially on limited hardware (low RAM, small disk): machine sizing (RAM/swap/disk), repo sync, device trees and vendor blobs, running and monitoring multi-hour builds, adding small features as patches, studying a reference ROM over ADB, and app-integrity problems (banking/government apps refusing custom ROMs). Triggers on "build LineageOS", "custom ROM", "repo sync", "breakfast", "m bacon", "soong_build slow", "android build out of memory", "vendor blobs", "TheMuppets", "ROM patch", "three finger screenshot", "DigiLocker not working".
---

# Custom ROM Builder

A practical, evidence-based workflow for building a custom Android ROM, written from a real first build of LineageOS 24 (Android 17) for a Snapdragon 8+ Gen 1 phone on a 15 GB RAM laptop. Numbers below are measurements from that build, not promises: your hardware and branch will differ. Anything unverified is marked UNVERIFIED.

## Ground rules (read first)

1. The device and data belong to the user. Never flash, unlock, relock, wipe or change boot settings without an explicit yes at that moment.
2. Never store, echo into files, or reuse passwords given in chat beyond the stated purpose. Tell the user to change a password once it has appeared in a transcript.
3. Never source, copy or ship attestation keyboxes or other leaked credentials. Do not build integrity spoofing that depends on them. See `references/app-integrity.md`.
4. Proprietary vendor files (Dolby, camera, Qualcomm, OEM) are for personal comparison only. Do not redistribute them.
5. Do not edit the source tree while a build is running. Draft patches outside the tree.
6. Report real exit codes. A background task "completed" status is not a build result: always read the log for the final line.
7. Read the clock (`date`) before quoting any time, and put the current time and an estimated finish time in every progress update. Never estimate "now" from elapsed minutes.
8. Never stop a running Soong analysis to try a cleverer approach; restarts can repeat the whole analysis. Label any such idea as a guess and state the cost if it is wrong (see `references/gotchas.md`).
9. Pausing a build is a last resort. Prefer adding swap, freeing disk (clear ccache, remove temporary swap files when RAM is free).

## Workflow

1. **Size the machine** with `scripts/check-machine.sh`. Read `references/low-ram-builds.md`. The Soong analysis stage is the memory cliff, not the compile.
2. **Prepare** packages, swap, udev rules, git identity, ccache. See `references/source-and-blobs.md`.
3. **Sync** with `repo sync -c -j4 --no-tags --no-clone-bundle`. Check the real result in a log file, never through a `| tail` pipe.
4. **Device setup**: `breakfast <device>`. If it fails, read `references/gotchas.md` before changing anything.
5. **Vendor blobs** from the maintainers' or TheMuppets repos via a local manifest of your own.
6. **Build** in the user's own terminal with `scripts/run-build.sh` (not as a background task of an AI tool, which may be reaped under memory pressure). Choose the job count before the first run: a restart repeats the analysis stage.
7. **Monitor** read-only with `scripts/watch-build.sh`. Act only on real signals (low swap, low disk, process gone, exit code). See `references/monitoring-and-ops.md` for alarms, ETA maths, and what to do on each. Verify the finished zip (exit code, no processes left, zip integrity, checksum) before saying "done". Do not flash.
8. **Develop features** as small separate patches. See `references/feature-patch-workflow.md`.
9. **Study a reference ROM** (one that already works on the device) over ADB, read-only. See `references/reference-rom-inspection.md`.
10. **Keep notes** in a resume file (state, commands, decisions, pending items) so a compacted or new session can continue. Template: `references/resume-notes-template.md`. Update it before the user compacts the session.

## Quick decision table

| Situation | Do |
|---|---|
| RAM well under 64 GB | Add swap so RAM+swap is at least about 80 GB for the analysis stage; use a low `-j`; run in own terminal |
| `breakfast` says "Repository for X-<release>-userdebug not found" | The shell's `grep` is probably a wrapper (ugrep). Run `unset -f grep` or use a normal terminal |
| `breakfast` says `vendor/<oem>/<device>/...-vendor.mk does not exist` | Vendor blobs missing. Add them with a local manifest |
| `fetch ... HTTP 429` during sync | Google rate limit. Rerun `repo sync` with fewer jobs (`-j4`) |
| Build log shows no progress for an hour | Normal during Soong analysis if `soong_build` uses CPU and swap I/O |
| App refuses the ROM | Read `references/app-integrity.md`; do not promise a fix |
