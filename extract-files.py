#!/usr/bin/env -S PYTHONPATH=../../../tools/extract-utils python3
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Adapted from iasnezhkov/android_device_ikko_mindone (same MT6789/Helio G99 platform,
# same LineageOS 23/Android 16 target). The blob_fixups below that reference generic
# MediaTek BSP files (audio.primary.mt6789.so, GNSS/power/sensors AIDL soname mismatches,
# the KeyMint "trustkernel" TEE renaming block) are KEPT — they fix version mismatches
# between a shared MTK BSP generation and this AOSP tree, not anything iKKO-device-specific,
# and several of the exact filenames (audio.primary.mt6789.so in particular) are CONFIRMED
# present byte-for-byte on Jelly Star too via live device inspection this session.
#
# 🔴 REMOVED, not adapted: iKKO's own custom fixup functions (audio_param_tuning.py,
# camera_metastore_fixup.py, camerahalserver_instance_fixup.py, halsensor_poweron_fixup.py)
# — these patch specific bugs in THEIR camera sensor (IMX766) and THEIR speech tuning
# tables. We do not have Jelly Star's camera sensor identity yet, and blindly carrying
# these over would silently patch the wrong assumptions into our blobs. Revisit once our
# own blobs are extracted and we know whether equivalent bugs exist here.
#
# 🔴 NOT YET RUN — this script has not been executed against real device blobs. Every
# blob_fixup entry below needs re-validation once real Jelly Star blobs are extracted: keep
# what still applies, drop what doesn't, add what's newly needed. Treat this as a
# well-informed starting point, not a verified result.

from extract_utils.fixups_blob import (
    blob_fixup,
    blob_fixups_user_type,
)
from extract_utils.fixups_lib import (
    lib_fixups,
    lib_fixups_user_type,
)
from extract_utils.main import (
    ExtractUtils,
    ExtractUtilsModule,
)

namespace_imports = [
    'device/unihertz/jellystar',
    'hardware/mediatek',
    'hardware/mediatek/libmtkperf_client',
]


def lib_fixup_vendor_suffix(lib: str, partition: str, *args, **kwargs):
    return f'{lib}_{partition}' if partition == 'vendor' else None


lib_fixups: lib_fixups_user_type = {
    **lib_fixups,
    ('vendor.mediatek.hardware.videotelephony@1.0'): lib_fixup_vendor_suffix,
}

blob_fixups: blob_fixups_user_type = {
    'system_ext/lib64/libimsma.so': blob_fixup()
        .replace_needed('libsink.so', 'libsink-mtk.so'),
    'system_ext/lib64/libsink-mtk.so': blob_fixup()
        .fix_soname(),
    'system_ext/lib64/libsource.so': blob_fixup()
        .add_needed('libui_shim.so'),
    (
        'vendor/bin/hw/android.hardware.gnss-service.mediatek',
        'vendor/lib64/hw/android.hardware.gnss-impl-mediatek.so',
    ): blob_fixup()
        .replace_needed('android.hardware.gnss-V1-ndk_platform.so', 'android.hardware.gnss-V1-ndk.so'),
    (
        'vendor/lib/libcodec2_mtk_venc.so',
        'vendor/lib/libcodec2_mtk_vdec.so',
        'vendor/lib64/libcodec2_mtk_venc.so',
        'vendor/lib64/libcodec2_mtk_vdec.so',
    ): blob_fixup()
        .replace_needed('libformatter.so', 'libformatter_mtk.so'),
    (
        'vendor/lib/libformatter_mtk.so',
        'vendor/lib64/libformatter_mtk.so',
    ): blob_fixup()
        .fix_soname(),
    (
        'vendor/lib64/android.hardware.power-service-mediatek.so'
    ): blob_fixup()
        .replace_needed('android.hardware.power-V2-ndk_platform.so', 'android.hardware.power-V2-ndk.so'),
    (
        'vendor/lib64/hw/hwcomposer.mtk_common.so'
    ): blob_fixup()
        .add_needed('libprocessgroup_shim.so'),
    (
        'vendor/lib64/lib3a.flash.so',
        'vendor/lib64/lib3a.ae.stat.so',
        'vendor/lib64/lib3a.sensors.color.so',
        'vendor/lib64/lib3a.sensors.flicker.so',
    ): blob_fixup()
        .add_needed('liblog.so'),
    (
        'vendor/lib/libGsFace_ca.so',
        'vendor/lib64/libGsFace_ca.so',
    ): blob_fixup()
        .add_needed('libteec.so'),
    (
        'vendor/lib64/libcam.utils.sensorprovider.so',
    ): blob_fixup()
        .replace_needed('libsensorndkbridge.so', 'android.hardware.sensors@1.0-convert-shared.so'),
    (
        'vendor/lib64/libmnl_mtk.so'
    ): blob_fixup()
        .fix_soname()
        .add_needed('libcutils.so'),
    (
        'vendor/lib/libneuralnetworks_sl_driver_mtk_prebuilt.so',
        'vendor/lib64/libneuralnetworks_sl_driver_mtk_prebuilt.so',
    ): blob_fixup()
        .clear_symbol_version('AHardwareBuffer_allocate')
        .clear_symbol_version('AHardwareBuffer_describe')
        .clear_symbol_version('AHardwareBuffer_lock')
        .clear_symbol_version('AHardwareBuffer_release')
        .clear_symbol_version('AHardwareBuffer_unlock')
        .clear_symbol_version('AHardwareBuffer_createFromHandle')
        .clear_symbol_version('AHardwareBuffer_getNativeHandle'),
    (
        'vendor/bin/nfcstackp-vendor',
        'vendor/bin/STFlashTool',
        'vendor/lib/libnvram.so',
        'vendor/lib64/libnvram.so',
        'vendor/lib/libsysenv.so',
        'vendor/lib64/libsysenv.so',
    ): blob_fixup()
        .add_needed('libbase_shim.so'),
    (
        # 'vendor/lib64/hw/audio.primary.mt6789.so' — CONFIRMED present byte-for-byte on
        # Jelly Star too, via live device inspection 2026-09-29.
        'system_ext/lib64/libsink-mtk.so',
        'vendor/lib/libspeech_enh_lib.so',
        'vendor/lib64/libspeech_enh_lib.so',
        'vendor/lib64/libwifi-hal-mtk.so',
        'vendor/lib64/hw/sensors.mt6789.so',
        'vendor/lib/hw/audio.primary.mt6789.so',
        'vendor/lib64/hw/audio.primary.mt6789.so',
        'vendor/lib/hw/audio.r_submix.mt6789.so',
        'vendor/lib64/hw/audio.r_submix.mt6789.so',
    ): blob_fixup()
        .fix_soname(),
    # 🔴 The TEE keymint service block below (trustkernel V1-ndk renaming) is carried over
    # from iKKO on the theory that it's a generic MTK-BSP-era KeyMint mismatch, NOT yet
    # confirmed that Jelly Star's keymint blob is the same "trustkernel" TEE vendor — check
    # `adb shell su -c "find /vendor -iname '*keymint*'"` during extraction before assuming
    # this whole block applies.
    (
        'vendor/bin/hw/android.hardware.security.keymint-service.trustkernel'
    ): blob_fixup()
        .replace_needed('android.hardware.security.keymint-V1-ndk_platform.so', 'android.hardware.security.keymint-V1-ndk.so')
        .replace_needed('android.hardware.security.secureclock-V1-ndk_platform.so', 'android.hardware.security.secureclock-V1-ndk.so')
        .replace_needed('android.hardware.security.sharedsecret-V1-ndk_platform.so', 'android.hardware.security.sharedsecret-V1-ndk.so')
        .replace_needed('libkeymint.so', 'libkeymint_mtk.so')
        .replace_needed('libcppbor_external.so', 'libcppbor_external_mtk.so')
        .add_needed('android.hardware.security.rkp-V1-ndk.so'),
    (
        'vendor/lib64/libkeymint_mtk.so'
    ): blob_fixup()
        .fix_soname()
        .replace_needed('android.hardware.security.keymint-V1-ndk_platform.so', 'android.hardware.security.keymint-V1-ndk.so')
        .replace_needed('android.hardware.security.secureclock-V1-ndk_platform.so', 'android.hardware.security.secureclock-V1-ndk.so')
        .replace_needed('android.hardware.security.sharedsecret-V1-ndk_platform.so', 'android.hardware.security.sharedsecret-V1-ndk.so')
        .replace_needed('lib_android_keymaster_keymint_utils.so', 'lib_android_keymaster_keymint_utils_mtk.so')
        .replace_needed('libcppbor_external.so', 'libcppbor_external_mtk.so')
        .replace_needed('libkeymaster_messages.so', 'libkeymaster_messages_mtk.so')
        .replace_needed('libkeymaster_portable.so', 'libkeymaster_portable_mtk.so')
        .replace_needed('libpuresoftkeymasterdevice.so', 'libpuresoftkeymasterdevice_mtk.so'),
    (
        'vendor/lib64/lib_android_keymaster_keymint_utils_mtk.so'
    ): blob_fixup()
        .fix_soname()
        .replace_needed('android.hardware.security.keymint-V1-ndk_platform.so', 'android.hardware.security.keymint-V1-ndk.so'),
    (
        'vendor/lib64/libkeymaster_messages_mtk.so'
    ): blob_fixup()
        .fix_soname(),
    (
        'vendor/lib64/libkeymaster_portable_mtk.so'
    ): blob_fixup()
        .fix_soname()
        .replace_needed('libcppbor_external.so', 'libcppbor_external_mtk.so')
        .replace_needed('libcppcose_rkp.so', 'libcppcose_rkp_mtk.so'),
    (
        'vendor/lib64/libcppbor_external_mtk.so'
    ): blob_fixup()
        .fix_soname(),
    (
        'vendor/lib64/libcppcose_rkp_mtk.so'
    ): blob_fixup()
        .fix_soname()
        .replace_needed('libcppbor_external.so', 'libcppbor_external_mtk.so'),
    (
        'vendor/lib64/libpuresoftkeymasterdevice_mtk.so'
    ): blob_fixup()
        .fix_soname()
        .replace_needed('libkeymaster_messages.so', 'libkeymaster_messages_mtk.so')
        .replace_needed('libkeymaster_portable.so', 'libkeymaster_portable_mtk.so')
        .replace_needed('libsoft_attestation_cert.so', 'libsoft_attestation_cert_mtk.so')
        .replace_needed('libcppbor_external.so', 'libcppbor_external_mtk.so')
        .replace_needed('libcppcose_rkp.so', 'libcppcose_rkp_mtk.so'),
    (
        'vendor/lib64/libsoft_attestation_cert_mtk.so'
    ): blob_fixup()
        .fix_soname()
        .replace_needed('libkeymaster_portable.so', 'libkeymaster_portable_mtk.so'),
    (
        'vendor/bin/hw/android.hardware.media.c2@1.2-mediatek',
    ): blob_fixup()
        .replace_needed('libavservices_minijail_vendor.so', 'libavservices_minijail.so')
        .add_needed('libstagefright_foundation-v33.so'),
    (
        'vendor/bin/hw/mtkfusionrild',
        'vendor/lib/libmtkcam_stdutils.so',
        'vendor/lib64/libmtkcam_stdutils.so',
        'vendor/lib64/hw/android.hardware.camera.provider@2.6-impl-mediatek.so',
    ): blob_fixup()
        .add_needed('libutils-v32.so'),
    (
        'system_ext/lib64/libimsma.so',
    ): blob_fixup()
        .replace_needed('libsink.so', 'libsink-mtk.so'),
    (
        'system_ext/lib64/libsource.so',
    ): blob_fixup()
        .add_needed('libui_shim.so'),
    (
        'vendor/etc/sensors/hals.conf'
    ): blob_fixup()
        .regex_replace('android.hardware.sensors@2.X-subhal-mediatek.so', 'android.hardware.sensors@2.0-subhal-impl-1.0.so'),
    (
        # audio.primary.{mt6789,mediatek}.so were linked against older AIDL interface
        # versions (audio.effect V2, bluetooth.audio V4) than the rest of the vendor audio
        # stack (libpreprocessingaidl_mtk.so, libspatializeraidl.so, the AOSP
        # audio.effect.aidl-impl-mediatek.so, and libbluetooth_audio_session_aidl_mtk's own
        # bluetooth.audio-V5 dependency all use effect V3 / bluetooth.audio V5, which is also
        # what this AOSP branch's audio.effect version "3" declares as importing
        # (android.hardware.audio.common-V4 + android.media.audio.common.types-V4, matching
        # bluetooth.audio version "5"'s own imports) — confirmed 2026-09-29 by reading
        # hardware/interfaces/audio/aidl/Android.bp and hardware/interfaces/bluetooth/audio/
        # aidl/Android.bp directly. Soong refuses a single module's dependency graph mixing
        # two versions of the same aidl_interface, so bump these two blobs' DT_NEEDED
        # entries to match — AIDL NDK-backend binaries are designed to be backward
        # compatible, so a binary built against V2 loading a V3 implementation (etc.) is
        # expected to work correctly at runtime, this is purely a build-time version-pin fix.
        'vendor/lib/hw/audio.primary.mediatek.so',
        'vendor/lib64/hw/audio.primary.mediatek.so',
        'vendor/lib/hw/audio.primary.mt6789.so',
        'vendor/lib64/hw/audio.primary.mt6789.so',
    ): blob_fixup()
        .replace_needed('android.hardware.audio.effect-V2-ndk.so', 'android.hardware.audio.effect-V3-ndk.so')
        .replace_needed('android.hardware.bluetooth.audio-V4-ndk.so', 'android.hardware.bluetooth.audio-V5-ndk.so'),
}  # fmt: skip

module = ExtractUtilsModule(
    'jellystar',
    'unihertz',
    blob_fixups=blob_fixups,
    lib_fixups=lib_fixups,
    namespace_imports=namespace_imports,
    add_firmware_proprietary_file=True,
)

if __name__ == '__main__':
    utils = ExtractUtils.device(module)
    utils.run()
