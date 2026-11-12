#!/vendor/bin/sh
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Development only (permissive test builds). If the boot hasn't completed after 180 s, writes a
# report (kernel log, boot properties, process list, logcat) as plain text into expdb at 64 MiB,
# then reboots so the bootloader retries the slot. The first 126 MiB of expdb are unused (the
# preloader and LK log to the last 2 MiB), and expdb can be read back from the other slot with dd.
# It reboots rather than panics: after a kernel exception, the stock vendor's AEE daemon on the
# other slot collects it from expdb and erases that area, report included. Each step has a timeout
# and the report is saved after each one, so a step that hangs can't keep the rest from being
# written. The expdb node is made from sysfs, so the report doesn't depend on ueventd having
# created /dev/block/by-name.

out=/dev/jellystar-boot-watchdog.txt
dev=/dev/jellystar-expdb

make_node() {
    [ -b $dev ] && return
    for u in /sys/class/block/*/uevent; do
        if grep -q '^PARTNAME=expdb$' $u; then
            mknod $dev b $(sed -n 's/^MAJOR=//p' $u) $(sed -n 's/^MINOR=//p' $u)
            return
        fi
    done
}

save() {
    make_node
    timeout 20 dd if=$out of=$dev bs=1048576 seek=64 conv=notrunc,fsync
}

echo "JSDBG-START uptime $(cat /proc/uptime)" > $out
save
sleep 180
[ "$(getprop sys.boot_completed)" = 1 ] && exit 0

{
    echo "=== boot not completed, uptime $(cat /proc/uptime)"
    echo "ro.cold_boot_done=$(getprop ro.cold_boot_done)"
    ls -la /dev/block/by-name 2>&1 | head -n 5
} >> $out
# Stacks of blocked tasks go to the kernel log.
echo w > /proc/sysrq-trigger
sleep 2
echo "=== dmesg" >> $out
timeout 20 dmesg >> $out 2>&1
save
echo "=== getprop" >> $out
timeout 20 getprop >> $out 2>&1
echo "=== ps" >> $out
timeout 20 ps -A -o PID,PPID,S,WCHAN,NAME >> $out 2>&1
save
echo "=== logcat" >> $out
timeout 20 /system/bin/logcat -d -b all >> $out 2>&1
echo "JSDBG-END" >> $out
save
sync
echo b > /proc/sysrq-trigger
