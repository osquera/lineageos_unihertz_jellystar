/*
 * SPDX-FileCopyrightText: 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.jellystar.ledbelt;

import android.service.quicksettings.Tile;
import android.service.quicksettings.TileService;

public class LedBeltTileService extends TileService {
    @Override
    public void onStartListening() {
        updateTile();
    }

    @Override
    public void onClick() {
        LedBelt.setBrightness(LedBelt.isOn() ? 0 : LedBelt.getSavedLevel(this));
        updateTile();
    }

    private void updateTile() {
        Tile tile = getQsTile();
        if (tile == null) return;
        int brightness = LedBelt.getBrightness();
        tile.setState(brightness > 0 ? Tile.STATE_ACTIVE : Tile.STATE_INACTIVE);
        tile.setSubtitle(brightness > 0
                ? getString(R.string.brightness_percent, brightness * 100 / LedBelt.MAX)
                : getString(R.string.off));
        tile.updateTile();
    }
}
