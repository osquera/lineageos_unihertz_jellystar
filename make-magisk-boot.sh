#!/bin/bash
#
# SPDX-FileCopyrightText: 2026 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Makes boot-magisk-v<version>.img, the optional rooted boot image for a release: boot.img from
# sign-build.sh's signed-target_files.zip, patched with the patch script and binaries from the
# Magisk app, as the app itself would patch it.
#
# Usage: device/unihertz/jellystar/make-magisk-boot.sh [signed-target_files.zip]
# Output goes to the current directory.

set -euo pipefail

MAGISK_VERSION=31.1
MAGISK_SHA256=89cefac0a318afa39fb3880c45c87b036c05bc1ebf02a7a715b7f8d7c26ac6e7

# Magisk keeps its pre-init data (module sepolicy rules) on this partition. The app finds it with
# `magisk --preinit-device` on the phone; on the Jelly Star that is metadata (ext4).
MAGISK_PREINITDEVICE=metadata

target_files=$(realpath "${1:-signed-target_files.zip}")
[ -f "$target_files" ] || { echo "No $target_files, run sign-build.sh first"; exit 1; }

out=$(pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

apk="$work/Magisk-v$MAGISK_VERSION.apk"
curl -fsSL -o "$apk" \
    "https://github.com/topjohnwu/Magisk/releases/download/v$MAGISK_VERSION/Magisk-v$MAGISK_VERSION.apk"
echo "$MAGISK_SHA256  $apk" | sha256sum -c --quiet
unzip -q "$apk" 'assets/*' 'lib/arm64-v8a/*' 'lib/x86_64/*' -d "$work/apk"

magisk="$work/magisk"
mkdir "$magisk"
cp "$work/apk/assets/"{boot_patch.sh,util_functions.sh} "$magisk/"
cp "$work/apk/lib/arm64-v8a/libmagiskinit.so" "$magisk/magiskinit"
cp "$work/apk/lib/arm64-v8a/libmagisk.so" "$magisk/magisk"
cp "$work/apk/lib/arm64-v8a/libinit-ld.so" "$magisk/init-ld"
# The x86_64 magiskboot is statically linked and runs on the build host.
cp "$work/apk/lib/x86_64/libmagiskboot.so" "$magisk/magiskboot"
unzip -p "$target_files" IMAGES/boot.img > "$magisk/boot.img"

# The app's defaults on this phone: keep dm-verity and encryption flags, no vbmeta patching
# (ours already has verification disabled). BOOTMODE=false skips the on-device checks.
(cd "$magisk" && BOOTMODE=false OUTFD=1 KEEPVERITY=true KEEPFORCEENCRYPT=true \
    PATCHVBMETAFLAG=false RECOVERYMODE=false PREINITDEVICE=$MAGISK_PREINITDEVICE \
    bash ./boot_patch.sh boot.img | sed -n 's/^ui_print //p')
cp "$magisk/new-boot.img" "$out/boot-magisk-v$MAGISK_VERSION.img"

echo "Magisk boot image: $out/boot-magisk-v$MAGISK_VERSION.img"
