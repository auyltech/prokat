package com.auyltech.prokat

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        EquipmentIdentityOcrBackend.register(
            flutterEngine.dartExecutor.binaryMessenger,
            this,
        )
    }
}
