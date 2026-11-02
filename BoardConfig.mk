#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Based on iasnezhkov/android_device_ikko_mindone (also MT6789).

DEVICE_PATH := device/unihertz/jellystar

# Architecture: Helio G99 (MT6789), 2x Cortex-A76 + 6x Cortex-A55
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-2a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := cortex-a76

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-2a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic
TARGET_2ND_CPU_VARIANT_RUNTIME := cortex-a55
TARGET_DYNAMIC_64_32_MEDIASERVER := true

# A/B
AB_OTA_UPDATER := true

AB_OTA_PARTITIONS += \
    boot \
    vendor_boot \
    dtbo \
    system \
    system_ext \
    product \
    vendor \
    vendor_dlkm \
    odm_dlkm \
    system_dlkm \
    vbmeta \
    vbmeta_system \
    vbmeta_vendor

# Bootloader (stock ro.product.board)
TARGET_BOOTLOADER_BOARD_NAME := g58v89c2k_dfl_eea
TARGET_NO_BOOTLOADER := true

# Kernel: load addresses from the stock vendor_boot header (kernel 0x40000000,
# tags/dtb 0x47c80000, ramdisk 0x66f00000).
BOARD_KERNEL_BASE := 0x3fff8000
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_KERNEL_PAGESIZE := 4096
BOARD_KERNEL_TAGS_OFFSET := 0x07c88000
BOARD_RAMDISK_OFFSET := 0x26f08000
BOARD_DTB_OFFSET := 0x07c88000

BOARD_BOOT_HEADER_VERSION := 4
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
BOARD_MOVE_GSI_AVB_KEYS_TO_VENDOR_BOOT := true
BOARD_USES_GENERIC_KERNEL_IMAGE := true

# Same cmdline and bootconfig as stock vendor_boot. A non-empty BOARD_BOOTCONFIG also adds the
# "bootconfig" cmdline token.
BOARD_KERNEL_CMDLINE := bootopt=64S3,32N2,64N2

BOARD_BOOTCONFIG := kernel.rcu_nocbs=all
BOARD_BOOTCONFIG += kernel.rcutree.enable_rcu_lazy=1
BOARD_BOOTCONFIG += kernel.rcupdate.rcu_cpu_stall_cputime=1

BOARD_MKBOOTIMG_ARGS := --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)
BOARD_MKBOOTIMG_ARGS += --dtb_offset $(BOARD_DTB_OFFSET)
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --board ""

# Display: 480x854, density as stock (ro.sf.lcd_density=220)
TARGET_SCREEN_DENSITY := 220

# Recovery: the xhdpi resources (18x32 font, 512 px logo) overflow this screen; hdpi uses a
# 12x22 font.
TARGET_RECOVERY_DENSITY := hdpi

# DTBO
BOARD_KERNEL_SEPARATED_DTBO := true

# HIDL/AIDL manifest & compatibility matrix
DEVICE_MANIFEST_FILE += $(DEVICE_PATH)/manifest.xml
DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE := hardware/mediatek/vintf/mediatek_framework_compatibility_matrix.xml
DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE += $(DEVICE_PATH)/compatibility_matrix.xml

# Prebuilt GKI kernel (LZ4) from stock boot.img; first-stage modules from stock vendor_boot.
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/kernel/Image.lz4
TARGET_KERNEL_ARCH := arm64

BOARD_VENDOR_RAMDISK_KERNEL_MODULES_LOAD := $(strip $(shell cat $(DEVICE_PATH)/kernel/modules.load.ramdisk 2>/dev/null))
BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD := $(strip $(shell cat $(DEVICE_PATH)/kernel/modules.load.recovery 2>/dev/null))
BOOT_KERNEL_MODULES := $(BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD) $(BOARD_VENDOR_RAMDISK_KERNEL_MODULES_LOAD)
BOARD_VENDOR_RAMDISK_KERNEL_MODULES := $(foreach m,$(sort $(BOARD_VENDOR_RAMDISK_KERNEL_MODULES_LOAD) $(BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD)),$(DEVICE_PATH)/kernel/modules/$(m))
BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES := $(foreach m,$(BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD),$(DEVICE_PATH)/kernel/modules/$(m))
# No BOARD_VENDOR_KERNEL_MODULES: the second-stage modules ship in the stock vendor_dlkm image
# (see "Stock vendor-side images" below).
# Stock has no modules.options, so no BOARD_VENDOR_KERNEL_MODULES_OPTIONS_FILE.
BOARD_DO_NOT_STRIP_VENDOR_RAMDISK_MODULES := true
BOARD_DO_NOT_STRIP_VENDOR_MODULES := true
BOARD_DO_NOT_STRIP_RECOVERY_MODULES := true

