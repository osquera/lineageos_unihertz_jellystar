/*
 * SPDX-FileCopyrightText: 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.jellystar.ledbelt;

import android.app.Activity;
import android.os.Bundle;
import android.os.SystemProperties;
import android.widget.LinearLayout;
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.ScrollView;
import android.widget.TextView;

/** Chooses what the red shortcut key does. Settings > System > Red button. */
public class RedKeyActivity extends Activity {
    private static final String[] ACTIONS = {
        KeyHandler.ACTION_APPS, KeyHandler.ACTION_TORCH, KeyHandler.ACTION_BACKLIGHT,
        KeyHandler.ACTION_CAMERA,
    };
    private static final int[] LABELS = {
        R.string.redkey_apps, R.string.redkey_torch, R.string.redkey_backlight,
        R.string.redkey_camera,
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        int pad = (int) (16 * getResources().getDisplayMetrics().density);
        LinearLayout content = new LinearLayout(this);
        content.setOrientation(LinearLayout.VERTICAL);
        content.setPadding(pad, pad, pad, pad);

        RadioGroup group = new RadioGroup(this);
        String current = SystemProperties.get(KeyHandler.PROP_ACTION, KeyHandler.ACTION_APPS);
        for (int i = 0; i < ACTIONS.length; i++) {
            RadioButton b = new RadioButton(this);
            b.setText(LABELS[i]);
            b.setId(i + 1);
            b.setMinHeight(pad * 3);
            group.addView(b);
            if (ACTIONS[i].equals(current)) b.setChecked(true);
        }
        group.setOnCheckedChangeListener((g, id) ->
                SystemProperties.set(KeyHandler.PROP_ACTION, ACTIONS[id - 1]));
        content.addView(group);

        TextView help = new TextView(this);
        help.setText(R.string.redkey_help);
        help.setPadding(0, pad, 0, 0);
        content.addView(help);

        ScrollView scroll = new ScrollView(this);
        scroll.addView(content);
        setContentView(scroll);
        Insets.apply(scroll);
    }
}
