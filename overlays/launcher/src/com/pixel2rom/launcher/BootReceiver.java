package com.pixel2rom.launcher;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

/** Boots straight into the camera viewfinder and raises the pill menu. */
public class BootReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        if (Intent.ACTION_BOOT_COMPLETED.equals(intent.getAction())) {
            context.startService(new Intent(context, PillService.class));
            Actions.launchCamera(context);
        }
    }
}
