package com.momentumhealth.beemvp

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Register Android Settings Plugin
        flutterEngine.plugins.add(AndroidSettingsPlugin())
    }
}
