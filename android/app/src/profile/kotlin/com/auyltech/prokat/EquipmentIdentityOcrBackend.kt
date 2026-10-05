package com.auyltech.prokat

import android.app.Activity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

object EquipmentIdentityOcrBackend {
    private const val CHANNEL = "com.auyltech.prokat/equipment_identity_ocr"

    fun register(messenger: BinaryMessenger, activity: Activity) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method != "recognizeFile") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            result.error(
                "debug_only",
                "On-device OCR spike is compiled into debug builds only.",
                null,
            )
        }
    }
}
