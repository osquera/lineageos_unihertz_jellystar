#!/usr/bin/env python3
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
"""Stage the kernel modules for the device tree from the source build, with stock fallbacks.

Writes into the device tree (all gitignored except the load lists):
  kernel/modules/                 first-stage modules (vendor_boot)
  kernel/vendor_dlkm/             second-stage modules (vendor_dlkm image)
  kernel/modules.load.ramdisk, kernel/modules.load.recovery, kernel/modules.load.vendor_dlkm
For each module in the stock lists the source-built .ko is used when it exists, else the stock
one. Then checks, like depmod, that every imported symbol is provided at its load stage with a
matching CRC. Prints a report; --dry-run writes nothing.

Inputs, all from stock firmware V01.00.04 or the GKI build the phone runs:
  --stock-vendor-boot DIR   the modules of stock vendor_boot's ramdisk: DIR/modules/*.ko,
                            DIR/modules.load.ramdisk, DIR/modules.load.recovery
  --stock-vendor-dlkm DIR   stock vendor_dlkm's lib/modules (*.ko and modules.load)
  --gki-symvers FILE        kernel_aarch64_Module.symvers of GKI build 15464463
                            (ci.android.com, target kernel_aarch64)

Usage: kernel/tools/stage-modules.py <ws> --stock-vendor-boot DIR --stock-vendor-dlkm DIR
           --gki-symvers FILE [--dry-run]
"""
import argparse, glob, os, shutil, subprocess, sys, tempfile

ap = argparse.ArgumentParser()
ap.add_argument("ws", help="workspace from setup-workspace.sh, after build-modules.sh")
ap.add_argument("--stock-vendor-boot", required=True)
ap.add_argument("--stock-vendor-dlkm", required=True)
ap.add_argument("--gki-symvers", required=True)
ap.add_argument("--dry-run", action="store_true")
opts = ap.parse_args()

DEV = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))   # the device tree's kernel/
WS = os.path.realpath(opts.ws)
STOCK_RD = opts.stock_vendor_boot
STOCK_DLKM = opts.stock_vendor_dlkm
GKI_SYMVERS = opts.gki_symvers
CLANG = f"{WS}/prebuilts/clang/host/linux-x86/clang-r536225/bin"
STRIP, OBJCOPY = f"{CLANG}/llvm-strip", f"{CLANG}/llvm-objcopy"
BUILT = glob.glob(f"{WS}/out/bazel/output_user_root/output_base/execroot/_main/bazel-out/"
                  "k8-fastbuild/bin/kernel_device_modules-6.12/mgk_64_k612_customer_modules_install.user/"
                  "staging/lib/modules/*")[0]

# Left out: MET profiler, debug/placeholder modules, the stock panel driver, and two Agold info
# modules nothing uses (agold_cam_version: /proc/agold_lcmcam_info; board_modem_version: board
# revision sysfs; no module imports from them and no vendor blob reads their files), and
# ext_bias (LCD bias chip): nothing calls its exports, not even the stock panel driver, and its
# probe does no I2C traffic, so it never touches the chip. agold_pm_info (/proc/driver/agold_*
# hardware info): only the stock touch driver imported from it, and only Agold's stock apps read
# its files (agolddaemon reads agold_battery_info on stock, but our policy doesn't allow it).
# fpsgo: MediaTek's proprietary plug-in for mtk_fpsgo_v3 (built from source), which adds frame
# pacing algorithms through hooks that mtk_fpsgo_v3 only calls when they are set.
# agold_hw_compatible (camera/LCM name registry) and agold_gms_board (/proc/driver/
# agold_gms_board_info, a copy of androidboot.agold_gms_board_info): only stock modules we no
# longer ship imported from them (imgsensor, hf_manager, sensorhub, agold_cam_version,
# agold_pm_info), and only Agold's stock system image reads the /proc file.
DROP = {"met", "met_backlight_api", "met_emi_api", "met_gpu_adv_api", "met_gpu_api", "met_ipi_api",
        "met_mcupm_api", "met_scmi_api", "met_sspm_api", "met_vcore_api", "mt63xx_oc_debug",
        "mtk_mmdvfs_debug_v3", "mtk_vcodec_sys_api", "pkvm_p1_dummy",
        "agold_cam_version", "board_modem_version", "ext_bias", "agold_pm_info",
        "fpsgo", "agold_hw_compatible", "agold_gms_board"}
REPLACE = {"panel_ST7701S_Z30043": "panel-unihertz-jellystar-st7701s"}
# Built from source, but the phone needs stock's binary.
KEEP_STOCK = set()


def norm(n):
    return n.replace("-", "_")


def read_list(p):
    return [l.strip() for l in open(p) if l.strip()]


def transform(names):
    out = []
    for ko in names:
        n = ko[:-3]
        if norm(n) in DROP:
            continue
        n = REPLACE.get(norm(n), n)
        out.append(n + ".ko")
    return out


built = {norm(os.path.basename(f)[:-3]): f for f in glob.glob(f"{BUILT}/**/*.ko", recursive=True)}
stock = {}
for d in (f"{STOCK_RD}/modules", STOCK_DLKM):
    for f in glob.glob(f"{d}/*.ko"):
        stock.setdefault(norm(os.path.basename(f)[:-3]), f)


def source(ko):
    n = norm(ko[:-3])
    if n in built and n not in KEEP_STOCK:
        return built[n], "built"
    if n in stock:
        return stock[n], "stock"
    raise SystemExit(f"no .ko for {ko}")


