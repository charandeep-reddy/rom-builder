# rom-builder

A Claude Code plugin with one skill, `custom-rom-builder`, for building a custom Android ROM (LineageOS) when your machine is smaller than the official recommendation.

It comes from a real first build (LineageOS 24 / Android 17, 15 GB RAM laptop). Every number is a measurement from that build and is marked UNVERIFIED where it is a guess.

## What is inside

```
skills/custom-rom-builder/
  SKILL.md                      ground rules, workflow, decision table
  references/
    low-ram-builds.md           memory/swap/disk numbers, why a restart is expensive
    source-and-blobs.md         repo sync, device tree, vendor blobs via a local manifest
    gotchas.md                  the errors that cost time and their real causes
    feature-patch-workflow.md   small patches drafted outside the tree
    reference-rom-inspection.md read-only ADB study of a working ROM
    app-integrity.md            why banking/ID apps refuse custom ROMs, honest options
    monitoring-and-ops.md       alarms, ETA maths, honest reporting, what to do on low swap/disk, verifying the result
    resume-notes-template.md    notes file template that survives context compaction
  scripts/
    check-machine.sh            read-only RAM/swap/disk/jobs assessment
    run-build.sh                run the build in your own terminal, logs the real exit code
    watch-build.sh              read-only status snapshot of a running build
```

## Install

Personal use (any project): copy or symlink the skill folder into `~/.claude/skills/`:

```
ln -s "$PWD/skills/custom-rom-builder" ~/.claude/skills/custom-rom-builder
```

As a plugin: add this repository as a plugin marketplace/source in Claude Code and install `rom-builder`.

## Use

Ask Claude Code things like "size my machine for a LineageOS build", "why does breakfast say the repository was not found", or "my build is silent for an hour, is it stuck". The scripts also work on their own:

```
bash skills/custom-rom-builder/scripts/check-machine.sh ~/android
DEVICE=<codename> JOBS=4 bash skills/custom-rom-builder/scripts/run-build.sh
bash skills/custom-rom-builder/scripts/watch-build.sh ~/android/build.log
```

## Safety

The skill tells the assistant not to flash or relock a device without an explicit yes, not to store passwords, not to read personal app data, and not to source or ship attestation keyboxes. Vendor files you copy are proprietary: personal comparison only.

## Licence

MIT. See `LICENSE`.
