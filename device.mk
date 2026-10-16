#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Adapted from iasnezhkov/android_device_ikko_mindone (same MT6789/Helio G99 platform,
# same LineageOS 23/Android 16 target). Their tree is roughly half genuinely
# platform-generic MediaTek boilerplate (kept below) and half their OWN custom-written
# components (a from-scratch audio HAL, sensors HAL, HIDL->AIDL bridges, launcher, key
# handler) that do not apply to us and have been REMOVED, not renamed — we do not have
# equivalents for those yet. Real gaps are marked 🔴 OPEN rather than filled with guesses.
#
# Confirmed facts used below (adb getprop / live device inspection, 2026-09-28/29):
#   ro.board.platform=mt6789, ro.hardware=mt6789 (fstab.mt6789, NOT fstab.mt8781)
#   NFC: TMS chip (android.hardware.nfc-service-tms, /dev/tms_nfc), NOT NXP
#   Audio: android.hardware.audio.service-aidl.mediatek (AIDL Core Audio HAL wrapper around
#     a legacy audio.primary.mt6789.so blob) — NOT the old HIDL @7.0 IDevicesFactory
#     architecture iKKO's tree assumes. The vendor's own audio HAL binaries + libs will be
#     handled as extracted prebuilt blobs (proprietary-files.txt), not PRODUCT_PACKAGES
#     built from AOSP source — the old android.hardware.audio@7.0-impl packages below were
#     removed for that reason.

# Installs gsi keys into ramdisk, to boot a developer GSI with verified boot.
$(call inherit-product, $(SRC_TARGET_DIR)/product/developer_gsi_keys.mk)

# Dalvik VM Configuration
$(call inherit-product, frameworks/native/build/phone-xhdpi-6144-dalvik-heap.mk)

# Project ID Quota
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

# Enforce generic ramdisk allow list
$(call inherit-product, $(SRC_TARGET_DIR)/product/generic_ramdisk.mk)

# A/B
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/launch_with_vendor_ramdisk.mk)

PRODUCT_PACKAGES += \
    com.android.hardware.boot \
    android.hardware.boot-service.default_recovery

PRODUCT_PACKAGES += \
    update_engine \
    update_engine_sideload \
    update_verifier

PRODUCT_PACKAGES_DEBUG += \
    update_engine_client

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=ext4 \
    POSTINSTALL_OPTIONAL_system=true

# No vendor postinstall step: the stock vendor image is EROFS and has no checkpoint_gc, so
# update_engine's "mount vendor_b as ext4" fails with kPostInstallMountError.

PRODUCT_PACKAGES += \
    otapreopt_script

# AAPT
PRODUCT_AAPT_CONFIG := normal
PRODUCT_AAPT_PREF_CONFIG := hdpi

# Audio — the real audio HAL (android.hardware.audio.service-aidl.mediatek + its .so's,
# audio.primary.mt6789.so, libbluetooth_audio_session_aidl_mtk.so, etc.) is a closed vendor
# blob set, handled via proprietary-files.txt, NOT built from AOSP source here.
PRODUCT_PACKAGES += \
    audio.r_submix.default \
    audio.usb.default

# bluetooth_audio_policy_configuration.xml — device-tree-owned override, NOT the stock blob
# (see the REMOVED note in proprietary-files.txt). Adds AUDIO_FORMAT_APTX (+ SBC/AAC/APTX_HD/
# LDAC) <profile> entries to the "bluetooth" module's "a2dp output" mixPort, which the stock
# file left completely empty. This is the confirmed, Frida-verified fix for the BT A2DP bug:
# AudioPolicyManager::setDeviceConnectionStateInt() resolves a NULL DeviceDescriptor (and
# fails the whole A2DP connection with ENOSYS) specifically when the negotiated codec is
# APTX, because nothing in the static profile list matched — this happens at the framework
# level, before the vendor audio HAL is ever consulted. See the file's own header comment
# for the full write-up.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/audio/bluetooth_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/bluetooth_audio_policy_configuration.xml

