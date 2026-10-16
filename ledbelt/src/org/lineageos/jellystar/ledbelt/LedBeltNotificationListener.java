/*
 * SPDX-FileCopyrightText: 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.jellystar.ledbelt;

import android.app.Notification;
import android.app.NotificationManager;
import android.service.notification.NotificationListenerService;
import android.service.notification.StatusBarNotification;

/** Back LED pulse and front LED colour for new, alerting notifications. */
public class LedBeltNotificationListener extends NotificationListenerService {
    @Override
    public void onNotificationPosted(StatusBarNotification sbn, RankingMap rankingMap) {
        Notification n = sbn.getNotification();
        if (sbn.isOngoing() || (n.flags & Notification.FLAG_GROUP_SUMMARY) != 0) {
            return;
        }
        Ranking ranking = new Ranking();
        if (rankingMap.getRanking(sbn.getKey(), ranking)
                && ranking.getImportance() < NotificationManager.IMPORTANCE_DEFAULT) {
            return;
        }
        LedBeltEffects.get(this).pulse();
        FrontLed.get(this).notificationPosted(sbn.getKey(), sbn.getPackageName());
    }

    @Override
    public void onNotificationRemoved(StatusBarNotification sbn) {
        FrontLed.get(this).notificationRemoved(sbn.getKey());
    }
}
