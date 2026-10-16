/*
 * SPDX-FileCopyrightText: 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.jellystar.ledbelt;

import android.view.View;
import android.view.WindowInsets;

/** Keeps content clear of the status, action and navigation bars (Android 15+ edge-to-edge). */
final class Insets {
    private Insets() {}

    static void apply(View view) {
        int l = view.getPaddingLeft(), t = view.getPaddingTop();
        int r = view.getPaddingRight(), b = view.getPaddingBottom();
        view.setOnApplyWindowInsetsListener((v, insets) -> {
            android.graphics.Insets bars = insets.getInsets(
                    WindowInsets.Type.systemBars() | WindowInsets.Type.displayCutout());
            v.setPadding(l + bars.left, t + bars.top, r + bars.right, b + bars.bottom);
            return WindowInsets.CONSUMED;
        });
        view.requestApplyInsets();
    }
}