# VINTF manifest fragments for the audio/bluetooth-audio AIDL HAL instances actually
# registered by the vendor's own service binaries (android.hardware.audio.service-aidl.
# mediatek, bluetooth_audio provider factory) — pulled verbatim from the real stock vendor
# partition (see device/unihertz/jellystar/vintf/manifest/, extracted 2026-09-29 via
# lpunpack+fsck.erofs from the local stock super.img, no device connection needed). Without
# these, AIDL HAL instances declared by our extracted service blobs are never advertised to
# the framework via VINTF — directly relevant to getting NFC/audio working correctly, not
# just a build-time technicality.
# Modern AOSP forbids installing VINTF XML via raw PRODUCT_COPY_FILES (build/make/core/
# Makefile.mk explicitly rejects it) — these are `vintf_fragment` Soong modules instead, see
# device/unihertz/jellystar/vintf/manifest/Android.bp.
PRODUCT_PACKAGES += \
    android.hardware.audio.service-aidl.mediatek.xml \
    android.hardware.audio.effect.service-aidl.xml \
    bluetooth_audio.mediatek.xml

# Bluetooth
# android.hardware.bluetooth-service.mediatek is built from real AOSP source
# (hardware/mediatek/aidl/bluetooth/Android.bp) rather than as a vendor blob — see memory,
# confirmed safe during the collision cleanup pass. Its VINTF fragment (declaring
# IBluetoothHci/default) is still the real stock one — a `vintf_fragment` Soong module, see
# device/unihertz/jellystar/vintf/manifest/Android.bp.
PRODUCT_PACKAGES += \
    android.hardware.bluetooth-service-mediatek.xml

# Dynamic Partitions
PRODUCT_USE_DYNAMIC_PARTITIONS := true
PRODUCT_BUILD_SUPER_PARTITION := true

PRODUCT_PACKAGES += \
    fastbootd

# FM radio — the chip is there (/dev/fm, MTK connsys FM). LineageOS's MediaTek FMRadio talks to
# it directly; the stock app can't be reused, it needs Unihertz's framework (AServiceManager).
# Wired headphones act as the antenna.
PRODUCT_PACKAGES += \
    FMRadio

# Gatekeeper
# 🔴 OPEN: iKKO's tree uses their own from-scratch AIDL->HIDL bridge components here
# (gatekeeper-service.mindone, biometrics.fingerprint-service.mindone, secure_element-
# service.mindone, tetheroffload-service.mindone) — all removed, we have no equivalent.
# Whatever gatekeeper/fingerprint/secure-element HAL Jelly Star's vendor partition actually
# ships (likely a stock MediaTek or Unihertz blob, TBD) needs identifying during blob
# extraction, then wiring in as either a prebuilt blob or (if genuinely needed) our own
# bridge, following iKKO's bridges/ pattern as a reference if it comes to that.

# Graphics
PRODUCT_PACKAGES += \
    android.hardware.graphics.composer@2.3-service

# Health
PRODUCT_PACKAGES += \
    android.hardware.health-service.mediatek \
    android.hardware.health-service.mediatek-recovery

$(call inherit-product, hardware/lineage/compat/frameworks/compat.mk)
$(call inherit-product, hardware/mediatek/frameworks/mediatek-frameworks.mk)

# IMS / VoLTE: stock MediaTek ImsService (com.mediatek.ims, see the IMS section of
# proprietary-files.txt) on top of the stock vendor IMS stack (volte_imsm_93 etc.). Its only
# MediaTek dependency is mediatek-ims-base, which has to be on the boot classpath, as on stock.
# config_ims_mmtel_package already points at com.mediatek.ims (hardware/mediatek overlay).
PRODUCT_BOOT_JARS += \
    mediatek-ims-base

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/permissions/privapp-permissions-mediatek-ims.xml:$(TARGET_COPY_OUT_SYSTEM_EXT)/etc/permissions/privapp-permissions-mediatek-ims.xml \
    $(LOCAL_PATH)/configs/permissions/com.mediatek.ims.config.xml:$(TARGET_COPY_OUT_SYSTEM_EXT)/etc/sysconfig/com.mediatek.ims.config.xml

PRODUCT_PACKAGES += \
    TeleServiceJellystar

# ImsService loads the video telephony libraries (libmtk_vt_wrapper etc.) at startup; they need
# libhidltransport (not in the default system image) and libui_shim (libsource, see extract-files.py).
PRODUCT_PACKAGES += \
    libhidltransport \
    libui_shim

# ImsService registers receivers without RECEIVER_EXPORTED and would crash on Android 14+.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/appcompat/compat_framework_overrides.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/appcompat/compat_framework_overrides.xml

