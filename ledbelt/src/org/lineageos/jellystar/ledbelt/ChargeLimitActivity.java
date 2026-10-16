/*
 * SPDX-FileCopyrightText: 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.jellystar.ledbelt;

import android.app.Activity;
import android.os.Bundle;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.SeekBar;
import android.widget.Switch;
import android.widget.TextView;

/** Settings > Battery > Charge limit. */
public class ChargeLimitActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        int pad = (int) (16 * getResources().getDisplayMetrics().density);
        LinearLayout content = new LinearLayout(this);
        content.setOrientation(LinearLayout.VERTICAL);
        content.setPadding(pad, pad, pad, pad);

        Switch enabled = new Switch(this);
        enabled.setText(R.string.charge_limit_enable);
        enabled.setMinHeight(pad * 3);
        enabled.setChecked(ChargeLimit.isEnabled(this));
        content.addView(enabled);

        TextView value = new TextView(this);
        value.setPadding(0, pad, 0, 0);
        content.addView(value);

        SeekBar slider = new SeekBar(this);
        slider.setMin(ChargeLimit.MIN_LIMIT);
        slider.setMax(ChargeLimit.MAX_LIMIT);
        slider.setProgress(ChargeLimit.getLimit(this));
        content.addView(slider);
        value.setText(getString(R.string.charge_limit_value, slider.getProgress()));

        TextView help = new TextView(this);
        help.setText(R.string.charge_limit_help);
        help.setPadding(0, pad, 0, 0);
        content.addView(help);

        enabled.setOnCheckedChangeListener((v, checked) -> {
            FrontLed.prefs(this).edit().putBoolean(ChargeLimit.KEY_ENABLED, checked).apply();
            ChargeLimit.get(this).update();
        });
        slider.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar s, int progress, boolean fromUser) {
                value.setText(getString(R.string.charge_limit_value, progress));
            }

            @Override
            public void onStartTrackingTouch(SeekBar s) {}

            @Override
            public void onStopTrackingTouch(SeekBar s) {
                FrontLed.prefs(ChargeLimitActivity.this).edit()
                        .putInt(ChargeLimit.KEY_LIMIT, s.getProgress()).apply();
                ChargeLimit.get(ChargeLimitActivity.this).update();
            }
        });

        ScrollView scroll = new ScrollView(this);
        scroll.addView(content);
        setContentView(scroll);
        Insets.apply(scroll);
    }
}
