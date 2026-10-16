/*
 * SPDX-FileCopyrightText: 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.jellystar.ledbelt;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.SystemProperties;

/** Stops charging at a chosen level and resumes a few percent below it. */
final class ChargeLimit {
    static final String KEY_ENABLED = "charge_limit_enabled";
    static final String KEY_LIMIT = "charge_limit";
    static final int DEFAULT_LIMIT = 80;
    static final int MIN_LIMIT = 50;
    static final int MAX_LIMIT = 95;
    private static final int RESUME_BELOW = 5;
    private static final String PROP = "sys.jellystar.charge.pause";

    private static ChargeLimit sInstance;

    private final Context mContext;
    private int mLevel = 100;
    private boolean mPlugged;
    private boolean mPaused;

    static synchronized ChargeLimit get(Context context) {
        if (sInstance == null) sInstance = new ChargeLimit(context.getApplicationContext());
        return sInstance;
    }

    private ChargeLimit(Context context) {
        mContext = context;
    }

    static boolean isEnabled(Context context) {
        return FrontLed.prefs(context).getBoolean(KEY_ENABLED, false);
    }

    static int getLimit(Context context) {
        return FrontLed.prefs(context).getInt(KEY_LIMIT, DEFAULT_LIMIT);
    }

    void setBattery(int level, boolean plugged) {
        mLevel = level;
        mPlugged = plugged;
        update();
    }

    void update() {
        boolean pause;
        if (!mPlugged || !isEnabled(mContext)) {
            pause = false;
        } else if (mLevel >= getLimit(mContext)) {
            pause = true;
        } else if (mLevel <= getLimit(mContext) - RESUME_BELOW) {
            pause = false;
        } else {
            pause = mPaused; // in between: keep the current state
        }
        if (pause != mPaused || SystemProperties.get(PROP).isEmpty()) {
            mPaused = pause;
            SystemProperties.set(PROP, pause ? "1" : "0");
        }
    }
}