# VoLTE offered for every SIM (AOSP's carrier configs leave it off for most carriers), see the overlay.
PRODUCT_PACKAGES += \
    CarrierConfigJellystar

# Lights
PRODUCT_PACKAGES += \
    android.hardware.light-service.lineage

$(call soong_config_set_bool,lineagelight,snap_rgb_to_pure,true)

# Media
# 🔴 OPEN: iKKO's tree replaces the stock MediaTek OMX/C2 chain with the open V4L2 Codec2
# HAL (MINDONE_OWN_CODEC2, ~2300 lines of their own patches) — not carried over. Jelly Star
# uses the stock vendor OMX/C2 HAL via extracted blobs (camera/video already work on the
# GSI per the original brief, so no rewrite is expected to be needed here).
PRODUCT_COPY_FILES += \
    frameworks/av/media/libstagefright/data/media_codecs_google_c2_audio.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_c2_audio.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_c2_video.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_c2_video.xml

PRODUCT_PACKAGES += \
    mediacodec.policy \
    mediaextractor.policy \
    mediaswcodec.policy

# Memtrack
PRODUCT_PACKAGES += \
    android.hardware.memtrack-service.mediatek

# NFC — TMS chip (confirmed via live device inspection: android.hardware.nfc-service-tms,
# vendor.tms.tmsnfc_aidl AIDL HAL, /dev/tms_nfc, libnfc-tms*.conf config files), NOT NXP.
# This is the SystemServer-never-starts-NfcService bug's target — see memory for the
# confirmed root cause (no HAL issue; SystemServer just never attempts to start the
# mainline NFC service, unlike Bluetooth, on the GSI — needs the device manifest/feature
# XML to be present at first boot, not injected late by a Magisk-style overlay).
PRODUCT_PACKAGES += \
    android.hardware.nfc-service-tms

# libnfc-tms*.conf config files are extracted via proprietary-files.txt (vendor/etc/), not
# PRODUCT_COPY_FILES here — already populated, this used to be a stale 🔴 OPEN note.

# VINTF manifest fragment declaring android.hardware.nfc/INfc and vendor.tms.tmsnfc_aidl/
# ITmsNfc — pulled verbatim from the real stock vendor partition (see the Audio section
# above for how/why). This is directly load-bearing for the NFC bug this whole port exists
# to fix: without it, the framework has no VINTF-level declaration that these HAL instances
# exist at all, regardless of whether the service binary itself is present and running.
# `vintf_fragment` Soong module, not PRODUCT_COPY_FILES (modern AOSP rejects raw VINTF XML
# copy-files) — see device/unihertz/jellystar/vintf/manifest/Android.bp.
PRODUCT_PACKAGES += \
    nfc-service-tms.xml

# NFC feature declarations. Stock ships these in /system (not /vendor), and with the stock
# vendor partition used as a prebuilt anything we put under $(TARGET_COPY_OUT_VENDOR) never
# reaches the device. Without android.hardware.nfc the NfcNciApex disables itself at boot.
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.nfc.hce.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/android.hardware.nfc.hce.xml \
    frameworks/native/data/etc/android.hardware.nfc.uicc.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/android.hardware.nfc.uicc.xml \
    frameworks/native/data/etc/android.hardware.nfc.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/android.hardware.nfc.xml \
    frameworks/native/data/etc/com.nxp.mifare.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/com.nxp.mifare.xml

# Stock (TMS-tuned) NCI stack config, verbatim from stock /system/etc. libnfc-nci looks in
# /product before /system, so this overrides the generic AOSP libnfc-nci.conf-default.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/nfc/libnfc-nci.conf:$(TARGET_COPY_OUT_PRODUCT)/etc/libnfc-nci.conf

# Hide the stock placeholder face HAL; face unlock was a Unihertz framework feature.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/permissions/jellystar-unavailable-features.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/jellystar-unavailable-features.xml

# Power-off charging: start the stock health HAL in charger mode (see the rc for why).
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/init.jellystar.charger.rc:$(TARGET_COPY_OUT_SYSTEM_EXT)/etc/init/init.jellystar.charger.rc

# Key layouts: haptic feedback for the capacitive navigation keys, and the red shortcut key.
# In /system because the stock vendor partition has none for these devices.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/keylayout/cap_touch.kl:$(TARGET_COPY_OUT_SYSTEM)/usr/keylayout/cap_touch.kl \
    $(LOCAL_PATH)/keylayout/mtk-kpd.kl:$(TARGET_COPY_OUT_SYSTEM)/usr/keylayout/mtk-kpd.kl

