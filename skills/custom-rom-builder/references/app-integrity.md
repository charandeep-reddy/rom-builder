# Apps that refuse custom ROMs (banking, government ID)

## Method that worked for diagnosing

1. Ask what error text the user sees, and whether the app works on a known reference setup.
2. Read-only on the reference phone: `ro.build.type`, `ro.build.tags`, `ro.debuggable`, `ro.boot.verifiedbootstate`, `ro.boot.flash.locked`, installed root manager and modules (names only).
3. Copy only the app package (APK and its split APKs) to a scratch folder. Search the dex for library names and property strings with `grep -a -o -F`. Python with `-I` for context around a string.
4. Do not touch the app's user data, documents or identifiers.

## What one government ID app contained (Talsec/freeRASP, RootBeer, Play Integrity, native checker)

- Talsec freeRASP (many string hits), RootBeer string tables (`test-keys`, `ro.debuggable`, `userdebug`, magisk and `su` paths, emulator props), Google Play Integrity API (standard requests), key attestation certificate chain use, and a native library named like `libtoolChecker.so` (checks in native code, which Java-level hiding does not reach).
- Strings in the dex show what the app CAN check, not what makes it block. Reading the decision code needs a decompiler (jadx).
- A match on the word "lineage" was only APK signature key-rotation classes, not a LineageOS check. Always read context before concluding.

## What explained the difference between two ROMs

On the reference phone the app worked because of root modules: KernelSU, Zygisk Next, an integrity module spoofing a Pixel identity, Tricky Store (attestation spoofing), and a hide-apps module. Props like `verifiedbootstate=green` and `flash.locked=1` were reported by those modules, not by a really re-locked bootloader.
A plain official LineageOS build (release-keys, `userdebug`) failed in the same app. Signing with release keys alone is therefore not the fix.

## What to tell the user (honest options)

- Custom ROMs cannot pass Google's strongest Play Integrity verdict by design; LineageOS states it does not circumvent integrity checks.
- Built-in Pixel-props spoofing exists in some ROMs (a framework class that changes properties for Google services). It may help basic/device verdicts, not the strong one, and it goes against the minimal and upstream-friendly goal.
- Strong attestation spoofing generally needs a keybox, a leaked credential that gets revoked. Do not source, copy or ship one.
- Users who want the app can install their own root + modules (not part of the ROM) or use the service's web version.
- Cheap tests first: which Play Integrity level the app needs (checker app), whether a `user` build type changes anything (UNVERIFIED for that app), then decompile to read the decision code.

## Generic "Something went wrong / Retry" in a payment app
Seen once with a UPI app: the app showed a generic error, sent no SMS and logged no reason. Phone/SMS/IMS were healthy and permissions were granted. The fix was adding the app to the integrity-spoof module's per-app target list (the user did this through the module's own UI), not changing firmware. Check the per-app list before suspecting firmware, and before swapping modules. A firmware zip can be a downgrade of low-level partitions (abl/xbl/tz) with no anti-rollback check; compare version strings read-only first.
