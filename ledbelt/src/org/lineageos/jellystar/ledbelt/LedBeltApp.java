/*
 * SPDX-FileCopyrightText: 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.jellystar.ledbelt;

import android.app.Application;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.BatteryManager;
import android.os.PowerManager;
import android.telephony.TelephonyManager;

/**
 * Persistent: watches screen, charger and phone state for the back LED effects, and arms the
 * power-on alarm at shutdown.
 */
public class LedBeltApp extends Application {
    @Override
    public void onCreate() {
        super.onCreate();
        LedBeltEffects fx = LedBeltEffects.get(this);

        boolean screenOff = !getSystemService(PowerManager.class).isInteractive();
        fx.setScreenOff(screenOff);

        IntentFilter filter = new IntentFilter();
        filter.addAction(Intent.ACTION_SCREEN_ON);
        filter.addAction(Intent.ACTION_SCREEN_OFF);
        filter.addAction(Intent.ACTION_BATTERY_CHANGED);
        filter.addAction(TelephonyManager.ACTION_PHONE_STATE_CHANGED);
        Intent battery = registerReceiver(new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                handle(fx, intent);
            }
        }, filter, RECEIVER_EXPORTED);
        if (battery != null) handle(fx, battery);

        PowerSchedule.update(this);
        registerReceiver(new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                PowerSchedule.onShutdown(context);
            }
        }, new IntentFilter(Intent.ACTION_SHUTDOWN), RECEIVER_EXPORTED);
    }

    private static void handle(LedBeltEffects fx, Intent intent) {
        switch (intent.getAction()) {
            case Intent.ACTION_SCREEN_ON -> fx.setScreenOff(false);
            case Intent.ACTION_SCREEN_OFF -> fx.setScreenOff(true);
            case Intent.ACTION_BATTERY_CHANGED -> {
                int status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1);
                fx.setCharging(status == BatteryManager.BATTERY_STATUS_CHARGING);
            }
            case TelephonyManager.ACTION_PHONE_STATE_CHANGED -> fx.setRinging(
                    TelephonyManager.EXTRA_STATE_RINGING.equals(
                            intent.getStringExtra(TelephonyManager.EXTRA_STATE)));
            default -> { }
        }
    }
}
