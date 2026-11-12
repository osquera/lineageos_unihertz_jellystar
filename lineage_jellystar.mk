#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

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

WITH_GAPPS ?= false
ifeq ($(WITH_GAPPS),true)
$(call inherit-product, vendor/gapps/arm64/arm64-vendor.mk)
endif
