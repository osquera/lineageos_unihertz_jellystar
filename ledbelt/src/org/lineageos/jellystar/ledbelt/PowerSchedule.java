/*
 * SPDX-FileCopyrightText: 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.jellystar.ledbelt;

import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.SystemProperties;

import java.util.Calendar;

/**
 * Powers the phone on for alarms and on a schedule, and off on a schedule. The RTC's power-on
 * alarm switches the phone on from off and from power-off charging; it is armed at shutdown
 * (init runs jellystar_poweron for sys.jellystar.poweron) and cleared at boot.
 */
final class PowerSchedule {
    static final String KEY_ALARMS = "power_on_for_alarms";
    static final String KEY_SCHEDULE = "power_schedule";
    static final String KEY_OFF = "power_schedule_off";   // minutes after midnight
    static final String KEY_ON = "power_schedule_on";     // minutes after midnight
    static final String KEY_DAYS = "power_schedule_days"; // bit (Calendar.DAY_OF_WEEK - 1)
    static final int DEFAULT_OFF = 23 * 60;
    static final int DEFAULT_ON = 7 * 60;
    static final int ALL_DAYS = 0x7f;

    static final String ACTION_WARN = "org.lineageos.jellystar.ledbelt.action.POWER_OFF_WARN";
    static final String ACTION_OFF = "org.lineageos.jellystar.ledbelt.action.POWER_OFF";
    static final String ACTION_CANCEL = "org.lineageos.jellystar.ledbelt.action.POWER_OFF_CANCEL";

    /** Booting takes about 35 s; the alarm app needs to be running before its alarm. */
    private static final long ALARM_LEAD_MS = 2 * 60 * 1000;
    static final long WARN_MS = 60 * 1000;
    private static final String PROP = "sys.jellystar.poweron";

    private PowerSchedule() {}

    private static SharedPreferences prefs(Context context) {
        return LedBelt.prefs(context);
    }

    static boolean forAlarms(Context context) {
        return prefs(context).getBoolean(KEY_ALARMS, true);
    }

    static boolean scheduled(Context context) {
        return prefs(context).getBoolean(KEY_SCHEDULE, false);
    }

    static int offMinutes(Context context) {
        return prefs(context).getInt(KEY_OFF, DEFAULT_OFF);
    }

    static int onMinutes(Context context) {
        return prefs(context).getInt(KEY_ON, DEFAULT_ON);
    }

    static int days(Context context) {
        return prefs(context).getInt(KEY_DAYS, ALL_DAYS);
    }

    /** Next time at minutes after midnight on an enabled day, after now; 0 if no day is set. */
    static long next(int minutes, int days, long now) {
        if ((days & ALL_DAYS) == 0) return 0;
        Calendar c = Calendar.getInstance();
        c.setTimeInMillis(now);
        c.set(Calendar.HOUR_OF_DAY, minutes / 60);
        c.set(Calendar.MINUTE, minutes % 60);
        c.set(Calendar.SECOND, 0);
        c.set(Calendar.MILLISECOND, 0);
        for (int i = 0; i < 8; i++) {
            if (c.getTimeInMillis() > now
                    && (days & (1 << (c.get(Calendar.DAY_OF_WEEK) - 1))) != 0) {
                return c.getTimeInMillis();
            }
            c.add(Calendar.DAY_OF_MONTH, 1);
        }
        return 0;
    }

    /** When to power on after shutting down now, or 0. */
    static long nextPowerOn(Context context) {
        long now = System.currentTimeMillis();
        long when = 0;
        if (forAlarms(context)) {
            AlarmManager.AlarmClockInfo alarm =
                    context.getSystemService(AlarmManager.class).getNextAlarmClock();
            if (alarm != null) when = alarm.getTriggerTime() - ALARM_LEAD_MS;
        }
        if (scheduled(context)) {
            long on = next(onMinutes(context), days(context), now);
            if (on != 0 && (when <= now || on < when)) when = on;
        }
        // Too close to power off and on again: the shutdown itself takes a while.
        return when > now + 60 * 1000 ? when : 0;
    }

    /** At shutdown: arm the RTC for the next power-on. */
    static void onShutdown(Context context) {
        long when = nextPowerOn(context);
        SystemProperties.set(PROP, Long.toString(when / 1000));
    }

    /** At boot and when the settings change. */
    static void update(Context context) {
        SystemProperties.set(PROP, "0");
        AlarmManager am = context.getSystemService(AlarmManager.class);
        PendingIntent warn = pending(context, ACTION_WARN);
        am.cancel(warn);
        am.cancel(pending(context, ACTION_OFF));
        if (!scheduled(context)) return;
        long off = next(offMinutes(context), days(context),
                System.currentTimeMillis() + WARN_MS);
        if (off != 0) am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, off - WARN_MS, warn);
    }

    static PendingIntent pending(Context context, String action) {
        Intent intent = new Intent(action).setClass(context, PowerScheduleReceiver.class);
        return PendingIntent.getBroadcast(context, 0, intent,
                PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);
    }
}
