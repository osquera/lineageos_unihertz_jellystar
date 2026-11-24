#!/vendor/bin/sh
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# MediaTek's bootloader saves a kernel crash dump (kedump) at the start of expdb. While it is
# there, the bootloader restores it into pstore on every boot and saves no new dumps. Stock's AEE
# daemon collects and clears it; we don't ship that, so keep a copy here and clear it.

expdb=/dev/block/by-name/expdb
out=/data/vendor/aee_exp

[ "$(od -An -tx1 -N4 "$expdb" | tr -d ' \n')" = "addee0ae" ] || exit 0

dd if="$expdb" bs=1M count=8 2>/dev/null | gzip > "$out/kedump-$(date +%Y%m%d-%H%M%S).bin.gz"
ls -t "$out"/kedump-*.bin.gz | tail -n +4 | xargs rm -f
printf '\0\0\0\0' | dd of="$expdb" bs=4 count=1 conv=notrunc 2>/dev/null
