# Adding a small feature as a clean patch

Principle: minimal, separate, removable. One feature = one patch per repository (frameworks/base, lineage-sdk, Settings...). No new apps or services unless needed.

## Method

1. **Find a precedent in the tree.** Example: the existing "edge long swipe" action shows the pattern: a key in `LineageSettings.System` (+ validator + `VALIDATORS.put`), an `Action` read in `PhoneWindowManager` via `Action.fromSettings`, a ContentObserver registration, and `performKeyAction(action, event)`.
2. **Read how other ROMs did it** from their public source (single files via raw URLs or the GitHub tree API; no need to clone frameworks/base). Prefer the version written against Lineage APIs. Note licences (Apache 2.0 needs attribution); writing your own version of simple logic is fine.
3. **Draft outside the tree**: copy the target files to a scratch directory, `git init` + commit, edit with scripted exact-match replacements (assert each anchor appears once), then `git diff` to produce patches. New files: `git add -N`.
4. **Dry-run against the real tree** (changes nothing): `git -C <repo> apply --check patch`.
5. **Apply and build only after any running build finishes**, one patch at a time. Rebuild just the affected modules; on a `userdebug` build `adb root && adb remount` and push the changed jar to test without reflashing (UNVERIFIED for every setup).
6. **Test with the feature off first**: behaviour must equal the baseline. Then on. Check `logcat` for exceptions.
7. **Keep it removable**: separate commits, separate local manifest entries for forks.

## Example: three-finger swipe (design, UNTESTED)

- New class `ThreeFingersSwipeListener implements WindowManagerPolicyConstants.PointerEventListener`: exactly 3 fingers within 500 ms, none in the bottom 50 dp, vertical start spread under 150 dp, fire when summed downward travel passes 3 x 50 dp.
- `PhoneWindowManager`: register the listener with `mWindowManagerFuncs.registerPointerEventListener(l, DEFAULT_DISPLAY)` only while the chosen action is not `NOTHING`; unregister otherwise (zero cost when off). Post the action to the policy handler. Build a synthetic `KeyEvent` and call `performKeyAction`.
- `lineage-sdk`: new key `key_three_fingers_swipe_action` reusing the hardware-key action validator (range must cover the screenshot actions).
- Optional later: a Settings screen; touch-cancel plumbing so the app under the fingers ignores the swipe (needs an activity-manager method: bigger change).
- Risk: it runs inside `system_server`, so a crash there soft-reboots the phone. Keep off by default and test carefully.

## Commit hygiene

Small commit messages with the subsystem prefix; attribution lines as the project requires. Do not push or publish without the user's approval.

## Testing framework changes without a full flash
- Build only the touched modules (`m services org.lineageos.platform LineageParts <overlay>`), then either `adb remount` + push (after disable-verity) or package the built files as a systemless KernelSU module (system/framework/*.jar, system/system_ext/priv-app/<App>/<App>.apk, system/vendor/overlay/<Overlay>.apk). Disabling the module restores the originals. Bootloop recovery: remove the module directory from recovery, or reflash the original boot image.
- This does NOT skip Soong analysis: new/removed source files, build-file edits or changed output globs make it rerun. Batch all changes into one build.
- A setting key that only exists in the patched SDK jar is rejected by the settings provider ("Invalid setting") until that jar is on the device, so it cannot be enabled with adb earlier.
- Add `Slog.d` diagnostics to new gestures: another ROM's users reported a gesture that silently did nothing.
