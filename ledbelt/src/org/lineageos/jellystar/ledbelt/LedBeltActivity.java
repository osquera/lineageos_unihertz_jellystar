/*
 * SPDX-FileCopyrightText: 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.jellystar.ledbelt;

import android.app.Activity;
import android.os.Bundle;
import android.widget.SeekBar;
import android.widget.Switch;

/** Back light settings; opened from Settings and by long-pressing the tile. */
public class LedBeltActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_ledbelt);
        Insets.apply(findViewById(android.R.id.content));

        SeekBar slider = findViewById(R.id.brightness);
        slider.setMax(LedBelt.MAX);
        slider.setProgress(LedBelt.isOn() ? LedBelt.getBrightness() : LedBelt.getSavedLevel(this));
        slider.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                if (!fromUser) return;
                LedBelt.setBrightness(progress);
                LedBelt.saveLevel(LedBeltActivity.this, progress);
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {}

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {}
        });

        bindSwitch(R.id.fx_notification, LedBeltEffects.KEY_NOTIFICATION);
        bindSwitch(R.id.fx_charging, LedBeltEffects.KEY_CHARGING);
        bindSwitch(R.id.fx_call, LedBeltEffects.KEY_CALL);

    }

    private void bindSwitch(int id, String key) {
        Switch view = findViewById(id);
        view.setChecked(LedBelt.isEffectEnabled(this, key));
        view.setOnCheckedChangeListener((v, checked) -> LedBelt.setEffectEnabled(this, key, checked));
    }
}
