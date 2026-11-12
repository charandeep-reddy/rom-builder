# Studying a working reference ROM over ADB (read-only)

Use a phone that already runs a ROM with the feature you want (Dolby, camera, audio tuning, gestures). Goal: learn which files and settings make it work, then reproduce the idea in your build.

## Privacy and safety rules

- Only system partitions and settings keys. Never pull `/data`, photos, messages, accounts or app data. Never read keybox or attestation key files.
- Property dumps: filter to build, product, boot-state, DRM and feature lines. Do not save serial numbers or IDs.
- Do not change settings or install anything on the phone for this.
- Proprietary files you copy stay local, with checksums and a README saying so.

## Useful read-only commands

```
adb shell getprop ro.build.type ; ro.build.tags ; ro.debuggable ; ro.boot.verifiedbootstate ; ro.boot.flash.locked
adb shell pm list packages -f | grep -i <keyword>
adb shell 'find /vendor /odm /system /system_ext /product \( -iname "*dolby*" -o -iname "*dvs*" \) 2>/dev/null'
adb shell cat /vendor/etc/init/<service>.rc          # how services start, user/groups
adb shell cat /vendor/etc/vintf/manifest/<hal>.xml   # HAL declarations
adb shell cat /vendor/etc/media_codecs_*.xml         # codec registrations
adb shell settings list system | cut -d= -f1 | grep -i gesture   # keys only; avoid the secure table
adb pull <path> <scratch>/<same path>                # mirror original paths to simplify later diffs
```

Large binaries (jars, APKs) can be searched offline with `unzip` plus `grep -a -o -F` for class and string names. Install `jadx` after the build is done (it uses memory).

## What Dolby Vision looked like (one device, one ROM; UNVERIFIED elsewhere)

Decoders `c2.dolby.*.so` and `libdolbyvision.so` in `/vendor/lib64`; services (`dolbycodec2`, `dvs-hal-service`, `vendor.dolby.*@...-service`) declared by `.rc` files running as `mediacodec` with groups `mediadrm drmrpc` (that is how secure playback works); HAL entries in `vintf/manifest`; codec lists `media_codecs_dolby_*.xml` that must be included by a media codec list; a panel config `dolby_vision.cfg`; the ROM only added a small settings app. All the heavy parts were OEM vendor files. A ROM needs: the binaries, init rc, vintf, codec XML and its include, SELinux policy for the services, and working Widevine L1.

## What Dolby Audio tuning looked like

A `dax-default.xml` with presets, per-profile settings for speaker/headphone, and per-hardware tunings: band EQ, a regulator (dynamic limiter), sibilance suppression, virtual bass. This tuning is why OEM sound can be smoother than a generic ROM. An open EQ/limiter based on the same idea is an alternative that avoids the licensed code.

## Root modules on the reference phone

Listing module names needs root (`su -c ls /data/adb/modules`). Read only names and versions from `module.prop`. If the reference ROM only works because of root and integrity modules, say so: the ROM itself is not the reason. See `app-integrity.md`.
