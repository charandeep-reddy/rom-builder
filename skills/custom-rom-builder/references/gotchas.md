# Gotchas (each one cost real time)

1. **`grep` is a wrapper (ugrep) in some AI-tool shells.** LineageOS `lunch` runs `echo $1 | grep "-"`. With ugrep that prints "no search PATTERN specified", the product string is never split, and roomservice searches GitHub for `device-release-userdebug`, which does not exist ("Repository for ... not found"). Fix: `unset -f grep` (or use a normal terminal). The error message points at the wrong thing.
2. **`mka` is a shell function, not a program.** `nice ... mka bacon` or `systemd-inhibit ... mka bacon` fails with "Failed to execute". Call `m bacon` instead (a real executable after `envsetup`).
3. **Task "completed, exit code 0" is not the build result.** If a pipeline or wrapper ends with `echo`, the status is the echo's. Always read the log's final line (`BUILD EXIT CODE: n` written by your script).
4. **Pasting a long command with quotes into a terminal can split it across lines.** `systemd-inhibit` then ran with no command and listed inhibitors, and the second line ran as its own command. Put the commands in a script file and run `bash script.sh`.
5. **A silent log is normal during Soong analysis.** Check `soong_build` CPU and swap I/O (`vmstat 1`) instead of assuming a hang.
6. **`E1112 ... memory stall` lines from siso are warnings**, not failures.
7. **`ninja: ignore missing out error in depfile`** is harmless.
8. **"Build sandboxing disabled due to nsjail error"** is harmless on Ubuntu 24.04 (user namespace restrictions).
9. **`repo` launcher "not writable" warning** is harmless with the apt package.
10. **Restarting repeats the analysis stage.** Do not restart just to change `-j`.
11. **Swap file permissions:** use mode 600, root-owned.
12. **Do not edit source files while the build runs.** It can corrupt or restart the build. Draft patches elsewhere.
13. **Add API surface carefully.** Check whether the SDK has API text files that must be updated before adding a public constant (in lineage-sdk for lineage-24 none listed the existing similar key; verify on your branch).

## Do not interrupt a running Soong analysis to try a cleverer approach
Symptom: after a source change, `m <module>` goes silent for an hour at 12 GB RSS with heavy swapping and "Globs changed, rerunning soong" in the log.
Mistake made once: stopping it after ~9 minutes, rearranging the change (moving a new Java file into an existing file) on an unverified theory that this would let Soong skip analysis. The restart re-ran the whole analysis anyway (log named a different glob, an output `dtbo.img` path), so the stop only cost time. Killing soong_build mid-analysis may also leave its saved state incomplete.
Rule: let a running analysis finish unless the process is dead or swap is exhausted. Before any stop/restart, say it is a guess, what it costs if wrong, and the time already sunk. Do not promise "quick module build" when a Soong input may have changed.
Also: `[100% 1/1] bootstrap blueprint` is the line before analysis, not the compile stage. A monitor that treats it as "compile started" gives a false alarm; match progress lines with many steps instead.

## Flashing lessons (A/B device with a separate recovery partition)
- The device had a separate `recovery` partition holding another recovery (Fox). Flashing `boot`, `dtbo` and `vendor_boot` did NOT replace it: `fastboot reboot recovery` booted the old recovery. Also flash the build's `recovery.img` to the `recovery` partition, then boot into it and check which recovery it is.
- In the ROM's recovery: format data first, then `adb sideload` the ROM zip (it reached 47% and printed "Total xfer: 1.00x" when finished), accept "reboot to recovery for additional packages", then sideload GApps before the first boot.
- `adb disable-verity` + reboot makes /system writable through overlayfs (user approval needed: it changes boot flags).
- A firmware-only zip ("fw_*.zip", writes both slots including xbl/abl/tz, no anti-rollback check) can be a downgrade. Before flashing, compare it read-only with the phone's partitions (`head -c <size> /dev/block/bootdevice/by-name/<part>_a | sha256sum`) and read the version strings in the images. A modem tag like "GLB" appeared in both the global and India packages, so it is not a region marker.
