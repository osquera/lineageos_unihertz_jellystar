#!/usr/bin/env -S PYTHONPATH=../../../tools/extract-utils python3
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Based on iasnezhkov/android_device_ikko_mindone (also MT6789).

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
]


def lib_fixup_vendor_suffix(lib: str, partition: str, *args, **kwargs):
    return f'{lib}_{partition}' if partition == 'vendor' else None


lib_fixups: lib_fixups_user_type = {
    **lib_fixups,
    (
        'vendor.mediatek.hardware.videotelephony@1.0',
        'vendor.mediatek.hardware.videotelephony-V1-ndk',
    ): lib_fixup_vendor_suffix,
}

blob_fixups: blob_fixups_user_type = {
    # libsink.so clashes with a framework library, so it is installed as libsink-mtk.so.
    'system_ext/lib64/libimsma.so': blob_fixup()
        .replace_needed('libsink.so', 'libsink-mtk.so'),
    (
        'system_ext/lib64/libsink-mtk.so',
        'vendor/lib/libaudioutils-mtk.so',
        'vendor/lib64/libaudioutils-mtk.so',
        'vendor/lib/libtinyxml2-mtk.so',
        'vendor/lib64/libtinyxml2-mtk.so',
        'vendor/lib/libexpat-mtk.so',
        'vendor/lib64/libexpat-mtk.so',
        # Loaded by hardware/mediatek's libwifi-hal-wrapper under this name.
        'vendor/lib64/libwifi-hal-mtk.so',
        # SONAME libspeech_enh.so, not the file name.
        'vendor/lib/libspeech_enh_lib.so',
        'vendor/lib64/libspeech_enh_lib.so',
    ): blob_fixup()
        .fix_soname(),
    # The stock audio stack needs stock's libaudioutils (newer than the one built here, e.g. for
    # audio_utils::mutex_get_enable_flag), installed as libaudioutils-mtk.so.
    (
        'vendor/bin/factory',
        'vendor/bin/hw/android.hardware.audio.service-aidl.mediatek',
        'vendor/lib/android.hardware.audio.core-impl-mediatek.so',
        'vendor/lib/libmtkspparser.so',
        'vendor/lib/libmtkspparser_swb.so',
        'vendor/lib/libspeechparser_vendor.so',
        'vendor/lib/soundfx/libaecsw_mtk.so',
        'vendor/lib/soundfx/libagc1sw_mtk.so',
        'vendor/lib/soundfx/libagc2sw_mtk.so',
        'vendor/lib/soundfx/libnssw_mtk.so',
        'vendor/lib/soundfx/libpreprocessingaidl_mtk.so',
        'vendor/lib/soundfx/libspatializer.so',
        'vendor/lib/soundfx/libspatializeraidl.so',
        'vendor/lib64/android.hardware.audio.core-impl-mediatek.so',
        'vendor/lib64/hw/android.hardware.audio.effect.aidl-impl-mediatek.so',
        'vendor/lib64/libmtkspparser.so',
        'vendor/lib64/libmtkspparser_swb.so',
        'vendor/lib64/libspeechparser_vendor.so',
        'vendor/lib64/soundfx/libaecsw_mtk.so',
        'vendor/lib64/soundfx/libagc1sw_mtk.so',
        'vendor/lib64/soundfx/libagc2sw_mtk.so',
        'vendor/lib64/soundfx/libnssw_mtk.so',
        'vendor/lib64/soundfx/libpreprocessingaidl_mtk.so',
        'vendor/lib64/soundfx/libspatializer.so',
        'vendor/lib64/soundfx/libspatializeraidl.so',
    ): blob_fixup()
        .replace_needed('libaudioutils.so', 'libaudioutils-mtk.so'),
    (
        'vendor/lib64/libneuralnetworks_sl_driver_mtk_prebuilt.so',
    ): blob_fixup()
        .clear_symbol_version('AHardwareBuffer_allocate')
        .clear_symbol_version('AHardwareBuffer_describe')
        .clear_symbol_version('AHardwareBuffer_lock')
        .clear_symbol_version('AHardwareBuffer_release')
        .clear_symbol_version('AHardwareBuffer_unlock')
        .clear_symbol_version('AHardwareBuffer_createFromHandle')
        .clear_symbol_version('AHardwareBuffer_getNativeHandle'),
    # camera.common V2 is not frozen in this tree. The library only uses types that V1 has.
    'vendor/lib64/mt6789/libmtkcam_hal_aidl_common.so': blob_fixup()
        .replace_needed('android.hardware.camera.common-V2-ndk.so', 'android.hardware.camera.common-V1-ndk.so'),
    # Soong does not allow two versions of one AIDL interface in a dependency graph. These also
    # reach sensors V3 (sensorservice, libsensorndkbridge).
    (
        'vendor/bin/mnld',
        'vendor/lib64/mt6789/libcam.utils.sensorprovider.so',
    ): blob_fixup()
        .replace_needed('android.hardware.sensors-V2-ndk.so', 'android.hardware.sensors-V3-ndk.so'),
    # The graphics interfaces in this tree (allocator V2, composer3) import graphics.common V7,
    # which only adds a PixelFormat value.
    'vendor/lib64/mt6789/libmtkcam_grallocutils.so': blob_fixup()
        .replace_needed('android.hardware.graphics.common-V5-ndk.so', 'android.hardware.graphics.common-V7-ndk.so'),
    (
        'vendor/bin/hw/mt6789/android.hardware.graphics.allocator-V2-service-mediatek.mt6789',
        'vendor/lib/hw/mt6789/android.hardware.graphics.allocator-V2-mediatek.so',
        'vendor/lib/hw/mt6789/mapper.mediatek.so',
        'vendor/lib/libcodec2_fsr.so',
        'vendor/lib/libgpud.so',
        'vendor/lib/vendor.mediatek.hardware.pq_aidl-V7-ndk.so',
        'vendor/lib64/hw/mt6789/android.hardware.graphics.allocator-V2-mediatek.so',
        'vendor/lib64/hw/mt6789/mapper.mediatek.so',
        'vendor/lib64/libaimemc.so',
        'vendor/lib64/libcodec2_fsr.so',
        'vendor/lib64/libcodec2_vpp_AIMEMC_plugin.so',
        'vendor/lib64/libcodec2_vpp_AISR_plugin.so',
        'vendor/lib64/libgpud.so',
        'vendor/lib64/vendor.mediatek.hardware.camera.isphal-V1-ndk.so',
        'vendor/lib64/vendor.mediatek.hardware.pq_aidl-V7-ndk.so',
    ): blob_fixup()
        .replace_needed('android.hardware.graphics.common-V6-ndk.so', 'android.hardware.graphics.common-V7-ndk.so'),
    # The rest of the audio stack uses audio.effect V3 and bluetooth.audio V5.
    (
        'vendor/lib/hw/audio.primary.mediatek.so',
        'vendor/lib64/hw/audio.primary.mediatek.so',
    ): blob_fixup()
        .replace_needed('android.hardware.audio.effect-V2-ndk.so', 'android.hardware.audio.effect-V3-ndk.so')
        .replace_needed('android.hardware.bluetooth.audio-V4-ndk.so', 'android.hardware.bluetooth.audio-V5-ndk.so')
        .replace_needed('libaudioutils.so', 'libaudioutils-mtk.so')
        .replace_needed('libtinyxml2.so', 'libtinyxml2-mtk.so'),
    # Stock's libtinyxml2 has a different object layout from the one built here (same symbols):
    # stock blobs that keep tinyxml2 objects on their stack crash with ours. Installed as
    # libtinyxml2-mtk.so.
    (
        'vendor/lib/hw/sunwave.fingerprint.default.so',
        'vendor/lib/libfrsm_extamp_intf.so',
        'vendor/lib/libmtkgpuserv.so',
        'vendor/lib/libpqxmlflagparser.so',
        'vendor/lib/libpqxmlparser.so',
        'vendor/lib/librt_extamp_intf.so',
        'vendor/lib/libsilkybrightnesscore.so',
        'vendor/lib64/hw/android.hardware.audio.effect.aidl-impl-mediatek.so',
        'vendor/lib64/hw/sunwave.fingerprint.default.so',
        'vendor/lib64/libfrsm_extamp_intf.so',
        'vendor/lib64/libmtkgpuserv.so',
        'vendor/lib64/libpqxmlflagparser.so',
        'vendor/lib64/libpqxmlparser.so',
        'vendor/lib64/librt_extamp_intf.so',
        'vendor/lib64/libsilkybrightnesscore.so',
    ): blob_fixup()
        .replace_needed('libtinyxml2.so', 'libtinyxml2-mtk.so'),
    # Same for libexpat (the stock power stack and fpsgo looped with ours): installed as
    # libexpat-mtk.so.
    (
        'vendor/bin/fpsgo',
        'vendor/bin/mtk_agpsd',
        'vendor/bin/touch_boost',
        'vendor/lib/libcodec2_mtk_c2store.so',
        'vendor/lib/libcodec2_mtk_vdec.so',
        'vendor/lib/libcodec2_mtk_venc.so',
        'vendor/lib/libperfctl_vendor.so',
        'vendor/lib64/libcodec2_mtk_c2store.so',
        'vendor/lib64/libcodec2_mtk_vdec.so',
        'vendor/lib64/libcodec2_mtk_venc.so',
        'vendor/lib64/libperfctl_vendor.so',
        'vendor/lib64/mt6789/libstereoinfoaccessor_vsdof.so',
    ): blob_fixup()
        .replace_needed('libexpat.so', 'libexpat-mtk.so'),
    (
        'vendor/lib/lib_power_applist.so',
        'vendor/lib/libpowerhal.so',
        'vendor/lib64/lib_power_applist.so',
        'vendor/lib64/libpowerhal.so',
    ): blob_fixup()
        .replace_needed('libexpat.so', 'libexpat-mtk.so')
        .replace_needed('libtinyxml2.so', 'libtinyxml2-mtk.so'),
    (
        'vendor/lib/hw/hwcomposer.mtk_common.so',
        'vendor/lib64/hw/hwcomposer.mtk_common.so',
    ): blob_fixup()
        .replace_needed('android.hardware.graphics.common-V6-ndk.so', 'android.hardware.graphics.common-V7-ndk.so')
        .replace_needed('libtinyxml2.so', 'libtinyxml2-mtk.so'),
    (
        'vendor/lib/hw/mt6789/vendor.mediatek.hardware.pq_aidl-impl.so',
        'vendor/lib64/hw/mt6789/vendor.mediatek.hardware.pq_aidl-impl.so',
    ): blob_fixup()
        .replace_needed('android.hardware.sensors-V2-ndk.so', 'android.hardware.sensors-V3-ndk.so')
        .replace_needed('libtinyxml2.so', 'libtinyxml2-mtk.so'),
    # hardware/mediatek builds different HALs at these paths, so the stock ones are installed
    # with a -stock suffix.
    (
        'vendor/etc/init/memtrack-mediatek-stock.rc',
        'vendor/etc/init/thermal-mediatek.rc',
        'vendor/etc/init/vibrator-mtk-default.rc',
    ): blob_fixup()
        .regex_replace(r'(?m)(/vendor/bin/hw/android\.hardware\.\w+-service\.mediatek)$', r'\1-stock'),
    # The stock fingerprint service loads the sunwave/chipsailing modules; AOSP's default one,
    # which owns the original path, only looks for "fingerprint".
    'vendor/etc/init/android.hardware.biometrics.fingerprint@2.1-service-stock.rc': blob_fixup()
        .regex_replace(r'(/vendor/bin/hw/android\.hardware\.biometrics\.fingerprint@2\.1-service)\b', r'\1-stock'),
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
