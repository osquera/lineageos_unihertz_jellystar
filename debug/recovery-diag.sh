#!/system/bin/sh
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Development only (permissive test builds). Recovery has no logcat or getprop and its USB may not
# come up, so this writes the kernel log (which includes init's errors), the USB gadget state and
# recovery's own log as plain text into expdb at 96 MiB, 60 s after recovery starts. Read it back
# from Android with dd. The boot watchdog uses 64 MiB; the preloader and LK log to the last 2 MiB.

out=/tmp/jellystar-recovery-diag.txt
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
    timeout 20 dd if=$out of=$dev bs=1048576 seek=96 conv=notrunc,fsync
}

sleep 60
{
    echo "JSRDIAG-START uptime $(cat /proc/uptime)"
    echo "=== udc"
    ls /sys/class/udc
    for f in state current_speed soft_connect function is_a_peripheral; do
        echo "$f=$(cat /sys/class/udc/musb-hdrc/$f 2>&1)"
    done
    echo "cmode=$(cat /sys/class/udc/musb-hdrc/device/cmode 2>&1)"
    echo "kernel_init_done=$(cat /sys/module/musb_hdrc/parameters/kernel_init_done 2>&1)"
    echo "=== configfs"
    echo "UDC=$(cat /config/usb_gadget/g1/UDC 2>&1)"
    ls -lR /config/usb_gadget 2>&1 | head -n 80
    echo "=== usb-ffs"
    ls -la /dev/usb-ffs/adb 2>&1
    echo "=== mounts"
    cat /proc/mounts
    echo "=== ps"
    timeout 20 ps -A -o PID,PPID,S,WCHAN,NAME 2>&1
    echo "=== recovery.log"
    tail -n 200 /tmp/recovery.log 2>&1
    echo "=== dmesg"
    timeout 20 dmesg 2>&1
    echo "JSRDIAG-END"
} > $out 2>&1
save
sync