# Back LED — Quick Settings tile + init glue, replacing Unihertz's framework-patched LED apps.
PRODUCT_PACKAGES += \
    JellyStarLedBelt

# Overlays
$(call inherit-product, hardware/mediatek/overlay/mssi.mk)

PRODUCT_ENFORCE_RRO_TARGETS := *

# Permissions — standard AOSP feature-declaration XML, platform-generic
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.audio.low_latency.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.audio.low_latency.xml \
    frameworks/native/data/etc/android.hardware.bluetooth_le.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth_le.xml \
    frameworks/native/data/etc/android.hardware.bluetooth.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth.xml \
    frameworks/native/data/etc/android.hardware.camera.flash-autofocus.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.flash-autofocus.xml \
    frameworks/native/data/etc/android.hardware.faketouch.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.faketouch.xml \
    frameworks/native/data/etc/android.hardware.fingerprint.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.fingerprint.xml \
    frameworks/native/data/etc/android.hardware.location.gps.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.location.gps.xml \
    frameworks/native/data/etc/android.hardware.opengles.aep.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.opengles.aep.xml \
    frameworks/native/data/etc/android.hardware.sensor.accelerometer.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.accelerometer.xml \
    frameworks/native/data/etc/android.hardware.sensor.compass.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.compass.xml \
    frameworks/native/data/etc/android.hardware.sensor.gyroscope.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.gyroscope.xml \
    frameworks/native/data/etc/android.hardware.sensor.light.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.light.xml \
    frameworks/native/data/etc/android.hardware.sensor.proximity.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.proximity.xml \
    frameworks/native/data/etc/android.hardware.sensor.stepcounter.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.stepcounter.xml \
    frameworks/native/data/etc/android.hardware.sensor.stepdetector.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.stepdetector.xml \
    frameworks/native/data/etc/android.hardware.se.omapi.uicc.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.se.omapi.uicc.xml \
    frameworks/native/data/etc/android.hardware.telephony.cdma.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.telephony.cdma.xml \
    frameworks/native/data/etc/android.hardware.telephony.gsm.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.telephony.gsm.xml \
    frameworks/native/data/etc/android.hardware.telephony.ims.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.telephony.ims.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.distinct.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.multitouch.distinct.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.multitouch.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.xml \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.accessory.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.host.xml \
    frameworks/native/data/etc/android.hardware.vulkan.compute-0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.compute.xml \
    frameworks/native/data/etc/android.hardware.vulkan.level-1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.level.xml \
    frameworks/native/data/etc/android.hardware.vulkan.version-1_1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.version.xml \
    frameworks/native/data/etc/android.hardware.wifi.direct.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.direct.xml \
    frameworks/native/data/etc/android.hardware.wifi.passpoint.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.passpoint.xml \
    frameworks/native/data/etc/android.hardware.wifi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.software.ipsec_tunnels.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.ipsec_tunnels.xml \
    frameworks/native/data/etc/android.software.midi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.midi.xml \
    frameworks/native/data/etc/android.software.opengles.deqp.level-2021-03-01.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.opengles.deqp.level.xml \
    frameworks/native/data/etc/android.software.verified_boot.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.verified_boot.xml \
    frameworks/native/data/etc/android.software.vulkan.deqp.level-2021-03-01.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.vulkan.deqp.level.xml \
    frameworks/native/data/etc/handheld_core_hardware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/handheld_core_hardware.xml

# Platform — ours, PROVEN: ro.board.platform=mt6789 (read from the device, 2026-09-29)
TARGET_BOARD_PLATFORM := mt6789

PRODUCT_PACKAGES += \
    android.hardware.power-service.lineage-libperfmgr \
    libmtkperf_client_vendor \
    libmtkperf_client \
    vendor.mediatek.hardware.mtkpower@1.2-service.stub

ENABLE_VENDOR_RIL_SERVICE := true

