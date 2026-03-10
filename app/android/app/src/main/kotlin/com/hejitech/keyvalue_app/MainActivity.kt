package com.hejitech.keyvalue_app

import android.os.Bundle
import com.google.firebase.ai.ondevice.FirebaseAIOnDevice
import com.google.firebase.ai.ondevice.OnDeviceModelStatus
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.flow.collect

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.hejitech.keyvalue_app/ai_ondevice"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "prepareModel" -> prepareModel(result)
                "checkStatus" -> checkStatus(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun checkStatus(result: MethodChannel.Result) {
        CoroutineScope(Dispatchers.Main).launch {
            try {
                val status = withContext(Dispatchers.IO) {
                    FirebaseAIOnDevice.checkStatus()
                }
                result.success(status.toString())
            } catch (e: Exception) {
                result.error("STATUS_ERROR", e.message, null)
            }
        }
    }

    private fun prepareModel(result: MethodChannel.Result) {
        CoroutineScope(Dispatchers.Main).launch {
            try {
                val status = withContext(Dispatchers.IO) {
                    FirebaseAIOnDevice.checkStatus()
                }
                
                // Use string comparison or type check if it's a sealed class
                val statusStr = status.toString()
                
                if (statusStr.contains("DOWNLOADABLE") || statusStr.contains("NeedsDownload")) {
                    withContext(Dispatchers.IO) {
                        FirebaseAIOnDevice.download().collect { _ -> }
                    }
                    result.success("DOWNLOADED")
                } else if (statusStr.contains("AVAILABLE") || statusStr.contains("Ready")) {
                    result.success("AVAILABLE")
                } else {
                    result.success(statusStr)
                }
            } catch (e: Exception) {
                result.error("PREPARE_ERROR", e.message, null)
            }
        }
    }
}
