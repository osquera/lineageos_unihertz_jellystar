#!/bin/bash
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Sets up the workspace for building the kernel modules, from public sources only:
#   src/        Google's Android common kernel, pinned to GKI build 15464463 (the kernel the
#               phone runs, 6.12.69-android16-6-g86dc53cfe87f), with toolchain and Kleaf
#   oneplus/    OnePlus' MT6993 GPL release: MediaTek's Kleaf rules and vendor/mediatek
#               kernel_modules, with oneplus-vendor.patch (drops OnePlus-only dependencies)
#   modules/    MediaTek's kernel_device_modules-6.12 with the Jelly Star changes
#   ws/         the Bazel workspace, made of links into the three above
#
# Usage: kernel/tools/setup-workspace.sh <directory>     (needs repo, git, about 60 GB)
# Then build with build-modules.sh <directory>/ws.

set -euo pipefail

TOOLS=$(cd "$(dirname "$0")" && pwd)
DIR=$(realpath -m "${1:?usage: $0 <directory>}")

ACK_MANIFEST_URL=https://android.googlesource.com/kernel/manifest
ACK_MANIFEST_BRANCH=common-android16-6.12
ONEPLUS_URL=https://github.com/OnePlusOSS/android_kernel_modules_and_devicetree_oneplus_mt6993.git
ONEPLUS_REV=2cc7f4606b65a9ede42030ee82614dd845b665a1
MODULES_URL=https://github.com/osquera/android_kernel_unihertz_jellystar-modules.git
MODULES_BRANCH=jellystar
BAZEL_COMMON_RULES_URL=https://android.googlesource.com/platform/build/bazel_common_rules
BAZEL_COMMON_RULES_REV=b1a2840cb13746f94e4c88e7e28d308f51f87804

mkdir -p "$DIR"
cd "$DIR"

if [ ! -d src/.repo ]; then
    mkdir -p src
    (cd src && repo init -u "$ACK_MANIFEST_URL" -b "$ACK_MANIFEST_BRANCH" &&
        cp "$TOOLS/ack-manifest.xml" .repo/manifests/jellystar.xml &&
        repo init -m jellystar.xml)
fi
(cd src && repo sync -c -j"${JOBS:-4}")

if [ ! -d oneplus/.git ]; then
    git init -q oneplus
    git -C oneplus remote add origin "$ONEPLUS_URL"
    git -C oneplus fetch --depth 1 origin "$ONEPLUS_REV"
    git -C oneplus checkout -q FETCH_HEAD
    git -C oneplus apply "$TOOLS/oneplus-vendor.patch"
fi

if [ ! -d modules/.git ]; then
    # Shallow clone: the tree carries the full Linux history, which the build doesn't need
    # (`git fetch --unshallow` gets it later if wanted).
    git clone --depth 1 -b "$MODULES_BRANCH" "$MODULES_URL" modules
fi

# MediaTek's mgk_internal repository rule looks for vendor/mediatek next to the workspace.
ln -sfn oneplus/vendor vendor

mkdir -p ws
cd ws
if [ ! -d build ]; then
    cp -a ../oneplus/kernel/build ../oneplus/kernel/common ../oneplus/kernel/tools .
    (cd build/bazel_mgk_rules && git apply "$TOOLS/mgk-rules-dtb.patch")
    git clone -q "$BAZEL_COMMON_RULES_URL" build/bazel_common_rules
    git -C build/bazel_common_rules checkout -q "$BAZEL_COMMON_RULES_REV"
fi
for d in bootable common-modules external prebuilts system; do
    ln -sfn "../src/$d" "$d"
done
ln -sfn ../src/common common-6.12
ln -sfn ../src/common kernel-6.12
ln -sfn ../modules kernel_device_modules-6.12
ln -sfn ../oneplus/kernel/oplus oplus
ln -sfn ../oneplus/vendor vendor
ln -sfn ../src/tools/mkbootimg tools/mkbootimg
ln -sfn build/bazel_mgk_rules/bzlmod/mgk.MODULE.bazel MODULE.bazel
ln -sfn build/bazel_mgk_rules/kleaf/bazel.WORKSPACE WORKSPACE

echo "Workspace ready: $DIR/ws"
