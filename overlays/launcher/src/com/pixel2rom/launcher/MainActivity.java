package com.pixel2rom.launcher;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;

public class MainActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        findViewById(R.id.btn_camera).setOnClickListener(v ->
                Actions.launchCamera(this));
        findViewById(R.id.btn_gallery).setOnClickListener(v ->
                Actions.launchGallery(this));
        findViewById(R.id.btn_uvc).setOnClickListener(v ->
                Actions.toggleUvc(this));
        startService(new Intent(this, PillService.class));
    }
}
