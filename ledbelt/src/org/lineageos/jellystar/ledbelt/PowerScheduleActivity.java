/*
 * SPDX-FileCopyrightText: 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.jellystar.ledbelt;

import android.app.Activity;
import android.app.TimePickerDialog;
import android.os.Bundle;
import android.text.format.DateFormat;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.Switch;
import android.widget.TextView;
import android.widget.ToggleButton;

import java.text.DateFormatSymbols;
import java.util.Calendar;

/** Settings > System > Power on and off. */
public class PowerScheduleActivity extends Activity {
    private int mPad;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        mPad = (int) (16 * getResources().getDisplayMetrics().density);
        LinearLayout content = new LinearLayout(this);
        content.setOrientation(LinearLayout.VERTICAL);
        content.setPadding(mPad, mPad, mPad, mPad);

        Switch alarms = new Switch(this);
        alarms.setText(R.string.power_on_alarms);
        alarms.setMinHeight(mPad * 3);
        alarms.setChecked(PowerSchedule.forAlarms(this));
        alarms.setOnCheckedChangeListener((v, checked) ->
                FrontLed.prefs(this).edit().putBoolean(PowerSchedule.KEY_ALARMS, checked).apply());
        content.addView(alarms);
        content.addView(text(R.string.power_on_alarms_help));

        Switch schedule = new Switch(this);
        schedule.setText(R.string.power_schedule_enable);
        schedule.setMinHeight(mPad * 3);
        schedule.setPadding(0, mPad, 0, 0);
        schedule.setChecked(PowerSchedule.scheduled(this));
        content.addView(schedule);

        LinearLayout details = new LinearLayout(this);
        details.setOrientation(LinearLayout.VERTICAL);
        details.addView(timeButton(R.string.power_schedule_off, PowerSchedule.KEY_OFF,
                PowerSchedule.offMinutes(this)));
        details.addView(timeButton(R.string.power_schedule_on, PowerSchedule.KEY_ON,
                PowerSchedule.onMinutes(this)));
        details.addView(dayRow());
        content.addView(details);
        setEnabled(details, schedule.isChecked());
        schedule.setOnCheckedChangeListener((v, checked) -> {
            FrontLed.prefs(this).edit().putBoolean(PowerSchedule.KEY_SCHEDULE, checked).apply();
            setEnabled(details, checked);
            PowerSchedule.update(this);
        });

        content.addView(text(R.string.power_schedule_help));

        ScrollView scroll = new ScrollView(this);
        scroll.addView(content);
        setContentView(scroll);
        Insets.apply(scroll);
    }

    private TextView text(int res) {
        TextView t = new TextView(this);
        t.setText(res);
        t.setPadding(0, mPad / 2, 0, 0);
        return t;
    }

    private Button timeButton(int label, String key, int minutes) {
        Button b = new Button(this);
        b.setAllCaps(false);
        b.setText(getString(label, format(minutes)));
        b.setOnClickListener(v -> new TimePickerDialog(this, (picker, h, m) -> {
            FrontLed.prefs(this).edit().putInt(key, h * 60 + m).apply();
            b.setText(getString(label, format(h * 60 + m)));
            PowerSchedule.update(this);
        }, FrontLed.prefs(this).getInt(key, minutes) / 60,
                FrontLed.prefs(this).getInt(key, minutes) % 60,
                DateFormat.is24HourFormat(this)).show());
        return b;
    }

    private String format(int minutes) {
        Calendar c = Calendar.getInstance();
        c.set(Calendar.HOUR_OF_DAY, minutes / 60);
        c.set(Calendar.MINUTE, minutes % 60);
        return DateFormat.getTimeFormat(this).format(c.getTime());
    }

    private LinearLayout dayRow() {
        LinearLayout row = new LinearLayout(this);
        String[] names = new DateFormatSymbols().getShortWeekdays();
        int first = Calendar.getInstance().getFirstDayOfWeek();
        for (int i = 0; i < 7; i++) {
            int day = (first - 1 + i) % 7 + 1; // Calendar.SUNDAY..SATURDAY
            int bit = 1 << (day - 1);
            ToggleButton t = new ToggleButton(this);
            t.setTextOn(names[day]);
            t.setTextOff(names[day]);
            t.setChecked((PowerSchedule.days(this) & bit) != 0);
            t.setOnCheckedChangeListener((v, checked) -> {
                int days = PowerSchedule.days(this);
                days = checked ? days | bit : days & ~bit;
                FrontLed.prefs(this).edit().putInt(PowerSchedule.KEY_DAYS, days).apply();
                PowerSchedule.update(this);
            });
            row.addView(t, new LinearLayout.LayoutParams(0,
                    LinearLayout.LayoutParams.WRAP_CONTENT, 1));
        }
        return row;
    }

    private static void setEnabled(android.view.View v, boolean enabled) {
        v.setEnabled(enabled);
        if (v instanceof android.view.ViewGroup g) {
            for (int i = 0; i < g.getChildCount(); i++) setEnabled(g.getChildAt(i), enabled);
        }
    }
}
