/*
 * SPDX-FileCopyrightText: 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.jellystar.ledbelt;

import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.service.quicksettings.TileService;

/**
 * Toggles the back LED on {@link #ACTION_TOGGLE}, so key remapping apps (e.g. Key Mapper's
 * "Send intent" action) can bind it to the red shortcut key. Exported on purpose: the worst
 * another app can do with it is switch a light.
 */
public class LedBeltToggleReceiver extends BroadcastReceiver {
    static final String ACTION_TOGGLE = "org.lineageos.jellystar.ledbelt.action.TOGGLE";

    @Override
    public void onReceive(Context context, Intent intent) {
        if (!ACTION_TOGGLE.equals(intent.getAction())) return;
        LedBelt.setBrightness(LedBelt.isOn() ? 0 : LedBelt.getSavedLevel(context));
        TileService.requestListeningState(context,
                new ComponentName(context, LedBeltTileService.class));
    }
}
