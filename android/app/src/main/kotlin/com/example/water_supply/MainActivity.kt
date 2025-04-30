package com.example.water_supply

import android.os.Build
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val mode = window.context.display?.supportedModes?.maxByOrNull { it.refreshRate }
            if (mode != null) {
                window.attributes.preferredDisplayModeId = mode.modeId
            }
        }
    }
}