# Rootdir — ALL CONFIRMED REAL (2026-09-29): fstab.mt6789 pulled from the live device earlier
# this session; chipinfo and the 10 init.*.rc files below extracted directly from Jelly
# Star's own stock vendor partition (vendor/etc/init/hw/*, vendor/bin/chipinfo — via
# lpunpack+fsck.erofs from the local stock super.img); init.recovery.mt6789.rc extracted
# from the recovery ramdisk (vendor_ramdisk01 inside vendor_boot.img). See
# rootdir/Android.bp for the prebuilt_etc module definitions.
# iKKO's equivalent list also carries fstab.mt6789.vendor_ramdisk, ueventd.mt6789.rc, and
# init.connsys_drv.rc — checked all three against the vendor partition, boot ramdisk, AND
# recovery ramdisk; none exist anywhere on Jelly Star's real firmware, so dropped rather
# than invented (Jelly Star apparently relies on the generic system/etc/ueventd.rc instead
# of a device-specific ueventd.mt6789.rc).
#
# First-stage init reads fstab.${ro.hardware} from /first_stage_ramdisk before /vendor is
# mounted — confirmed by unpacking Jelly Star's own stock vendor_boot.img ramdisk
# (2026-10-01), which has first_stage_ramdisk/fstab.mt6789 there (byte-identical to the
# /vendor/etc copy below). Tried several Soong prebuilt_etc/prebuilt_root property
# combinations (vendor_ramdisk_available, install_in_root) and none landed the file at that
# exact path (either nested under vendor/ or at the bare ramdisk root, not inside a
# first_stage_ramdisk/ subdir) — a plain PRODUCT_COPY_FILES with an explicit destination is
# simple and known to work.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/fstab.mt6789:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk/fstab.mt6789

PRODUCT_PACKAGES += \
    chipinfo \
    fstab.mt6789 \
    init.aee.rc \
    init.cgroup.rc \
    init.connectivity.rc \
    init.connectivity.common.rc \
    init_connectivity.rc \
    init.modem.rc \
    init.mt6789.rc \
    init.mtkgki.rc \
    init.project.rc \
    init.sensor_2_0.rc

# Recovery init only reads /init.recovery.${ro.hardware}.rc from the ramdisk root; the
# prebuilt_etc module put it in /system/etc where it was ignored, so recovery never set
# sys.usb.controller and never appeared on USB (no adb sideload).
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/init.recovery.mt6789.rc:$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.mt6789.rc

PRODUCT_PACKAGES += \
    android.hardware.thermal-service.mediatek

# 🔴 OPEN: thermal_info_config.json — iKKO wrote their own; ours needs extracting from the
# device's actual /vendor/etc/thermal_info_config.json via proprietary-files.txt instead.

# ours, PROVEN: ro.product.first_api_level=33 (Android 13, matching the original shipped
# OS per the handoff brief), read from the device 2026-09-29. Kept even though the vendor
# partition itself now reports SDK 36 (ro.vendor.build.version.sdk=36) — Unihertz's OTA
# updated the vendor partition too, but first_api_level correctly still reflects what the
# device originally shipped with, which is what this property is for.
PRODUCT_SHIPPING_API_LEVEL := 33

# Development only: pre-authorize a local adb key (debug/adbkey.pub, a copy of
# ~/.android/adbkey.pub, gitignored) when building with JELLYSTAR_DEV_ADB_KEY=true. Never in
# builds for other people: it lets that key use adb on every phone without confirmation.
# Only honoured on userdebug/eng builds. Must be a source-tree-relative path (Soong's adb_keys
# module panics on absolute paths).
ifeq ($(JELLYSTAR_DEV_ADB_KEY),true)
ifneq ($(wildcard $(LOCAL_PATH)/debug/adbkey.pub),)
PRODUCT_ADB_KEYS := $(LOCAL_PATH)/debug/adbkey.pub
endif
endif
PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false

# Remote key provisioning: like stock (set there by Google's product config), so keystore gets
# its attestation keys from Google's provisioning server; the TEE's registration was uploaded at
# the factory (vendor.trustkernel.rkp.uploaded=true). Without it rkpd is disabled and keystore
# falls back to the factory attestation key.
PRODUCT_PRODUCT_PROPERTIES += \
    remote_provisioning.hostname=remoteprovisioning.googleapis.com

# Updater app: update list published with each release, see make-updater-json.sh. HEAD is the
# default branch; property values are limited to 91 bytes.
PRODUCT_SYSTEM_PROPERTIES += \
    lineage.updater.uri=https://raw.githubusercontent.com/osquera/lineageos_unihertz_jellystar/HEAD/updates.json

PRODUCT_SYSTEM_PROPERTIES += ro.telephony.sim.count=2

