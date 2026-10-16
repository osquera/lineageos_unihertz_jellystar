# Prebuilt kernel — no vendor kernel source exists for this device

Unihertz does not release kernel source for any of their devices (documented pattern, not
specific to Jelly Star — see the project memory / handoff brief for the research behind
this). This directory holds the stock kernel/dtb/dtbo **extracted directly from Jelly
Star's own stock firmware**, used as prebuilt binaries rather than built from source —
the same approach `iasnezhkov/android_device_ikko_mindone` uses for the same reason on the
same MT6789/Helio G99 platform (that project went further and hand-forward-ported a kernel
from Google's ACK; we have not attempted that here).

## What's here and where it came from

| File | Source | Notes |
|---|---|---|
| `Image.lz4` | `boot.img` (`~/Downloads/boot.img`, stock V01.00.04, unpacked with `unpack_bootimg`) | **LZ4-compressed**, not gzip — confirmed via `file`. Unmodified bytes, known-good: this is literally the kernel that boots the device today. |
| `dtb/jellystar.dtb` | `vendor_boot.img` (EEA firmware, `2026082709_g58v89c2k_dfl_eea/images/vendor_boot.img`) | Exactly one `.dtb` file — **must stay that way**. See the warning in `../BoardConfig.mk`: a second stray `.dtb` here gets silently concatenated into `vendor_boot`, and the device just stops booting with no adb and no crash log (a preloader window every ~33s is the only symptom) — this is a real failure mode iKKO's project hit and documented, not a hypothetical. |
| `dtbo.img` | Same EEA firmware folder, copied as-is | Standard Android DTBO image (magic `0xD00DFEED`/`0xd7b7ab1e` — confirmed). |

Kernel command line and vendor_boot header fields (`bootopt=64S3,32N2,64N2`, kernel load
`0x40000000`, ramdisk load `0x66f00000`, dtb/tags load `0x47c80000`) were cross-checked
against iKKO's own `BoardConfig.mk` for the same SoC and matched exactly — see the header
comment there.

## Kernel modules — DONE (2026-09-29)

`modules/` holds all 176 `.ko` files plus `modules.dep`/`modules.alias`/`modules.softdep`,
extracted from `vendor_ramdisk00` inside `vendor_boot.img`. `modules.load` (169 entries,
verified every one has a matching `.ko`), `modules.load.recovery` (166 entries), and
`modules.load.ramdisk` (a copy of `modules.load` — the extracted ramdisk only shipped one
"load" list, not a separate ramdisk-specific one, so the same list is used for both
`BoardConfig.mk` variables) all live one level up in `kernel/`.

**How it was extracted, since no `lz4` tool was installed and there's no passwordless
sudo:** `vendor_ramdisk00` uses Android's **legacy** LZ4 frame format (magic `0x184C2102`,
not the modern LZ4 frame format `lz4.frame` in Python expects) — a sequence of 4-byte
length-prefixed raw LZ4 blocks, each decompressing to at most 8 MiB. Decompressed with `uv
run --with lz4 python3` and `lz4.block.decompress(block, uncompressed_size=8*1024*1024)`
per block (no system package needed), producing a `newc`-format CPIO archive, then `cpio
-idm` to unpack it. `lib/modules/` inside that ramdisk had everything needed.
The archive also contains several *other* device panels' drivers (`panel-nt37801-*`,
`panel-samsung-s68fc01-*`, `panel-tianma-*`, `panel-truly-*`, etc.) — this vendor_boot ram
disk is evidently shared across a family of MT6789 Unihertz-adjacent devices; only one
panel driver is actually relevant to Jelly Star specifically, not yet identified which.

## Reference: how iKKO handles the equivalent step

Their `README.md` build steps 4 does this:
```sh
mkdir -p device/ikko/mindone/kernel/dtb device/ikko/mindone/kernel/modules
rm -f device/ikko/mindone/kernel/dtb/*.dtb
cp <kernel-out>/Image.gz                                 device/ikko/mindone/kernel/
cp <kernel-out>/arch/arm64/boot/dts/mediatek/mindone.dtb  device/ikko/mindone/kernel/dtb/
cp <k6set>/*.ko                                           device/ikko/mindone/kernel/modules/
```
Theirs comes from actually building a kernel (their hand-forward-ported ACK). Ours instead
needs to come from extracting `vendor_ramdisk00`'s `.ko` files directly out of the stock
`vendor_boot.img`, since we have no kernel source to build from at all.
