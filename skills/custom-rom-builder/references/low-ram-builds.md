# Building on low RAM (measured, not guaranteed)

Reference setup: Ryzen 7 (8c/16t), 15 GB RAM, NVMe, Ubuntu 24.04, LineageOS 24.0 (Android 17), source about 191 GB.
The official wiki asks for 64 GB RAM and 400 GB disk for lineage-21 and later.

## What actually happened

| Stage | Observation |
|---|---|
| Soong analysis (`soong_build`) | About 12 GB RSS plus up to about 40-55 GB of swap at peak (RAM+swap used reached roughly 68 GB). 60 to 85 minutes of silence in the log. Heavy swap thrash, "memory stall" warnings |
| `ckati` (Make to Ninja) | A few minutes, about 3 GB RAM |
| Compile (`siso` + clang) | `-j4`: about 230-440 steps/min; RAM about 9 GB used, swap about 20 GB used, plenty free |
| Whole first build | 12+ hours on this machine |

Peak is the analysis stage. After it, memory pressure drops sharply (swap fell from 54 GB to under 1 GB when it ended).

## Final result of the reference build

- Success after one 49% stop and one reaped restart; the final run was in the user's own terminal. Exit code 0.
- Flashable zip 1.8 GB; `out/` ended at 149 GB; source 191 GB. Total about 340 GB plus swap files and ccache on a 468 GB disk.
- The last 15% (system/vendor/super images, target files, zip) wrote about 20-30 GB quickly: disk fell about 19 GB in 30 minutes. Keep 40+ GB free for the end, and free space BEFORE it gets tight (clear ccache; remove temporary swap files once the linker steps are done and RAM is available).
- Removing a swap file holding about 10 GB took roughly 3-4 minutes; do it only when RAM is free.

## Rules of thumb

- Plan RAM + swap of at least about 80 GB for lineage-24 analysis. With 15 GB RAM that meant two 32 GB swap files. 32 GB of swap alone nearly ran out.
- Swap files can be temporary: create them for the analysis stage, remove them afterwards to give the disk back. Removing swap while memory is still tight can cause OOM, so wait until the compile is stable.
- Create a swap file: `sudo fallocate -l 32G /swapfileN && sudo chmod 600 /swapfileN && sudo mkswap /swapfileN && sudo swapon /swapfileN`. Takes seconds. Not in fstab means it disappears on reboot.
- `-j` does not affect the analysis stage. It only affects the compile.
- **A restart repeats the analysis stage** (about 85 min here) even though finished compile steps are kept. So pick `-j` before the first run. Restarting only to change `-j` was break-even at best.
- CPU was not the bottleneck: power profile "performance", cores near max clock, only 4 of 16 threads busy with `-j4`. More jobs need more RAM.
- Disk: source 191 GB, `out/` grew about 5 GB per 30 minutes during compile in the observed stretch. Keep ccache small (20 GB was enough).
- Suggestion for next time (UNVERIFIED): `-j8` after confirming free RAM and swap during the compile stage.

## Time estimates

Compute from two progress samples taken 30 minutes apart: steps_done_delta / minutes, then remaining_steps / that rate. Rates varied 225-630 steps/min as step types changed, so quote a range and refine it each sample.

## AI-tool caveat

Some AI coding tools stop background jobs when the machine is critically low on memory and the session is idle. The analysis stage triggers this. Run the build in your own terminal (tmux is safest), and let the AI tool watch the log read-only.

## zRAM and temporary swap (added after a 2 h 30 min Soong analysis on 15 GB RAM)
- Measured: the analysis stage held about 12 GB RSS and filled 54-68 GB of NVMe swap, with 70%+ I/O wait. It ran past 2 h 13 min without finishing, and the build was then stopped by the user.
- Reports from other builders (anecdotal, unverified for this machine) say zRAM (compressed swap in RAM) can cut this stage a lot. Set it up BEFORE the build, at higher priority than disk swap:
  `echo lz4 > /sys/block/zram0/comp_algorithm; echo 10G > /sys/block/zram0/disksize; mkswap /dev/zram0; swapon -p 100 /dev/zram0; sysctl vm.swappiness=60` (`zramctl --find` failed with "busy" once; the sysfs route worked). Not persistent.
- Temporary swap files cost disk: each 16 GB file took 16 GB of a 52 GB disk. Do not let free disk fall under ~6 GB, since the compile still needs space. Remove the files (`swapoff` then `rm`) only after the build exits and used swap is small.
- Do not interrupt a running analysis (see gotchas.md). `systemd-oomd` may be active on Ubuntu and can kill a build under memory pressure; ask before disabling it.