PRODUCT_SYSTEM_PROPERTIES += service.sf.prime_shader_cache=1

PRODUCT_SYSTEM_PROPERTIES += dalvik.vm.background-dex2oat-cpu-set=0,1,2,3,4,5
PRODUCT_SYSTEM_PROPERTIES += dalvik.vm.background-dex2oat-threads=3

# Bluetooth profiles — copied verbatim from stock /system/build.prop. Without them the BT stack
# only starts GATT/SAP/HearingAid, so headsets pair and then drop (no A2DP/HFP/AVRCP).
PRODUCT_SYSTEM_PROPERTIES += \
    bluetooth.profile.a2dp.source.enabled=true \
    bluetooth.profile.asha.central.enabled=true \
    bluetooth.profile.avrcp.target.enabled=true \
    bluetooth.profile.bas.client.enabled=true \
    bluetooth.profile.gatt.enabled=true \
    bluetooth.profile.hfp.ag.enabled=true \
    bluetooth.profile.hid.device.enabled=true \
    bluetooth.profile.hid.host.enabled=true \
    bluetooth.profile.map.server.enabled=true \
    bluetooth.profile.opp.enabled=true \
    bluetooth.profile.pan.nap.enabled=true \
    bluetooth.profile.pan.panu.enabled=true \
    bluetooth.profile.pbap.server.enabled=true \
    bluetooth.profile.sap.server.enabled=true

PRODUCT_HIDL_ENABLED := true
PRODUCT_PACKAGES += \
    hwservicemanager \
    vndservicemanager \
    vndservice \
    android.hidl.allocator@1.0-service \
    android.hidl.memory@1.0-impl

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH) \
    hardware/google/interfaces \
    hardware/google/pixel \
    hardware/lineage/interfaces/power-libperfmgr \
    hardware/mediatek \
    hardware/mediatek/libmtkperf_client

# USB
PRODUCT_PACKAGES += \
    android.hardware.usb-service.mediatek \
    android.hardware.usb.gadget-service.mediatek \
    init.mt6789.usb.rc

# Vibrator
# 🔴 OPEN: not yet confirmed which vibrator HAL generation Jelly Star's vendor blob uses
# (legacy vs AIDL) — legacy assumed as a starting point only.
PRODUCT_PACKAGES += \
    android.hardware.vibrator-service.legacy

# Wi-Fi
$(call soong_config_set_bool,mediatek_wifi_hal,use_pre_u_qpr2_struct,true)

PRODUCT_PACKAGES += \
    android.hardware.wifi-service \
    hostapd \
    libwifi-hal-wrapper \
    wlan_assistant \
    wpa_supplicant

# 🔴 OPEN: wifi conf overlay files (p2p_supplicant_overlay.conf, wpa_supplicant.conf,
# wpa_supplicant_overlay.conf) — iKKO authored their own under configs/wifi/; we don't have
# equivalents yet, so no PRODUCT_COPY_FILES for these until we write or extract them.

# Generated 2026-09-29 by extract-files.py against real device blobs.
$(call inherit-product, vendor/unihertz/jellystar/jellystar-vendor.mk)

PRODUCT_VENDOR_PROPERTIES += \
    ro.vendor.rc=/vendor/etc/init/hw/ \
    ro.vendor.init.sensor.rc=init.sensor_2_0.rc

PRODUCT_VENDOR_PROPERTIES += \
    persist.vendor.enable.thermal.genl=true

# ro.control_privapp_permissions is left at LineageOS's own default ("enforce",
# vendor/lineage/config/common.mk) — an earlier attempt to override it to "log" from
# lineage_jellystar.mk caused a "found duplicate sysprop assignments" build failure and was
# removed (2026-09-30); see that file for the full story. Not needed for either target bug.

# Framework config overlay, as a product RRO (see rro_overlays/FrameworksResJellystar/Android.bp).
PRODUCT_PACKAGES += \
    FrameworksResJellystar \
    LineageSdkJellystar

# ours, PROVEN: `adb shell wm size` / `dumpsys display` on the live device, 2026-09-29 ->
# 480x854 physical, density 220. Boot animation is generated sized to the screen by
# vendor/lineage/config/common.mk — without these set it falls back to a default 1080x1920,
# which would look wrong on a screen this small.
TARGET_SCREEN_WIDTH := 480
TARGET_SCREEN_HEIGHT := 854
