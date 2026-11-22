# Kernel and kernel modules

## Kernel (prebuilt), DTB, DTBO

| File | Source | Notes |
|---|---|---|
| `Image.lz4` | stock `boot.img` (V01.00.04) | Google's GKI build, unmodified: `6.12.69-android16-6-g86dc53cfe87f-ab15464463-4k`. LZ4 (legacy format), not gzip. |
| `dtb/jellystar.dtb` | built from source: `mt6789.dtb` from the module tree's `out/mgk_64_k612/dist`, in a DT table (`mkdtboimg.py create --page_size=2048`, one entry, as stock); then cut the file to the table's `total_size` (header bytes 4-7): `mkdtboimg.py` pads it to the page size, and LK's overlay step (`ufdt_apply_overlay(): Bad fdt size!`) rejects a DTB whose file size isn't exactly the table size, so the phone boot-loops | Keep **exactly one** `.dtb` here: a second one gets concatenated into `vendor_boot` and the phone stops booting without any log (see `../BoardConfig.mk`). |
| `dtbo.img` | built from source: `dtbo.img` from `out/mgk_64_k612/dist` (board overlay `arch/arm64/boot/dts/mediatek/mt6789-jellystar-overlay.dtso`) | Padded to the partition size by the build (`BOARD_DTBOIMG_PARTITION_SIZE`). |

## Modules

The modules are built from MediaTek's GPL source for MT6789, `kernel_device_modules-6.12` with
the Jelly Star changes (battery and charger stack, RT9471 charger, ST7701S panel, gpufreq/clock
fixes): <https://github.com/osquera/android_kernel_unihertz_jellystar-modules>, branch
`jellystar`. The `.ko` files are not in git (`.gitignore`); the load lists are.

### Building

```sh
kernel/tools/setup-workspace.sh ~/jellystar-kernel        # once; needs repo, git, ~60 GB
JOBS=6 kernel/tools/build-modules.sh ~/jellystar-kernel/ws
kernel/tools/stage-modules.py ~/jellystar-kernel/ws \
    --stock-vendor-boot <dir> --stock-vendor-dlkm <dir> --gki-symvers <file>
```

`setup-workspace.sh` uses public sources only: Google's common kernel pinned to the GKI build
the phone runs (`tools/ack-manifest.xml`), OnePlus' MT6993 GPL release for MediaTek's Kleaf rules
and `vendor/mediatek/kernel_modules` (with `tools/oneplus-vendor.patch`, which drops OnePlus-only
dependencies), and the module tree above. `stage-modules.py` needs the stock modules (from
stock `vendor_boot` and `vendor_dlkm`, V01.00.04) and the GKI build's `Module.symvers`; its
docstring says what each input is.

| Path | Image | Load list |
|---|---|---|
| `modules/` | `vendor_boot` (first stage) | `modules.load.ramdisk`, `modules.load.recovery` |
| `vendor_dlkm/` | `vendor_dlkm` (second stage, built by the build system) | `modules.load.vendor_dlkm` |

`odm_dlkm` and `system_dlkm` stay stock images: `system_dlkm` holds Google's GKI modules, which
are signed by the GKI build and match `Image.lz4`.

### Stock modules

None are shipped any more: every module in `modules/` and `vendor_dlkm/` is built from source.
`stage-modules.py` still reads the stock modules and their load lists, because they define which
modules the phone loads at which stage and in which order, and because the CRC check below
compares against them. The amplifier driver `snd-soc-fsm` (FS16xx) is built but untested: the
test phone has the FS19xx amplifier.

Load order comes from `modules.dep`, which the build generates from the symbols. When staging,
`stage-modules.py` checks, like depmod, that every symbol a module imports is provided at its
load stage with a matching CRC (GKI exports from the GKI build's `Module.symvers`).
