/*
 * SPDX-FileCopyrightText: 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.jellystar.ledbelt;

import android.app.AlarmManager;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.PowerManager;
import android.telecom.TelecomManager;

/** Scheduled power off: a warning with Cancel, then shutdown a minute later. */
public class PowerScheduleReceiver extends BroadcastReceiver {
    private static final String CHANNEL = "power_schedule";
    private static final int NOTIFICATION_ID = 1;

    @Override
    public void onReceive(Context context, Intent intent) {
        NotificationManager nm = context.getSystemService(NotificationManager.class);
        switch (String.valueOf(intent.getAction())) {
            case PowerSchedule.ACTION_WARN -> {
                nm.createNotificationChannel(new NotificationChannel(CHANNEL,
                        context.getString(R.string.power_schedule_title),
                        NotificationManager.IMPORTANCE_HIGH));
                nm.notify(NOTIFICATION_ID, new Notification.Builder(context, CHANNEL)
                        .setSmallIcon(R.drawable.ic_power)
                        .setContentTitle(context.getString(R.string.power_off_warning))
                        .setOngoing(true)
                        .setTimeoutAfter(PowerSchedule.WARN_MS)
                        .addAction(new Notification.Action.Builder(null,
                                context.getString(android.R.string.cancel),
                                PowerSchedule.pending(context, PowerSchedule.ACTION_CANCEL))
                                .build())
                        .build());
                context.getSystemService(AlarmManager.class).setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        System.currentTimeMillis() + PowerSchedule.WARN_MS,
                        PowerSchedule.pending(context, PowerSchedule.ACTION_OFF));
            }
            case PowerSchedule.ACTION_OFF -> {
                nm.cancel(NOTIFICATION_ID);
                if (context.getSystemService(TelecomManager.class).isInCall()) {
                    PowerSchedule.update(context); // skip today, keep the schedule
                    return;
                }
                context.getSystemService(PowerManager.class)
                        .shutdown(false, "scheduled", false);
            }
            case PowerSchedule.ACTION_CANCEL -> {
                nm.cancel(NOTIFICATION_ID);
                PowerSchedule.update(context);
            }
            default -> { }
        }
    }
}
