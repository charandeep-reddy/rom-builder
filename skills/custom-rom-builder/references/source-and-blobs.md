# Source, device tree and vendor blobs

## Packages (Ubuntu)

`git git-lfs adb fastboot repo ccache build-essential python3 bc bison flex zip unzip curl lm-sensors`
plus `android-sdk-platform-tools-common` for udev rules (then `sudo udevadm control --reload-rules && sudo udevadm trigger`, user in `plugdev`).
`repo` from apt is old but works; its own newer copy is fetched into `.repo`.
Install `git-lfs` before `repo init --git-lfs` or LFS files arrive as small placeholder text files.

## Init and sync

```
mkdir -p ~/android/lineage && cd ~/android/lineage
repo init -u https://github.com/LineageOS/android.git -b lineage-24.0 --git-lfs --no-clone-bundle
repo sync -c -j4 --no-tags --no-clone-bundle > ~/android/sync.log 2>&1; echo "repo exit code: $?" >> ~/android/sync.log
```

- Find the right branch for a device on the LineageOS wiki device page, or in `lineage-build-targets` of the `LineageOS/hudson` repo.
- `-c` fetches only the needed branch. `-j8` triggered Google `HTTP 429` / `RESOURCE_EXHAUSTED` errors on AOSP tags; rerunning with `-j4` finished cleanly. Rerunning resumes.
- Never pipe `repo sync` into `tail`: the exit status you see is `tail`'s, and output only appears at the end.
- Size: about 190 GB for lineage-24 with `-c`.
- UNVERIFIED for this branch: `--partial-clone --clone-filter=blob:limit=10M` keeps history but saves space; `--depth=1` saves the most but breaks `git log`, rebases and `repopick`.

## Device tree

`source build/envsetup.sh && breakfast <device>` fetches `device/<oem>/<device>`, the common tree, kernel and hardware repos (roomservice). It writes `.repo/local_manifests/roomservice.xml`. That file is generated: do not hand-edit it.

## Vendor blobs

Lineage device trees do not ship proprietary files. `breakfast` then stops with `vendor/<oem>/<device>/<device>-vendor.mk does not exist`.

Check which repos exist (read-only):
```
curl -s https://api.github.com/repos/TheMuppets/proprietary_vendor_<oem>_<device>/branches | grep '"name"'
```
Add them in your own file `.repo/local_manifests/muppets.xml`:
```xml
<manifest>
  <remote name="muppets" fetch="https://github.com/TheMuppets" />
  <project name="proprietary_vendor_<oem>_<device>" path="vendor/<oem>/<device>" remote="muppets" revision="lineage-24.0" />
  <project name="proprietary_vendor_<oem>_<soc>-common" path="vendor/<oem>/<soc>-common" remote="muppets" revision="lineage-24.0" />
</manifest>
```
Then `repo sync -c --no-tags --no-clone-bundle vendor/<oem>/<device> vendor/<oem>/<soc>-common` (a few GB). Look at `lineage.dependencies` of the device and common trees to see what is needed.
Alternative: `extract-files` from the user's own phone or a stock ROM zip.
Trust note: blobs are third-party binaries run with high privilege. Official LineageOS builds use the same source; say so to the user.

## Maintainers

Device maintainers often publish working branches in their own GitHub organisation (the Telegram or wiki "Sources" link). Read-only look at branches and commit messages shows active work (audio, camera, sepolicy). Do not mix those into the tree without asking.

## ccache

`USE_CCACHE=1`, `CCACHE_EXEC=$(command -v ccache)`, `ccache -M 20G`. It helps rebuilds and variants, not the first build. Only C/C++ is cached.
