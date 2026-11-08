package com.pixel2rom.launcher;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.provider.MediaStore;
import android.widget.Toast;

/** Shared actions for the launcher home screen and the docked pill menu. */
public final class Actions {
    /** Verified stock component on walleye RP1A.201005.004.A1. */
    static final ComponentName GCAM =
            new ComponentName("com.google.android.GoogleCamera",
                    "com.android.camera.CameraLauncher");
    public static final String UVC_PROP = "pixel2rom.uvc.enable";
    private static boolean uvcOn = false;

    private Actions() {}

    public static void launchCamera(Context c) {
        Intent i = new Intent(Intent.ACTION_MAIN).setComponent(GCAM)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        try {
            c.startActivity(i);
        } catch (Exception e) {
            try {
                c.startActivity(new Intent(MediaStore.INTENT_ACTION_STILL_IMAGE_CAMERA)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
            } catch (Exception e2) {
                toast(c, "No camera app found");
            }
        }
    }

    public static void launchGallery(Context c) {
        try {
            c.startActivity(new Intent(Intent.ACTION_MAIN)
                    .addCategory(Intent.CATEGORY_APP_GALLERY)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
        } catch (Exception e) {
            toast(c, "No gallery app found");
        }
    }

    public static void toggleUvc(Context c) {
        uvcOn = !uvcOn;
        String value = uvcOn ? "1" : "0";
        boolean ok = false;
        try {
            Process p = Runtime.getRuntime().exec(
                    new String[]{"sh", "-c", "setprop " + UVC_PROP + " " + value});
            ok = p.waitFor() == 0;
        } catch (Exception ignored) {
        }
        // Honest state: SELinux may deny platform_app setprop until the policy lands.
        toast(c, "UVC " + (uvcOn ? "ON" : "OFF") + " (prop write " + (ok ? "ok" : "denied)"));
    }

    private static void toast(Context c, String m) {
        Toast.makeText(c, m, Toast.LENGTH_SHORT).show();
    }

    public static boolean uvcState() {
        return uvcOn;
    }
}
