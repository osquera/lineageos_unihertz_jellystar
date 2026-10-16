/*
 * SPDX-FileCopyrightText: 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.jellystar.ledbelt;

import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.os.Handler;
import android.os.Looper;
import android.os.SystemProperties;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Drives the front RGB LED. Unread notifications (screen off) win over the battery state.
 * Colours are 0xRRGGBB; blinking is done by the LED chip itself.
 */
final class FrontLed {
    static final String KEY_NOTIF_ENABLED = "front_notif_enabled";
    static final String KEY_NOTIF_COLOR = "front_notif_color";
    static final String KEY_NOTIF_BLINK = "front_notif_blink";
    static final String KEY_BATTERY_ENABLED = "front_battery_enabled";
    static final String KEY_CHARGING_COLOR = "front_charging_color";
    static final String KEY_FULL_COLOR = "front_full_color";
    static final String KEY_LOW_COLOR = "front_low_color";
    private static final String APP_COLOR_PREFIX = "front_app_color_";

    static final String BLINK_SLOW = "slow";
    static final String BLINK_FAST = "fast";
    static final String BLINK_STEADY = "steady";

    private static final int LOW_LEVEL = 15;
    private static final int FULL_LEVEL = 90;
    private static final long PREVIEW_MS = 2500;

    private static FrontLed sInstance;

    private final Context mContext;
    private final Handler mHandler = new Handler(Looper.getMainLooper());
    private final Map<String, Integer> mUnread = new LinkedHashMap<>();
    private boolean mScreenOff;
    private boolean mCharging;
    private boolean mFull;
    private int mLevel = 100;
    private Integer mPreviewColor;
    private String mApplied;
    private int mCounter;

    static synchronized FrontLed get(Context context) {
        if (sInstance == null) sInstance = new FrontLed(context.getApplicationContext());
        return sInstance;
    }

    private FrontLed(Context context) {
        mContext = context;
    }

    Context context() {
        return mContext;
    }

    // --- Settings -------------------------------------------------------------------------

    static SharedPreferences prefs(Context context) {
        return context.createDeviceProtectedStorageContext()
                .getSharedPreferences("ledbelt", Context.MODE_PRIVATE);
    }

    static int getColor(Context context, String key) {
        int def = switch (key) {
            case KEY_NOTIF_COLOR -> 0x00FFFF;
            case KEY_FULL_COLOR -> 0x00FF00;
            case KEY_LOW_COLOR -> 0xFF0000;
            default -> 0xFF4000; // charging: orange
        };
        return prefs(context).getInt(key, def);
    }

    /** Per-app colour, or null for the default notification colour. */
    static Integer getAppColor(Context context, String pkg) {
        SharedPreferences p = prefs(context);
        String key = APP_COLOR_PREFIX + pkg;
        return p.contains(key) ? p.getInt(key, 0) : null;
    }

    static void setAppColor(Context context, String pkg, Integer color) {
        SharedPreferences.Editor e = prefs(context).edit();
        if (color == null) e.remove(APP_COLOR_PREFIX + pkg);
        else e.putInt(APP_COLOR_PREFIX + pkg, color);
        e.apply();
    }

    // --- State ----------------------------------------------------------------------------

    void setScreenOff(boolean screenOff) {
        mScreenOff = screenOff;
        if (!screenOff) mUnread.clear(); // seen
        update();
    }

    void setBattery(int level, boolean charging, boolean full) {
        mLevel = level;
        mCharging = charging;
        mFull = full;
        update();
    }

    void notificationPosted(String key, String pkg) {
        if (!mScreenOff) return;
        Integer color = getAppColor(mContext, pkg);
        mUnread.remove(key);
        mUnread.put(key, color != null ? color : getColor(mContext, KEY_NOTIF_COLOR));
        update();
    }

    void notificationRemoved(String key) {
        if (mUnread.remove(key) != null) update();
    }

    /** Shows a colour for a moment, e.g. while choosing it in settings. */
    void preview(int color) {
        mPreviewColor = color;
        mHandler.removeCallbacks(mEndPreview);
        mHandler.postDelayed(mEndPreview, PREVIEW_MS);
        update();
    }

    private final Runnable mEndPreview = () -> {
        mPreviewColor = null;
        update();
    };

    void update() {
        SharedPreferences p = prefs(mContext);
        int color = 0;
        String blink = BLINK_STEADY;
        if (mPreviewColor != null) {
            color = mPreviewColor;
        } else if (!mUnread.isEmpty() && p.getBoolean(KEY_NOTIF_ENABLED, true)) {
            Integer last = null;
            for (Integer c : mUnread.values()) last = c;
            color = last;
            blink = p.getString(KEY_NOTIF_BLINK, BLINK_SLOW);
        } else if (p.getBoolean(KEY_BATTERY_ENABLED, true)) {
            if (mFull || (mCharging && mLevel >= FULL_LEVEL)) {
                color = getColor(mContext, KEY_FULL_COLOR);
            } else if (mCharging) {
                color = getColor(mContext, KEY_CHARGING_COLOR);
            } else if (mLevel <= LOW_LEVEL) {
                color = getColor(mContext, KEY_LOW_COLOR);
                blink = BLINK_SLOW;
            }
        }
        apply(color, color == 0 ? BLINK_STEADY : blink);
    }

    private void apply(int color, String blink) {
        String state = Integer.toHexString(color) + "/" + blink;
        if (state.equals(mApplied)) return;
        mApplied = state;
        SystemProperties.set("sys.jellystar.fled.r", Integer.toString(Color.red(color)));
        SystemProperties.set("sys.jellystar.fled.g", Integer.toString(Color.green(color)));
        SystemProperties.set("sys.jellystar.fled.b", Integer.toString(Color.blue(color)));
        mCounter++;
        if (BLINK_STEADY.equals(blink)) {
            SystemProperties.set("sys.jellystar.fled.solid", Integer.toString(mCounter));
        } else {
            SystemProperties.set("sys.jellystar.fled.time",
                    BLINK_FAST.equals(blink) ? "3 1 3 3" : "6 0 6 4");
            SystemProperties.set("sys.jellystar.fled.blink", Integer.toString(mCounter));
        }
    }
}
