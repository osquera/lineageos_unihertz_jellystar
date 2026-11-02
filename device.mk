#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Based on iasnezhkov/android_device_ikko_mindone (also MT6789).

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

# Audio: the HAL (android.hardware.audio.service-aidl.mediatek, audio.primary.mt6789.so) is
# a vendor blob.
PRODUCT_PACKAGES += \
    audio.r_submix.default \
    audio.usb.default

# The stock bluetooth_audio_policy_configuration.xml leaves the A2DP output mixPort without
# profiles, so AudioPolicyManager finds no device descriptor for APTX and the A2DP connection
# fails. This copy lists the codecs.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/audio/bluetooth_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/bluetooth_audio_policy_configuration.xml

# VINTF fragments for the stock audio and Bluetooth audio HAL services (vintf/manifest/).
PRODUCT_PACKAGES += \
    android.hardware.audio.service-aidl.mediatek.xml \
    android.hardware.audio.effect.service-aidl.xml \
    bluetooth_audio.mediatek.xml

# Bluetooth: VINTF fragment for the stock IBluetoothHci service
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

# NFC (TMS THN31)
PRODUCT_PACKAGES += \
    android.hardware.nfc-service-tms

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

# Face unlock: the stock vendor's face HAL needs Unihertz's framework, so hide the feature.
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

# Platform
TARGET_BOARD_PLATFORM := mt6789

PRODUCT_PACKAGES += \
    android.hardware.power-service.lineage-libperfmgr \
    libmtkperf_client_vendor \
    libmtkperf_client \
    vendor.mediatek.hardware.mtkpower@1.2-service.stub

ENABLE_VENDOR_RIL_SERVICE := true

# Rootdir: stock init scripts and fstab (rootdir/Android.bp). First-stage init reads the fstab
# from /first_stage_ramdisk in the vendor ramdisk, as on stock; no prebuilt_etc option installs
# it there, hence PRODUCT_COPY_FILES.
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

# Shipping API level (launched with Android 13)
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

# Proprietary
$(call inherit-product, vendor/unihertz/jellystar/jellystar-vendor.mk)

PRODUCT_VENDOR_PROPERTIES += \
    ro.vendor.rc=/vendor/etc/init/hw/ \
    ro.vendor.init.sensor.rc=init.sensor_2_0.rc

PRODUCT_VENDOR_PROPERTIES += \
    persist.vendor.enable.thermal.genl=true

# Framework, Lineage SDK and SystemUI overlays, as product RROs (see rro_overlays/*/Android.bp).
PRODUCT_PACKAGES += \
    FrameworksResJellystar \
    LineageSdkJellystar \
    SystemUIJellystar

# Screen size, for the boot animation
TARGET_SCREEN_WIDTH := 480
TARGET_SCREEN_HEIGHT := 854
