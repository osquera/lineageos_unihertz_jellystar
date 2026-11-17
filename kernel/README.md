# Kernel and kernel modules

## Kernel, DTB, DTBO (prebuilt)

| File | Source | Notes |
|---|---|---|
| `Image.lz4` | stock `boot.img` (V01.00.04) | Google's GKI build, unmodified: `6.12.69-android16-6-g86dc53cfe87f-ab15464463-4k`. LZ4 (legacy format), not gzip. |
| `dtb/jellystar.dtb` | stock `vendor_boot.img` (EEA) | Keep **exactly one** `.dtb` here: a second one gets concatenated into `vendor_boot` and the phone stops booting without any log (see `../BoardConfig.mk`). |
| `dtbo.img` | stock firmware, as is | |

## Modules

The modules are built from MediaTek's GPL source for MT6789 (`kernel_device_modules-6.12`, with
the Jelly Star changes: battery and charger stack, RT9471 charger, ST7701S panel, gpufreq/clock
fixes) and staged here by a script outside this repo. The `.ko` files are not in git
(`.gitignore`); the load lists are.

| Path | Image | Load list |
|---|---|---|
| `modules/` | `vendor_boot` (first stage) | `modules.load.ramdisk`, `modules.load.recovery` |
| `vendor_dlkm/` | `vendor_dlkm` (second stage, built by the build system) | `modules.load.vendor_dlkm` |

`odm_dlkm` and `system_dlkm` stay stock images: `system_dlkm` holds Google's GKI modules, which
are signed by the GKI build and match `Image.lz4`.

### Stock binaries still used

These have no public source, or the public source doesn't match the stock userspace:

- Agold (the ODM): `fauge` (OZ8806 fuel gauge), `agold_cam_version`, `agold_gms_board`,
  `agold_hw_compatible`, `agold_pm_info`, `board_modem_version`, `lampbelt-leds`
- Touch, fingerprint, NFC: `chsc5xxx_touch`, `sunwave_fp`, `tms_thn31`
- `leds-aw2033`, `ext_bias`, the amplifiers `snd-soc-fs19xx`, `snd-soc-fsm`
- TrustKernel TEE: `tkcore`, `tkcore_drv`; MediaTek `fpsgo` (license "Proprietary")
- `imgsensor_isp6s`: Agold's camera sensor drivers are only in stock's build (MediaTek's source
  has a reference sensor set, and Android then finds no camera)
- `camera_mem`: stock's ioctl struct is 104 bytes, every public source has 88; the stock camera
  HAL needs stock's (otherwise the preview stays black)

Load order comes from `modules.dep`, which the build generates from the symbols; source-built
modules that use symbols from stock ones (e.g. the charger framework and `fauge`) are checked
against the stock symbol CRCs when they are staged.
