# Patches to other LineageOS projects

Changes outside this device tree that the build relies on. Apply after `repo sync`:

```sh
(cd vendor/apn && git am ../../device/unihertz/jellystar/patches/vendor/apn/*.patch)   # lineage-23.2 only
(cd packages/apps/SecureElement && git am ../../../device/unihertz/jellystar/patches/packages/apps/SecureElement/*.patch)
(cd hardware/lineage/interfaces && git am ../../../device/unihertz/jellystar/patches/hardware/lineage/interfaces/*.patch)
```

| Project | Patch | Why |
|---|---|---|
| `vendor/apn` | Match Lebara APNs by SPN | Lebara Denmark shares Telenor's 238 02 with other brands; without it a Lebara SIM gets BiBoB's APN, Telenor rejects it and the phone stays on 2G without data. Worth submitting upstream. <br>**lineage-24.0: not applied.** vendor/apn no longer has DK.xml; Danish APNs come only from the upstream list, which for 238 02 has just Telenor's own entries (no BiBoB, no Lebara). Whether a Lebara SIM gets data with Telenor's `Internet` APN is untested. |
| `packages/apps/SecureElement` | Stop reading access rules when GET DATA (next) is empty | Some SIMs (a 9eSIM card) answer it with 9000 and no data, so the service loops forever; NFC waits on it while holding its lock, which hangs NFC, Settings' connected devices page and the Quick Settings tiles (issue #5). Submitted to AOSP: [Gerrit change](https://android-review.googlesource.com/q/Ia44229fd7ce190dd51f30b66456ebe0a12a5fc7a); drop this patch once it is merged. |
| `hardware/lineage/interfaces` | Lights HAL: blink RGB LEDs in phase with the timer trigger | With the timer trigger each colour of the front LED blinks on its own timer, starting in a random phase and at full brightness, so a mixed notification colour (e.g. orange) shows as a sequence of red, green and blue. The patch parks all three colours off, then starts them together at their own levels. Needs this tree's `ueventd.rc` lines for the LED's `delay_on`/`delay_off`. To be submitted to LineageOS Gerrit; drop this patch once it is merged. |