# DTB / DTBO: every .dtb in kernel/dtb/ is concatenated into vendor_boot, and with two the phone
# no longer boots (no adb, no log). The directory is gitignored, so a stale file from an older
# build can sit there unnoticed; fail the build instead.
BOARD_PREBUILT_DTBIMAGE_DIR := $(DEVICE_PATH)/kernel/dtb
jellystar_dtbs := $(wildcard $(BOARD_PREBUILT_DTBIMAGE_DIR)/*.dtb)
ifneq ($(words $(jellystar_dtbs)),1)
ifneq ($(words $(jellystar_dtbs)),0)
$(error $(BOARD_PREBUILT_DTBIMAGE_DIR) holds $(words $(jellystar_dtbs)) .dtb files ($(notdir $(jellystar_dtbs))); \
        every one of them is concatenated into vendor_boot. Keep exactly one and rebuild)
endif
endif
BOARD_PREBUILT_DTBOIMAGE := $(DEVICE_PATH)/kernel/dtbo.img

# Partitions (sizes from the stock scatter file)
BOARD_FLASH_BLOCK_SIZE := 131072
BOARD_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := $(BOARD_BOOTIMAGE_PARTITION_SIZE)
BOARD_DTBOIMG_PARTITION_SIZE := 8388608
BOARD_SUPER_PARTITION_SIZE := 9663676416
BOARD_SUPER_IMAGE_IN_UPDATE_PACKAGE := true
BOARD_USES_METADATA_PARTITION := true

BOARD_SUPER_PARTITION_GROUPS := mediatek_dynamic_partitions
BOARD_MEDIATEK_DYNAMIC_PARTITIONS_PARTITION_LIST := odm_dlkm product system system_dlkm system_ext vendor vendor_dlkm
BOARD_MEDIATEK_DYNAMIC_PARTITIONS_SIZE := 9661579264

BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := ext4
# Room for GApps (MindTheGapps) sideloaded after installing: the images are otherwise built to
# fit their contents, and the installer also checks free space in system and system_ext. This is
# what official LineageOS devices use: free space and inodes in product (1.1 GiB with Virtual A/B),
# system and system_ext (90 MiB each). Every update writes the same headroom, and MindTheGapps'
# addon.d script restores GApps. super has room to spare.
-include vendor/lineage/config/BoardConfigReservedSize.mk
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := ext4

# Stock vendor-side images, used unmodified (EROFS, each with its own AVB hashtree footer).
# Building our own vendor booted only to the splash screen; the stock one boots and gives
# working audio, NFC HAL, camera, sensors and modem. Taken from the V01.00.04 firmware's super
# via lpunpack (vendor_a, vendor_dlkm_a, odm_dlkm_a, system_dlkm_a). system_dlkm is mandatory:
# the stock first-stage fstab mounts it without nofail, and its absence caused the 20 s loop.
# Our device-specific changes therefore go into system/system_ext/product only.
BOARD_PREBUILT_VENDORIMAGE := vendor/unihertz/jellystar/images/vendor.img
BOARD_PREBUILT_VENDOR_DLKMIMAGE := vendor/unihertz/jellystar/images/vendor_dlkm.img
BOARD_PREBUILT_ODM_DLKMIMAGE := vendor/unihertz/jellystar/images/odm_dlkm.img
BOARD_PREBUILT_SYSTEM_DLKMIMAGE := vendor/unihertz/jellystar/images/system_dlkm.img

TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_SYSTEM_EXT := system_ext
TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm
TARGET_COPY_OUT_ODM_DLKM := odm_dlkm
TARGET_COPY_OUT_SYSTEM_DLKM := system_dlkm

# Properties
TARGET_PRODUCT_PROP += $(DEVICE_PATH)/product.prop
TARGET_SYSTEM_EXT_PROP += $(DEVICE_PATH)/system_ext.prop
TARGET_VENDOR_PROP += $(DEVICE_PATH)/vendor.prop

# Recovery (ro.hardware=mt6789, so init reads fstab.mt6789)
BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true
# Unihertz's LK needs a separate "recovery" fragment (type 0x2) in the vendor ramdisk table, as
# stock vendor_boot has. Without it every recovery boot halts in LK with "ASSERT FAILED at
# (app/mt_boot/boot_info.c:333): idx < entry_cnt" and the phone loops.
BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT := true
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/rootdir/etc/fstab.mt6789
TARGET_RECOVERY_PIXEL_FORMAT := BGRA_8888
TARGET_USERIMAGES_USE_F2FS := true

# SEPolicy — the stock vendor partition ships its own complete vendor policy, so never include
# device/mediatek/sepolicy_vndr/SEPolicy.mk wholesale: its system_ext property_contexts
# re-declares persist.vendor.pco5.radio.ctrl and init aborts with "Duplicate prefix match
# detected" against the stock vendor_property_contexts.
# Our own additions only define new types, so they can't collide with the stock vendor policy.
SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/private

# MediaTek's system_ext policy (types such as sysfs_headset that the stock vendor policy expects
# from system_ext, plus their labels), minus the one vendor property it re-declares: see
# sepolicy/mtk_private/property_contexts. Its vendor part is left out on purpose.
SYSTEM_EXT_PUBLIC_SEPOLICY_DIRS += device/mediatek/sepolicy_vndr/base/public
SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/mtk_private
ifneq ($(TARGET_BUILD_VARIANT),user)
SYSTEM_EXT_PUBLIC_SEPOLICY_DIRS += device/mediatek/sepolicy_vndr/debug/public
SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS += device/mediatek/sepolicy_vndr/debug/private
endif
# Vendor policy only ends up in recovery (see sepolicy/vendor/file_contexts).
BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/vendor

# SPL
BOOT_SECURITY_PATCH := 2026-05-01
VENDOR_SECURITY_PATCH := $(BOOT_SECURITY_PATCH)

BOARD_AVB_ENABLE := true

ifneq (,$(AVB_CUSTOM_KEY_PATH))
BOARD_AVB_ALGORITHM := $(AVB_CUSTOM_ALGORITHM)
BOARD_AVB_KEY_PATH := $(AVB_CUSTOM_KEY_PATH)
else
AVB_CUSTOM_ALGORITHM := SHA256_RSA2048
AVB_CUSTOM_KEY_PATH := external/avb/test/data/testkey_rsa2048.pem
endif

ifneq ($(WITH_AVB),true)
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3
endif

BOARD_AVB_BOOT_ALGORITHM := $(AVB_CUSTOM_ALGORITHM)
BOARD_AVB_BOOT_KEY_PATH := $(AVB_CUSTOM_KEY_PATH)
BOARD_AVB_BOOT_ROLLBACK_INDEX := 1
BOARD_AVB_BOOT_ROLLBACK_INDEX_LOCATION := 1

BOARD_AVB_VBMETA_SYSTEM := product system system_ext
BOARD_AVB_VBMETA_SYSTEM_ALGORITHM := $(AVB_CUSTOM_ALGORITHM)
BOARD_AVB_VBMETA_SYSTEM_KEY_PATH := $(AVB_CUSTOM_KEY_PATH)
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX := 1
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX_LOCATION := 2

BOARD_AVB_VBMETA_VENDOR := vendor
BOARD_AVB_VBMETA_VENDOR_ALGORITHM := $(AVB_CUSTOM_ALGORITHM)
BOARD_AVB_VBMETA_VENDOR_KEY_PATH := $(AVB_CUSTOM_KEY_PATH)
BOARD_AVB_VBMETA_VENDOR_ROLLBACK_INDEX := 1
BOARD_AVB_VBMETA_VENDOR_ROLLBACK_INDEX_LOCATION := 3

# Wi-Fi
WPA_SUPPLICANT_VERSION := VER_0_8_X
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
BOARD_HOSTAPD_DRIVER := NL80211
WIFI_DRIVER_FW_PATH_STA := "STA"
WIFI_DRIVER_FW_PATH_AP := "AP"
WIFI_DRIVER_FW_PATH_P2P := "P2P"
WIFI_HIDL_FEATURE_DUAL_INTERFACE := true
WIFI_HIDL_UNIFIED_SUPPLICANT_SERVICE_RC_ENTRY := true
WIFI_DRIVER_FW_PATH_PARAM := "/dev/wmtWifi"
WIFI_DRIVER_STATE_CTRL_PARAM := "/dev/wmtWifi"
WIFI_DRIVER_STATE_ON := "1"
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := lib_driver_cmd_mt66xx
WIFI_DRIVER_STATE_OFF := "0"

# Proprietary
include vendor/unihertz/jellystar/BoardConfigVendor.mk

# Prebuilt vendor blobs fail the ELF dependency checks (KeyMint, audio HAL, ...).
BUILD_BROKEN_PREBUILT_ELF_FILES := true

$(call soong_config_set,android_hardware_audio,run_64bit,true)
BUILD_BROKEN_NINJA_USES_ENV_VARS += ROSETTA_DISABLE_AOT
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true
