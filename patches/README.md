# Patches to other LineageOS projects

Changes outside this device tree that the build relies on. Apply after `repo sync`:

```sh
(cd vendor/apn && git am ../../device/unihertz/jellystar/patches/vendor/apn/*.patch)
(cd packages/apps/SecureElement && git am ../../../device/unihertz/jellystar/patches/packages/apps/SecureElement/*.patch)
```

| Project | Patch | Why |
|---|---|---|
| `vendor/apn` | Match Lebara APNs by SPN | Lebara Denmark shares Telenor's 238 02 with other brands; without it a Lebara SIM gets BiBoB's APN, Telenor rejects it and the phone stays on 2G without data. Worth submitting upstream. |
| `packages/apps/SecureElement` | Stop reading access rules when GET DATA (next) is empty | Some SIMs (a 9eSIM card) answer it with 9000 and no data, so the service loops forever; NFC waits on it while holding its lock, which hangs NFC, Settings' connected devices page and the Quick Settings tiles (issue #5). Submitted to AOSP: [Gerrit change](https://android-review.googlesource.com/q/Ia44229fd7ce190dd51f30b66456ebe0a12a5fc7a); drop this patch once it is merged. |
