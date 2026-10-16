#!/bin/bash
#
# SPDX-FileCopyrightText: 2026 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Builds the target-files package and signs it with your own release keys, following
# https://wiki.lineageos.org/signing_builds (LineageOS 19.1+ section, APEX lists from the
# lineage_wiki source). Keys are generated once, as described there, into $KEYS.
#
# Usage, from the root of the source tree after `source build/envsetup.sh && lunch ...`:
#   device/unihertz/jellystar/sign-build.sh
# Output: signed-target_files.zip and lineage-<version>-<date>-UNOFFICIAL-jellystar-signed.zip

set -euo pipefail

KEYS=${KEYS:-$HOME/.android-certs}

APEX_APKS=(
    com.android.appsearch.apk AdServicesApk FederatedCompute HalfSheetUX
    HealthConnectBackupRestore HealthConnectController OsuLogin SafetyCenterResources
    ServiceConnectivityResources ServiceUwbResources ServiceWifiResources
    TelecomServiceResources TelecomUi WebAppService WifiDialog
)

APEXES=(
    com.android.adbd com.android.adservices com.android.adservices.api com.android.appsearch
    com.android.art com.android.bluetooth com.android.bt com.android.btservices
    com.android.cellbroadcast com.android.compos com.android.configinfrastructure
    com.android.connectivity.resources com.android.conscrypt com.android.crashrecovery
    com.android.devicelock com.android.extservices com.android.graphics.pdf
    com.android.hardware.authsecret com.android.hardware.biometrics.face.virtual
    com.android.hardware.biometrics.fingerprint.virtual com.android.hardware.boot
    com.android.hardware.cas com.android.hardware.contexthub com.android.hardware.drm.clearkey
    com.android.hardware.dumpstate com.android.hardware.gatekeeper.nonsecure
    com.android.hardware.neuralnetworks com.android.hardware.power
    com.android.hardware.rebootescrow com.android.hardware.thermal
    com.android.hardware.threadnetwork com.android.hardware.uwb com.android.hardware.vibrator
    com.android.hardware.wifi com.android.healthfitness com.android.hotspot2.osulogin
    com.android.i18n com.android.ipsec com.android.media com.android.media.swcodec
    com.android.mediaprovider com.android.nearby.halfsheet com.android.networkstack.tethering
    com.android.neuralnetworks com.android.nfcservices com.android.npumanager
    com.android.ondevicepersonalization com.android.os.statsd com.android.permission
    com.android.profiling com.android.resolv com.android.rkpd com.android.runtime
    com.android.safetycenter.resources com.android.scheduling com.android.sdkext
    com.android.support.apexer com.android.telephony com.android.telephonycore
    com.android.telephonymodules com.android.tethering com.android.tzdata
    com.android.uprobestats com.android.uwb com.android.uwb.resources com.android.virt
    com.android.vndk.current com.android.vndk.current.on_vendor com.android.webapp
    com.android.wifi com.android.wifi.dialog com.android.wifi.resources
    com.google.pixel.camera.hal com.google.pixel.vibrator.hal com.qorvo.uwb
)

[ -f "$KEYS/releasekey.pk8" ] || { echo "No keys in $KEYS, see the LineageOS signing guide"; exit 1; }
[ -n "${OUT:-}" ] || { echo "Run 'source build/envsetup.sh && lunch ...' first"; exit 1; }

# croot/mka are shell functions from envsetup.sh and don't reach scripts.
cd "$ANDROID_BUILD_TOP"
# JOBS limits parallelism, e.g. JOBS=10 on machines with ~32 GB RAM.
build/soong/soong_ui.bash --make-mode ${JOBS:+-j$JOBS} target-files-package otatools

args=(-o -d "$KEYS")
for apk in "${APEX_APKS[@]}"; do
    args+=(--extra_apks "$apk.apk=$KEYS/releasekey")
done
for apex in "${APEXES[@]}"; do
    args+=(--extra_apks "$apex.apex=$KEYS/$apex")
    args+=(--extra_apex_payload_key "$apex.apex=$KEYS/$apex.pem")
done

# The stock vendor-side images are prebuilts (BOARD_PREBUILT_*IMAGE) and only exist under IMAGES/.
# sign_target_files_apks drops all of IMAGES/ and regenerates images from their source
# directories, which prebuilts don't have ("AssertionError: Failed to find odm_dlkm.img"). So:
# park copies under RADIO/ (copied verbatim, and accepted by the A/B image check), sign, then
# move them back and rebuild the vbmeta images, which were built without their descriptors.
# vbmeta_vendor is parked too: the signer only builds it when it sees vendor.img, and the A/B
# image check needs one. That stale copy is deleted again before the vbmeta rebuild.
PREBUILT_PARTITIONS="vendor vendor_dlkm odm_dlkm system_dlkm"
unsigned=$(ls "$OUT"/obj/PACKAGING/target_files_intermediates/*-target_files*.zip)

python3 - "$unsigned" unsigned-target_files.zip $PREBUILT_PARTITIONS vbmeta_vendor <<'EOF'
import shutil, sys, tempfile, zipfile
src, dst, parts = sys.argv[1], sys.argv[2], sys.argv[3:]
shutil.copyfile(src, dst)
with tempfile.TemporaryDirectory() as tmp, zipfile.ZipFile(src) as zin, \
        zipfile.ZipFile(dst, "a", allowZip64=True) as zout:
    for p in parts:
        img = zin.extract(f"IMAGES/{p}.img", tmp)
        zout.write(img, f"RADIO/{p}.img")
EOF

sign_target_files_apks "${args[@]}" unsigned-target_files.zip signed-target_files.zip

python3 - signed-target_files.zip $PREBUILT_PARTITIONS <<'EOF'
import copy, os, shutil, sys, zipfile
path, parts = sys.argv[1], sys.argv[2:]
moved = {f"RADIO/{p}.img": f"IMAGES/{p}.img" for p in parts}
drop = {"IMAGES/vbmeta.img", "IMAGES/vbmeta_vendor.img", "RADIO/vbmeta_vendor.img"} | set(moved.values())
with zipfile.ZipFile(path) as zin, zipfile.ZipFile(path + ".tmp", "w", zipfile.ZIP_DEFLATED, allowZip64=True) as zout:
    for info in zin.infolist():
        if info.filename in drop:
            continue
        # Keep each entry's metadata: permissions and directory entries live in external_attr.
        out = copy.copy(info)
        out.filename = moved.get(info.filename, info.filename)
        if info.is_dir():
            zout.writestr(out, b"")
            continue
        with zin.open(info) as f, zout.open(out, "w", force_zip64=True) as o:
            shutil.copyfileobj(f, o)
os.replace(path + ".tmp", path)
EOF

add_img_to_target_files --is_signing --add_missing signed-target_files.zip

version=$(unzip -p signed-target_files.zip PRODUCT/etc/build.prop | sed -n 's/^ro.lineage.version=//p')
ota_from_target_files -k "$KEYS/releasekey" --block --backup=true \
    signed-target_files.zip "lineage-$version-signed.zip"

echo "Signed package: $(pwd)/lineage-$version-signed.zip"
