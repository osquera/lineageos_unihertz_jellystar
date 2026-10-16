# Patches to other LineageOS projects

Changes outside this device tree that the build relies on. Apply after `repo sync`:

```sh
cd vendor/apn && git am ../../device/unihertz/jellystar/patches/vendor/apn/*.patch
```

| Project | Patch | Why |
|---|---|---|
| `vendor/apn` | Match Lebara APNs by SPN | Lebara Denmark shares Telenor's 238 02 with other brands; without it a Lebara SIM gets BiBoB's APN, Telenor rejects it and the phone stays on 2G without data. Worth submitting upstream. |