def depends(path):
    out = subprocess.run(["modinfo", "-F", "depends", path], capture_output=True, text=True).stdout.strip()
    return [d for d in out.split(",") if d]


ramdisk = transform(read_list(f"{STOCK_RD}/modules.load.ramdisk"))
recovery = transform(read_list(f"{STOCK_RD}/modules.load.recovery"))
dlkm = transform(read_list(f"{STOCK_DLKM}/modules.load"))
# Modules that are files in the stock ramdisk but not in any list (dependencies) are kept too.
rd_files = sorted(set(ramdisk) | set(recovery) | set(transform([os.path.basename(f) for f in glob.glob(f"{STOCK_RD}/modules/*.ko")])))
dlkm_files = sorted(set(dlkm) | set(transform([os.path.basename(f) for f in glob.glob(f"{STOCK_DLKM}/*.ko")])) - set(rd_files))

kernel_syms = {}
for line in open(GKI_SYMVERS):
    f = line.split("\t")
    if len(f) >= 3 and f[2] == "vmlinux":
        kernel_syms[f[1]] = int(f[0], 16)


def exports(path):
    """Exported symbols with their CRCs. In a .ko, __crc_<sym> is the offset of the CRC in
    __kcrctab, or in __kcrctab_gpl for EXPORT_SYMBOL_GPL."""
    sec = subprocess.run(["readelf", "-SW", path], capture_output=True, text=True).stdout
    tabs = {}
    for l in sec.splitlines():
        f = l.replace("[ ", "[").split()
        if len(f) > 2 and f[1] in ("__kcrctab", "__kcrctab_gpl"):
            tmp = os.path.join(tempfile.gettempdir(), "kcrctab.bin")
            subprocess.run([OBJCOPY, "-O", "binary", f"--only-section={f[1]}", path, tmp], check=True)
            tabs[f[0].strip("[]")] = open(tmp, "rb").read()
            os.remove(tmp)
    out = subprocess.run(["readelf", "-sW", path], capture_output=True, text=True).stdout
    crcs, syms = {}, set()
    for l in out.splitlines():
        f = l.split()
        if len(f) >= 8:
            if f[7].startswith("__crc_") and f[6] in tabs:
                off = int(f[1], 16)
                crcs[f[7][6:]] = int.from_bytes(tabs[f[6]][off:off + 4], "little")
            elif f[7].startswith("__ksymtab_"):
                syms.add(f[7][10:])
    return {s: crcs.get(s) for s in syms}


def imports(path):
    out = subprocess.run(["modprobe", "--dump-modversions", path], capture_output=True, text=True).stdout
    return {l.split()[1]: int(l.split()[0], 16) for l in out.splitlines() if len(l.split()) == 2}


# Like depmod: every imported symbol must come from the kernel or a module available at that stage.
problems = []
for stage, files, avail in (("vendor_boot", rd_files, rd_files), ("vendor_dlkm", dlkm_files, rd_files + dlkm_files)):
    provided = {}
    for f in avail:
        for sym, crc in exports(source(f)[0]).items():
            provided.setdefault(sym, (f, crc))
    for ko in files:
        missing, bad = [], []
        for sym, crc in imports(source(ko)[0]).items():
            if sym in kernel_syms:
                if kernel_syms[sym] != crc:
                    bad.append(f"{sym}(kernel)")
            elif sym in provided:
                if provided[sym][1] is not None and provided[sym][1] != crc:
                    bad.append(f"{sym}({provided[sym][0]})")
            else:
                missing.append(sym)
        if missing:
            problems.append(f"{stage}: {ko} needs {' '.join(sorted(missing)[:6])}")
        if bad:
            problems.append(f"{stage}: {ko} CRC mismatch {' '.join(sorted(bad)[:6])}")

counts = {}
for ko in rd_files + dlkm_files:
    counts[source(ko)[1]] = counts.get(source(ko)[1], 0) + 1
print(f"vendor_boot: {len(rd_files)} files ({len(ramdisk)} in ramdisk list, {len(recovery)} in recovery list); "
      f"vendor_dlkm: {len(dlkm_files)} files ({len(dlkm)} listed); sources: {counts}")
print("stock binaries still used:", " ".join(sorted(k[:-3] for k in rd_files + dlkm_files if source(k)[1] == "stock")))
print("dependency problems:", len(problems))
for p in problems:
    print("  " + p)

if opts.dry_run or problems:
    sys.exit(1 if problems else 0)

for d, files in ((f"{DEV}/modules", rd_files), (f"{DEV}/vendor_dlkm", dlkm_files)):
    shutil.rmtree(d, ignore_errors=True)
    os.makedirs(d)
    for ko in files:
        src, kind = source(ko)
        # copy, not copy2: the staged file must get the current time. Stock files date from 2009,
        # and the build only repackages a module that is newer than its output.
        shutil.copy(src, f"{d}/{ko}")
        if kind == "built":
            # Kleaf keeps DWARF in the modules; stock ships them without. Symbols stay.
            subprocess.run([STRIP, "--strip-debug", f"{d}/{ko}"], check=True)
for name, lst in (("modules.load.ramdisk", ramdisk), ("modules.load.recovery", recovery),
                  ("modules.load.vendor_dlkm", dlkm)):
    with open(f"{DEV}/{name}", "w") as f:
        f.write("\n".join(lst) + "\n")
print("staged into", DEV)
