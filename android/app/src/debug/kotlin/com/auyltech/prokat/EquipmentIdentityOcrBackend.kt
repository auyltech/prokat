package com.auyltech.prokat

import android.app.Activity
import android.graphics.Rect
import android.net.Uri
import android.os.SystemClock
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File

object EquipmentIdentityOcrBackend {
    private const val CHANNEL = "com.auyltech.prokat/equipment_identity_ocr"

    fun register(messenger: BinaryMessenger, activity: Activity) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method != "recognizeFile") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val path = call.argument<String>("path")
            if (path.isNullOrBlank()) {
                result.error("bad_args", "path required", null)
                return@setMethodCallHandler
            }
            val started = SystemClock.elapsedRealtime()
            val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
            try {
                val image = InputImage.fromFilePath(activity, Uri.fromFile(File(path)))
                recognizer.process(image)
                    .addOnSuccessListener { visionText ->
                        val observations = ArrayList<Map<String, Any?>>()
                        for (block in visionText.textBlocks) {
                            for (line in block.lines) {
                                observations.add(lineMap(line.text, line.boundingBox, line.confidence))
                            }
                        }
                        result.success(
                            mapOf(
                                "engine" to "android-mlkit-latin-bundled",
                                "imageWidth" to image.width,
                                "imageHeight" to image.height,
                                "elapsedMs" to (SystemClock.elapsedRealtime() - started),
                                "observations" to observations,
                                "supportedLanguages" to listOf("latin"),
                                "note" to "Bundled Latin model. No Play Services download.",
                            ),
                        )
                        recognizer.close()
                    }
                    .addOnFailureListener { error ->
                        recognizer.close()
                        result.error("ocr", error.message, null)
                    }
            } catch (error: Exception) {
                recognizer.close()
                result.error("ocr", error.message, null)
            }
        }
    }

    private fun lineMap(text: String, box: Rect?, confidence: Float?): Map<String, Any?> {
        return mapOf(
            "text" to text,
            "confidence" to confidence?.toDouble(),
            "left" to box?.left,
            "top" to box?.top,
            "width" to box?.width(),
            "height" to box?.height(),
        )
    }
}
