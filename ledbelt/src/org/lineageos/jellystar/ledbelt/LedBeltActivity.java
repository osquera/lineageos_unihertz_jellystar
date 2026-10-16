/*
 * SPDX-FileCopyrightText: 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.jellystar.ledbelt;

import android.app.Activity;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.SeekBar;
import android.widget.Switch;
import android.widget.TextView;

/** Back and front light settings; opened from Settings and by long-pressing the tile. */
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

        buildFrontSection(findViewById(R.id.front_container));
    }

    private void buildFrontSection(LinearLayout c) {
        SharedPreferences p = FrontLed.prefs(this);
        FrontLed led = FrontLed.get(this);

        c.addView(frontSwitch(R.string.front_notifications, FrontLed.KEY_NOTIF_ENABLED));
        c.addView(label(R.string.front_default_color));
        c.addView(ColorRow.create(this, FrontLed.getColor(this, FrontLed.KEY_NOTIF_COLOR),
                col -> p.edit().putInt(FrontLed.KEY_NOTIF_COLOR, col).apply()));

        c.addView(label(R.string.front_blink));
        RadioGroup blink = new RadioGroup(this);
        blink.setOrientation(RadioGroup.HORIZONTAL);
        String current = p.getString(FrontLed.KEY_NOTIF_BLINK, FrontLed.BLINK_SLOW);
        String[] values = {FrontLed.BLINK_SLOW, FrontLed.BLINK_FAST, FrontLed.BLINK_STEADY};
        int[] labels = {R.string.front_blink_slow, R.string.front_blink_fast,
                R.string.front_blink_steady};
        for (int i = 0; i < values.length; i++) {
            RadioButton b = new RadioButton(this);
            b.setText(labels[i]);
            b.setId(i + 1);
            blink.addView(b);
            if (values[i].equals(current)) b.setChecked(true);
        }
        blink.setOnCheckedChangeListener((g, id) ->
                p.edit().putString(FrontLed.KEY_NOTIF_BLINK, values[id - 1]).apply());
        c.addView(blink);

        Button apps = new Button(this);
        apps.setText(R.string.front_app_colors);
        apps.setOnClickListener(v -> startActivity(new Intent(this, AppColorsActivity.class)));
        c.addView(apps);

        c.addView(frontSwitch(R.string.front_battery, FrontLed.KEY_BATTERY_ENABLED));
        c.addView(label(R.string.front_charging_color));
        c.addView(ColorRow.create(this, FrontLed.getColor(this, FrontLed.KEY_CHARGING_COLOR),
                col -> p.edit().putInt(FrontLed.KEY_CHARGING_COLOR, col).apply()));
        c.addView(label(R.string.front_full_color));
        c.addView(ColorRow.create(this, FrontLed.getColor(this, FrontLed.KEY_FULL_COLOR),
                col -> p.edit().putInt(FrontLed.KEY_FULL_COLOR, col).apply()));
        c.addView(label(R.string.front_low_color));
        c.addView(ColorRow.create(this, FrontLed.getColor(this, FrontLed.KEY_LOW_COLOR),
                col -> p.edit().putInt(FrontLed.KEY_LOW_COLOR, col).apply()));
    }

    private Switch frontSwitch(int text, String key) {
        Switch s = new Switch(this);
        s.setText(text);
        s.setMinHeight((int) (48 * getResources().getDisplayMetrics().density));
        s.setChecked(FrontLed.prefs(this).getBoolean(key, true));
        s.setOnCheckedChangeListener((v, checked) -> {
            FrontLed.prefs(this).edit().putBoolean(key, checked).apply();
            FrontLed.get(this).update();
        });
        return s;
    }

    private TextView label(int text) {
        TextView t = new TextView(this);
        t.setText(text);
        t.setPadding(0, (int) (8 * getResources().getDisplayMetrics().density), 0, 0);
        return t;
    }

    private void bindSwitch(int id, String key) {
        Switch view = findViewById(id);
        view.setChecked(LedBelt.isEffectEnabled(this, key));
        view.setOnCheckedChangeListener((v, checked) -> LedBelt.setEffectEnabled(this, key, checked));
    }
}
