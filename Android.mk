#
# SPDX-FileCopyrightText: 2026 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),jellystar)

# Unihertz's bootloader builds the kernel's ramdisk from vendor_boot's first platform fragment,
# then (in recovery) its recovery fragment, then the generic ramdisk of init_boot when that
# partition holds a boot image, else of boot. Phones updated from Android 13 by Unihertz's OTA can
# keep an init_boot whose ramdisk is empty, so the kernel would get no /init and panic. Stock
# carries the whole first stage in its vendor ramdisk, so a copy of the generic ramdisk goes into
# the vendor ramdisk here. Where boot's ramdisk is loaded, it comes last and replaces the copy.
JELLYSTAR_GENERIC_RAMDISK_DIRS := \
    debug_ramdisk dev metadata mnt proc second_stage_resources sys \
    $(addprefix first_stage_ramdisk/,debug_ramdisk dev metadata mnt proc second_stage_resources sys)

JELLYSTAR_GENERIC_RAMDISK_FILES := \
    system/bin/snapuserd_ramdisk \
    system/bin/toolbox_ramdisk \
    system/etc/init/snapuserd.rc \
    system/etc/ramdisk/build.prop

JELLYSTAR_GENERIC_RAMDISK_SYMLINKS := \
    system/bin/getevent:toolbox_ramdisk \
    system/bin/getprop:toolbox_ramdisk \
    system/bin/modprobe:toolbox_ramdisk \
    system/bin/setprop:toolbox_ramdisk \
    system/bin/snapuserd:snapuserd_ramdisk \
    system/bin/start:toolbox_ramdisk \
    system/bin/stop:toolbox_ramdisk

# The mount points are empty directories, so they are created along with /init.
$(TARGET_VENDOR_RAMDISK_OUT)/init: PRIVATE_DIRS := $(JELLYSTAR_GENERIC_RAMDISK_DIRS)
$(TARGET_VENDOR_RAMDISK_OUT)/init: $(TARGET_RAMDISK_OUT)/init
	$(copy-file-to-target)
	$(hide) mkdir -p $(addprefix $(dir $@),$(PRIVATE_DIRS))

$(foreach f,$(JELLYSTAR_GENERIC_RAMDISK_FILES), \
    $(eval $(call copy-one-file,$(TARGET_RAMDISK_OUT)/$(f),$(TARGET_VENDOR_RAMDISK_OUT)/$(f))))

$(foreach f,init $(JELLYSTAR_GENERIC_RAMDISK_FILES), \
    $(call declare-copy-target-license-metadata,$(TARGET_VENDOR_RAMDISK_OUT)/$(f),$(TARGET_RAMDISK_OUT)/$(f)))

# Each link depends on the copy of the binary it points to.
$(foreach l,$(JELLYSTAR_GENERIC_RAMDISK_SYMLINKS), \
    $(call symlink-file, \
        $(TARGET_VENDOR_RAMDISK_OUT)/system/bin/$(call word-colon,2,$(l)), \
        $(call word-colon,2,$(l)), \
        $(TARGET_VENDOR_RAMDISK_OUT)/$(call word-colon,1,$(l))))

ALL_DEFAULT_INSTALLED_MODULES += \
    $(TARGET_VENDOR_RAMDISK_OUT)/init \
    $(addprefix $(TARGET_VENDOR_RAMDISK_OUT)/,$(JELLYSTAR_GENERIC_RAMDISK_FILES)) \
    $(addprefix $(TARGET_VENDOR_RAMDISK_OUT)/,$(foreach l,$(JELLYSTAR_GENERIC_RAMDISK_SYMLINKS),$(call word-colon,1,$(l))))

endif
