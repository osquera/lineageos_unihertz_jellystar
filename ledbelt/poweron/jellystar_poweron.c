/*
 * SPDX-FileCopyrightText: 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

/*
 * Sets MediaTek's RTC power-on alarm, which switches the phone on from off (also from power-off
 * charging): jellystar_poweron <time in seconds since the epoch>. 0 clears it. Run by init for
 * the JellyStarLedBelt app, see init.jellystar.ledbelt.rc.
 */

#include <errno.h>
#include <fcntl.h>
#include <linux/rtc.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <time.h>
#include <unistd.h>

/* rtc-mt6397: a time in the future arms the power-on alarm, one in the past disables it. */
#define RTC_POFF_ALM_SET _IOW('p', 0x15, struct rtc_time)

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "usage: %s <epoch seconds, 0 to clear>\n", argv[0]);
        return 2;
    }

    time_t when = (time_t)strtoll(argv[1], NULL, 10);
    if (when <= 0) when = time(NULL) - 1;

    struct tm tm;
    if (!gmtime_r(&when, &tm)) return 2; /* the RTC runs in UTC */

    struct rtc_time alarm = {
        .tm_sec = tm.tm_sec,
        .tm_min = tm.tm_min,
        .tm_hour = tm.tm_hour,
        .tm_mday = tm.tm_mday,
        .tm_mon = tm.tm_mon,
        .tm_year = tm.tm_year,
    };

    int fd = open("/dev/rtc0", O_RDONLY | O_CLOEXEC);
    if (fd < 0) {
        fprintf(stderr, "open /dev/rtc0: %s\n", strerror(errno));
        return 1;
    }
    int ret = ioctl(fd, RTC_POFF_ALM_SET, &alarm);
    if (ret < 0) fprintf(stderr, "RTC_POFF_ALM_SET: %s\n", strerror(errno));
    close(fd);
    return ret < 0 ? 1 : 0;
}
