#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Identity below is OURS, PROVEN (read from the device via adb getprop, 2026-09-29):
# ro.product.brand=Unihertz, ro.product.manufacturer=Unihertz, ro.product.model=Jelly Star,
# ro.build.fingerprint=Unihertz/Jelly_Star_EEA/Jelly_Star:16/BP2A.250605.031.A3/
# V01.00.03:user/release-keys
#
# 🔴 OPEN: this fingerprint is from the currently-running GSI's stock backup, build V01.00.03.
# The stock firmware we have locally for blob extraction is V01.00.04 (newer). Confirm which
# build the extracted blobs actually come from before finalizing this fingerprint string —
# mixing a fingerprint from one build with blobs from another is a known source of
# hard-to-diagnose failures (see docs/BLOBS.md once written, following the iKKO precedent).

ZYGOTE_FORCE_64 := true
TARGET_SUPPORTS_OMX_SERVICE := false
TARGET_REQUIRES_HIDL_CAS_HAL := false
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from device makefile.
$(call inherit-product, device/unihertz/jellystar/device.mk)

# Inherit some common LineageOS stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

PRODUCT_NAME := lineage_jellystar
PRODUCT_DEVICE := jellystar
PRODUCT_MANUFACTURER := Unihertz
PRODUCT_BRAND := Unihertz
PRODUCT_MODEL := Jelly Star

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildFingerprint=Unihertz/Jelly_Star_EEA/Jelly_Star:16/BP2A.250605.031.A3/V01.00.03:user/release-keys \
    DeviceProduct=Jelly_Star_EEA

# 🔴 REMOVED (2026-09-30): previously tried to override ro.control_privapp_permissions from
# LineageOS's own "enforce" (vendor/lineage/config/common.mk) down to "log", via a
# filter-out-then-append pattern. That pattern does NOT work in this build pipeline — Soong's
# product-config generation (out/soong/.intermediates/build/soong/product-build.prop) still
# saw both assignments and failed with "found duplicate sysprop assignments", even though the
# filter-out should have removed the "enforce" entry before ours was appended at the Make
# level. Not worth fighting further: "enforce" (the secure default) has nothing to do with
# either target bug (NFC, BT A2DP) — this override was just an iKKO-inherited debugging
# convenience, not something we actually need. Dropped entirely.

WITH_GAPPS ?= false
ifeq ($(WITH_GAPPS),true)
$(call inherit-product, vendor/gapps/arm64/arm64-vendor.mk)
endif
