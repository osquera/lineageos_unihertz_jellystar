#!/bin/bash
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Builds MediaTek's MT6789 kernel modules for the Jelly Star (the module set is in the module
# tree's kernel/kleaf/jellystar_modules.bzl). Log: <ws>/../build-modules.log.
#
# Usage: [JOBS=6] kernel/tools/build-modules.sh <ws>    (<ws> from setup-workspace.sh)
# Then stage the modules with stage-modules.py.

set -euo pipefail

WS=$(realpath "${1:?usage: $0 <workspace>/ws}")
cd "$WS"

export KERNEL_VERSION=kernel-6.12 SUPPORT_PLATFORM=mt6789
export DEFCONFIG_OVERLAYS="entry_level.config jellystar.config"
export KERNEL_BUILD_VARIANT=user BAZEL_DO_NOT_DETECT_CPP_TOOLCHAIN=1

OUT=(--output_user_root="$WS/out" --output_base="$WS/out/bazel/output_user_root/output_base")
ARGS=(--experimental_writable_outputs --allow_ddk_unsafe_headers=1 --workaround_btrfs_b292212788
      --//build/bazel_mgk_rules:kernel_version=6.12 --experimental_optimize_ddk_config_actions
      --user_ddk_unsafe_headers=//kernel_device_modules-6.12:mtk_use_gki_unsafe_headers
      --keep_going ${JOBS:+--jobs=$JOBS})

tools/bazel "${OUT[@]}" build "${ARGS[@]}" \
    //kernel_device_modules-6.12:mgk_64_k612_customer_modules_install.user \
    2>&1 | tee "$WS/../build-modules.log"
