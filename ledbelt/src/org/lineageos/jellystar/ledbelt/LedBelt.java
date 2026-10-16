/*
 * SPDX-FileCopyrightText: 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.jellystar.ledbelt;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.SystemProperties;

/** Back LED state. The property is the live brightness (0 = off); prefs remember the "on" level. */
final class LedBelt {
    static final int MAX = 255;

    private static final String PROP = "persist.sys.jellystar.ledbelt";
    // Effects animate through a non-persistent property so they never write to flash.
    private static final String FX_PROP = "sys.jellystar.ledbelt.fx";
    private static final String PREFS = "ledbelt";
    private static final String KEY_LEVEL = "level";
    private static final int DEFAULT_LEVEL = 128;

    private LedBelt() {}

    static int getBrightness() {
        return SystemProperties.getInt(PROP, 0);
    }

    static boolean isOn() {
        return getBrightness() > 0;
    }

    static void setBrightness(int level) {
        SystemProperties.set(PROP, Integer.toString(Math.max(0, Math.min(MAX, level))));
    }

    /** Drives the LED directly for an effect frame; {@link #getBrightness} is left untouched. */
    static void setFrame(int level) {
        SystemProperties.set(FX_PROP, Integer.toString(Math.max(0, Math.min(MAX, level))));
    }

    static boolean isEffectEnabled(Context context, String key) {
        return prefs(context).getBoolean(key, true);
    }

    static void setEffectEnabled(Context context, String key, boolean enabled) {
        prefs(context).edit().putBoolean(key, enabled).apply();
    }

    static int getSavedLevel(Context context) {
        return prefs(context).getInt(KEY_LEVEL, DEFAULT_LEVEL);
    }

    static void saveLevel(Context context, int level) {
        if (level > 0) {
            prefs(context).edit().putInt(KEY_LEVEL, level).apply();
        }
    }

    private static SharedPreferences prefs(Context context) {
        return context.createDeviceProtectedStorageContext()
                .getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }
}
