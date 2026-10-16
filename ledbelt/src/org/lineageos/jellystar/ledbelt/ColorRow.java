/*
 * SPDX-FileCopyrightText: 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.jellystar.ledbelt;

import android.content.Context;
import android.graphics.drawable.GradientDrawable;
import android.view.View;
import android.widget.LinearLayout;

import java.util.function.IntConsumer;

/** A row of colour swatches. Picking one previews it on the front LED. */
final class ColorRow {
    static final int[] COLORS = {
        0xFF0000, 0xFF4000, 0xFFA000, 0x00FF00, 0x00FFFF, 0x0000FF, 0x8000FF, 0xFF00FF, 0xFFFFFF,
    };

    private ColorRow() {}

    static LinearLayout create(Context context, int selected, IntConsumer onPick) {
        LinearLayout row = new LinearLayout(context);
        row.setOrientation(LinearLayout.HORIZONTAL);
        int size = (int) (24 * context.getResources().getDisplayMetrics().density);
        int margin = size / 6;
        View[] views = new View[COLORS.length];
        for (int i = 0; i < COLORS.length; i++) {
            int color = COLORS[i];
            View swatch = new View(context);
            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(size, size);
            lp.setMargins(margin, margin, margin, margin);
            swatch.setLayoutParams(lp);
            swatch.setContentDescription(String.format("#%06X", color));
            views[i] = swatch;
            swatch.setOnClickListener(v -> {
                for (int j = 0; j < views.length; j++) style(views[j], COLORS[j], COLORS[j] == color);
                FrontLed.get(context).preview(color);
                onPick.accept(color);
            });
            style(swatch, color, color == selected);
            row.addView(swatch);
        }
        return row;
    }

    private static void style(View view, int color, boolean selected) {
        GradientDrawable d = new GradientDrawable();
        d.setShape(GradientDrawable.OVAL);
        d.setColor(0xFF000000 | color);
        d.setStroke(selected ? 6 : 1, selected ? 0xFF808080 : 0x40808080);
        view.setBackground(d);
    }
}
