package com.pixel2rom.launcher;

import android.app.Service;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.graphics.PixelFormat;
import android.os.IBinder;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

/**
 * Persistent side-docked pill menu: a slim overlay strip docked to the right edge
 * that opens a floating panel with Camera / Gallery / UVC toggles.
 */
public class PillService extends Service {
    private WindowManager wm;
    private View pill, popup;
    private boolean panelOpen = false;

    private static int dp(int v) {
        return (int) (v * 2.0f); // ~2x density on walleye (1080p, 420dpi)
    }

    @Override
    public IBinder onBind(Intent i) { return null; }

    @Override
    public int onStartCommand(Intent i, int flags, int id) {
        wm = (WindowManager) getSystemService(WINDOW_SERVICE);
        if (pill == null) showPill();
        return START_STICKY;
    }

    private void showPill() {
        LinearLayout strip = new LinearLayout(this);
        strip.setOrientation(LinearLayout.VERTICAL);
        strip.setGravity(Gravity.CENTER);
        GradientDrawable bg = new GradientDrawable();
        bg.setColor(Color.parseColor("#CC101418"));
        bg.setCornerRadius(dp(18));
        strip.setBackground(bg);

        TextView tv = new TextView(this);
        tv.setText("•\n•\n•");
        tv.setTextColor(Color.WHITE);
        tv.setGravity(Gravity.CENTER);
        tv.setTypeface(null, Typeface.BOLD);
        strip.addView(tv, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        strip.setPadding(dp(4), dp(8), dp(4), dp(8));

        WindowManager.LayoutParams lp = new WindowManager.LayoutParams(
                dp(28), ViewGroup.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                    | WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH,
                PixelFormat.TRANSLUCENT);
        lp.gravity = Gravity.END | Gravity.CENTER_VERTICAL;
        lp.x = dp(2);

        strip.setOnClickListener(v -> { if (panelOpen) hidePanel(); else showPanel(); });
        pill = strip;
        wm.addView(pill, lp);
    }

    private void showPanel() {
        LinearLayout panel = new LinearLayout(this);
        panel.setOrientation(LinearLayout.VERTICAL);
        panel.setPadding(dp(12), dp(12), dp(12), dp(12));
        GradientDrawable bg = new GradientDrawable();
        bg.setColor(Color.parseColor("#F0101418"));
        bg.setCornerRadius(dp(12));
        panel.setBackground(bg);

        panel.addView(button("Camera", v -> { Actions.launchCamera(this); hidePanel(); }));
        panel.addView(button("Gallery", v -> { Actions.launchGallery(this); hidePanel(); }));
        panel.addView(button("UVC " + (Actions.uvcState() ? "OFF" : "ON"),
                v -> { Actions.toggleUvc(this); hidePanel(); }));

        WindowManager.LayoutParams lp = new WindowManager.LayoutParams(
                dp(120), ViewGroup.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
                PixelFormat.TRANSLUCENT);
        lp.gravity = Gravity.END | Gravity.CENTER_VERTICAL;
        popup = panel;
        wm.addView(popup, lp);
        panelOpen = true;
    }

    private void hidePanel() {
        if (popup != null) {
            try { wm.removeView(popup); } catch (Exception ignored) {}
            popup = null;
        }
        panelOpen = false;
    }

    private Button button(String label, View.OnClickListener l) {
        Button b = new Button(this);
        b.setText(label);
        b.setTextColor(Color.WHITE);
        b.setOnClickListener(l);
        return b;
    }

    @Override
    public void onDestroy() {
        hidePanel();
        if (pill != null) {
            try { wm.removeView(pill); } catch (Exception ignored) {}
            pill = null;
        }
        super.onDestroy();
    }
}
