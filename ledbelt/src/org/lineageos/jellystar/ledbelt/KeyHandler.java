/*
 * SPDX-FileCopyrightText: 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.jellystar.ledbelt;

import android.app.KeyguardManager;
import android.content.Context;
import android.content.Intent;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraManager;
import android.os.Handler;
import android.os.Looper;
import android.os.PowerManager;
import android.os.SystemClock;
import android.os.SystemProperties;
import android.os.UserHandle;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.provider.MediaStore;
import android.util.Log;
import android.view.KeyEvent;

import com.android.internal.os.DeviceKeyHandler;

/**
 * Red shortcut key (scan code 249, PROG_RED). Loaded into system_server by PhoneWindowManager
 * through config_deviceKeyHandlerLibs/Classes; it sees the key before apps, even with the
 * screen off. The action is chosen in {@link RedKeyActivity}.
 */
public class KeyHandler implements DeviceKeyHandler {
    private static final String TAG = "JellyStarKeyHandler";
    // Runs in system_server, so the context's package is "android", not ours.
    private static final String PACKAGE = "org.lineageos.jellystar.ledbelt";

    static final String PROP_ACTION = "persist.sys.jellystar.redkey";
    static final String ACTION_APPS = "apps";
    static final String ACTION_TORCH = "torch";
    static final String ACTION_BACKLIGHT = "backlight";
    static final String ACTION_CAMERA = "camera";

    // With the screen off, wait this long for a proximity reading before acting anyway.
    private static final long PROXIMITY_TIMEOUT_MS = 400;

    private final Context mContext;
    private final Handler mHandler = new Handler(Looper.getMainLooper());
    private final CameraManager mCameraManager;
    private final SensorManager mSensorManager;
    private final Sensor mProximity;
    private String mTorchId;
    private boolean mTorchOn;

    public KeyHandler(Context context) {
        mContext = context;
        mCameraManager = context.getSystemService(CameraManager.class);
        mSensorManager = context.getSystemService(SensorManager.class);
        mProximity = mSensorManager.getDefaultSensor(Sensor.TYPE_PROXIMITY);
        mCameraManager.registerTorchCallback(new CameraManager.TorchCallback() {
            @Override
            public void onTorchModeChanged(String cameraId, boolean enabled) {
                if (cameraId.equals(mTorchId)) mTorchOn = enabled;
            }
        }, new Handler(Looper.getMainLooper()));
    }

    @Override
    public KeyEvent handleKeyEvent(KeyEvent event) {
        if (event.getKeyCode() != KeyEvent.KEYCODE_PROG_RED) return event;
        String action = SystemProperties.get(PROP_ACTION, ACTION_APPS);
        if (ACTION_APPS.equals(action)) return event;
        if (event.getAction() == KeyEvent.ACTION_DOWN && event.getRepeatCount() == 0) {
            if (mProximity != null
                    && !mContext.getSystemService(PowerManager.class).isInteractive()) {
                runUnlessInPocket(action);
            } else {
                runSafely(action);
            }
        }
        return null;
    }

    /**
     * Screen off: ignore the key if something covers the proximity sensor (pocket, bag), so an
     * accidental press can't leave the camera or flashlight running for hours.
     */
    private void runUnlessInPocket(String action) {
        boolean[] done = {false};
        SensorEventListener listener = new SensorEventListener() {
            @Override
            public void onSensorChanged(SensorEvent e) {
                if (done[0]) return;
                done[0] = true;
                mSensorManager.unregisterListener(this);
                mHandler.removeCallbacksAndMessages(this);
                if (e.values[0] >= mProximity.getMaximumRange()) runSafely(action);
                else Log.i(TAG, "Red key ignored: proximity sensor covered");
            }

            @Override
            public void onAccuracyChanged(Sensor sensor, int accuracy) {}
        };
        mSensorManager.registerListener(listener, mProximity, SensorManager.SENSOR_DELAY_FASTEST,
                mHandler);
        // No reading in time: act anyway rather than leave the key dead.
        mHandler.postAtTime(() -> {
            if (done[0]) return;
            done[0] = true;
            mSensorManager.unregisterListener(listener);
            runSafely(action);
        }, listener, SystemClock.uptimeMillis() + PROXIMITY_TIMEOUT_MS);
    }

    private void runSafely(String action) {
        try {
            run(action);
        } catch (Exception e) {
            Log.w(TAG, "Red key action " + action + " failed", e);
        }
    }

    private void run(String action) throws CameraAccessException {
        switch (action) {
            case ACTION_TORCH -> {
                String id = torchId();
                if (id != null) mCameraManager.setTorchMode(id, !mTorchOn);
            }
            case ACTION_BACKLIGHT -> mContext.sendBroadcastAsUser(
                    new Intent(LedBeltToggleReceiver.ACTION_TOGGLE).setPackage(PACKAGE),
                    UserHandle.CURRENT);
            case ACTION_CAMERA -> {
                boolean locked = mContext.getSystemService(KeyguardManager.class)
                        .isKeyguardLocked();
                mContext.getSystemService(PowerManager.class).wakeUp(SystemClock.uptimeMillis(),
                        PowerManager.WAKE_REASON_CAMERA_LAUNCH, TAG);
                mContext.startActivityAsUser(new Intent(locked
                                ? MediaStore.INTENT_ACTION_STILL_IMAGE_CAMERA_SECURE
                                : MediaStore.INTENT_ACTION_STILL_IMAGE_CAMERA)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK
                                | Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS),
                        UserHandle.CURRENT);
            }
            default -> {
                return;
            }
        }
        mContext.getSystemService(Vibrator.class).vibrate(
                VibrationEffect.createPredefined(VibrationEffect.EFFECT_CLICK));
    }

    private String torchId() throws CameraAccessException {
        if (mTorchId == null) {
            for (String id : mCameraManager.getCameraIdList()) {
                CameraCharacteristics c = mCameraManager.getCameraCharacteristics(id);
                Boolean flash = c.get(CameraCharacteristics.FLASH_INFO_AVAILABLE);
                Integer facing = c.get(CameraCharacteristics.LENS_FACING);
                if (Boolean.TRUE.equals(flash) && facing != null
                        && facing == CameraCharacteristics.LENS_FACING_BACK) {
                    mTorchId = id;
                    break;
                }
            }
        }
        return mTorchId;
    }
}
