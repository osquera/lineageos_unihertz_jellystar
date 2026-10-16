/*
 * SPDX-FileCopyrightText: 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.jellystar.ledbelt;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.graphics.drawable.GradientDrawable;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import java.util.List;

/** Per-app notification colours for the front LED. */
public class AppColorsActivity extends Activity {
    private LinearLayout mList;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setTitle(R.string.front_app_colors);
        ScrollView scroll = new ScrollView(this);
        mList = new LinearLayout(this);
        mList.setOrientation(LinearLayout.VERTICAL);
        int pad = dp(16);
        mList.setPadding(pad, pad / 2, pad, pad / 2);
        scroll.addView(mList);
        setContentView(scroll);
        Insets.apply(scroll);
        populate();
    }

    private void populate() {
        mList.removeAllViews();
        TextView help = new TextView(this);
        help.setText(R.string.front_app_colors_help);
        help.setPadding(0, dp(8), 0, dp(16));
        mList.addView(help);
        PackageManager pm = getPackageManager();
        Intent launcher = new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER);
        List<ResolveInfo> apps = pm.queryIntentActivities(launcher, 0);
        apps.sort((a, b) -> a.loadLabel(pm).toString()
                .compareToIgnoreCase(b.loadLabel(pm).toString()));
        String last = null;
        for (ResolveInfo info : apps) {
            String pkg = info.activityInfo.packageName;
            if (pkg.equals(last)) continue;
            last = pkg;
            mList.addView(row(info.loadLabel(pm).toString(), pkg));
        }
    }

    private View row(String label, String pkg) {
        LinearLayout row = new LinearLayout(this);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setMinimumHeight(dp(48));
        TextView name = new TextView(this);
        name.setText(label);
        name.setLayoutParams(new LinearLayout.LayoutParams(0, -2, 1));
        row.addView(name);
        Integer color = FrontLed.getAppColor(this, pkg);
        TextView chip = new TextView(this);
        if (color == null) {
            chip.setText(R.string.front_app_default);
        } else {
            GradientDrawable d = new GradientDrawable();
            d.setShape(GradientDrawable.OVAL);
            d.setColor(0xFF000000 | color);
            chip.setBackground(d);
            chip.setLayoutParams(new LinearLayout.LayoutParams(dp(20), dp(20)));
        }
        row.addView(chip);
        row.setOnClickListener(v -> pick(label, pkg, color));
        return row;
    }

    private void pick(String label, String pkg, Integer current) {
        int[] chosen = {current != null ? current : -1};
        LinearLayout colors = ColorRow.create(this, chosen[0], c -> chosen[0] = c);
        colors.setPadding(dp(16), dp(8), dp(16), 0);
        new AlertDialog.Builder(this)
                .setTitle(label)
                .setView(colors)
                .setPositiveButton(android.R.string.ok, (d, w) -> {
                    if (chosen[0] >= 0) FrontLed.setAppColor(this, pkg, chosen[0]);
                    populate();
                })
                .setNeutralButton(R.string.front_app_default, (d, w) -> {
                    FrontLed.setAppColor(this, pkg, null);
                    populate();
                })
                .setNegativeButton(android.R.string.cancel, null)
                .show();
    }

    private int dp(int v) {
        return (int) (v * getResources().getDisplayMetrics().density);
    }
}
