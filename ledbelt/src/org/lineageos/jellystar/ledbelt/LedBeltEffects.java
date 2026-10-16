/*
 * SPDX-FileCopyrightText: 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.jellystar.ledbelt;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.os.PowerManager;

/**
 * Plays back LED effects by stepping the brightness. Priority: ringing > notification pulse >
 * charging breath. Effects never run while the steady light is on, and afterwards the steady
 * brightness is restored.
 */
final class LedBeltEffects {
    static final String KEY_NOTIFICATION = "fx_notification";
    static final String KEY_CHARGING = "fx_charging";
    static final String KEY_CALL = "fx_call";

    private static final long FRAME_MS = 50;
    private static final long BREATH_PERIOD_MS = 3000;
    private static final long CALL_BLINK_MS = 150;
    private static final long PULSE_ON_MS = 120;
    private static final long PULSE_OFF_MS = 180;
    private static final int PULSE_COUNT = 3;

    private static LedBeltEffects sInstance;

    private final Context mContext;
    private final Handler mHandler = new Handler(Looper.getMainLooper());
    private final PowerManager.WakeLock mWakeLock;

    private boolean mRinging;
    private boolean mCharging;
    private boolean mScreenOff;
    private int mPulseFramesLeft;
    private long mStartTime;
    private boolean mRunning;

    static synchronized LedBeltEffects get(Context context) {
        if (sInstance == null) {
            sInstance = new LedBeltEffects(context.getApplicationContext());
        }
        return sInstance;
    }

    private LedBeltEffects(Context context) {
        mContext = context;
        mWakeLock = context.getSystemService(PowerManager.class)
                .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "LedBelt:effects");
        mWakeLock.setReferenceCounted(false);
    }

    void setRinging(boolean ringing) {
        mRinging = ringing;
        update();
    }

    void setCharging(boolean charging) {
        mCharging = charging;
        update();
    }

    void setScreenOff(boolean screenOff) {
        mScreenOff = screenOff;
        update();
    }

    void pulse() {
        if (!mScreenOff || !LedBelt.isEffectEnabled(mContext, KEY_NOTIFICATION)) return;
        mPulseFramesLeft = PULSE_COUNT * 2;
        mStartTime = 0;
        update();
    }

    private boolean ringingActive() {
        return mRinging && LedBelt.isEffectEnabled(mContext, KEY_CALL);
    }

    private boolean chargingActive() {
        return mCharging && mScreenOff && LedBelt.isEffectEnabled(mContext, KEY_CHARGING);
    }

    private void update() {
        boolean wanted = !LedBelt.isOn()
                && (ringingActive() || mPulseFramesLeft > 0 || chargingActive());
        if (wanted && !mRunning) {
            mRunning = true;
            mWakeLock.acquire(10 * 60 * 1000L);
            mStartTime = android.os.SystemClock.uptimeMillis();
            mHandler.post(mFrame);
        } else if (!wanted && mRunning) {
            stop();
        }
    }

    private void stop() {
        mRunning = false;
        mPulseFramesLeft = 0;
        mHandler.removeCallbacks(mFrame);
        LedBelt.setFrame(LedBelt.getBrightness());
        mWakeLock.release();
    }

    private final Runnable mFrame = new Runnable() {
        @Override
        public void run() {
            if (!mRunning) return;
            if (LedBelt.isOn()) {
                stop();
                return;
            }
            int peak = LedBelt.getSavedLevel(mContext);
            long elapsed = android.os.SystemClock.uptimeMillis() - mStartTime;
            long next;
            if (ringingActive()) {
                LedBelt.setFrame((elapsed / CALL_BLINK_MS) % 2 == 0 ? LedBelt.MAX : 0);
                next = CALL_BLINK_MS;
            } else if (mPulseFramesLeft > 0) {
                boolean on = mPulseFramesLeft % 2 == 0;
                LedBelt.setFrame(on ? LedBelt.MAX : 0);
                mPulseFramesLeft--;
                next = on ? PULSE_ON_MS : PULSE_OFF_MS;
            } else if (chargingActive()) {
                double phase = (elapsed % BREATH_PERIOD_MS) / (double) BREATH_PERIOD_MS;
                double level = (1 - Math.cos(phase * 2 * Math.PI)) / 2;
                LedBelt.setFrame((int) Math.round(level * level * peak));
                next = FRAME_MS;
            } else {
                stop();
                return;
            }
            mHandler.postDelayed(this, next);
        }
    };
}
