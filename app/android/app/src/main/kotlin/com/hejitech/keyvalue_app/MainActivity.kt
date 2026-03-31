@file:OptIn(com.google.firebase.ai.type.PublicPreviewAPI::class)

package com.hejitech.keyvalue_app

import android.os.Bundle
import com.google.firebase.Firebase
import com.google.firebase.ai.ai
import com.google.firebase.ai.GenerativeModel
import com.google.firebase.ai.InferenceMode
import com.google.firebase.ai.OnDeviceConfig
import com.google.firebase.ai.ondevice.FirebaseAIOnDevice
import com.google.firebase.ai.ondevice.OnDeviceModelStatus
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.flow.collect

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.hejitech.keyvalue_app/ai_ondevice"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "prepareModel" -> prepareModel(result)
                "checkStatus" -> checkStatus(result)
                "generateContent" -> {
                    val prompt = call.argument<String>("prompt")
                    if (prompt != null) {
                        generateContent(prompt, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Prompt is null", null)
                    }
                }
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
                
                val friendlyStatus = when (status) {
                    OnDeviceModelStatus.AVAILABLE -> "AVAILABLE"
                    OnDeviceModelStatus.DOWNLOADING -> "DOWNLOADING"
                    OnDeviceModelStatus.DOWNLOADABLE -> "DOWNLOADABLE"
                    OnDeviceModelStatus.UNAVAILABLE -> "UNSUPPORTED"
                    else -> "UNSUPPORTED"
                }
                
                result.success(friendlyStatus)
            } catch (e: Exception) {
                result.error("STATUS_ERROR", e.message, null)
            }
        }
    }

    private fun generateContent(prompt: String, result: MethodChannel.Result) {
        CoroutineScope(Dispatchers.Main).launch {
            try {
                // Initialize the GenerativeModel with on-device config
                val model = Firebase.ai.generativeModel(
                    modelName = "gemini-2.0-flash",
                    onDeviceConfig = OnDeviceConfig(mode = InferenceMode.ONLY_ON_DEVICE)
                )
                
                val response = withContext(Dispatchers.IO) {
                    model.generateContent(prompt)
                }
                result.success(response.text)
            } catch (e: Exception) {
                result.error("GENERATE_ERROR", e.message, null)
            }
        }
    }

    private fun prepareModel(result: MethodChannel.Result) {
        CoroutineScope(Dispatchers.Main).launch {
            try {
                val status = withContext(Dispatchers.IO) {
                    FirebaseAIOnDevice.checkStatus()
                }
                
                if (status == OnDeviceModelStatus.DOWNLOADABLE || 
                    status == OnDeviceModelStatus.DOWNLOADING) {
                    
                    withContext(Dispatchers.IO) {
                        FirebaseAIOnDevice.download().collect { _ -> }
                    }
                    result.success("DOWNLOADED")
                } else if (status == OnDeviceModelStatus.AVAILABLE) {
                    result.success("AVAILABLE")
                } else {
                    result.success("UNSUPPORTED")
                }
            } catch (e: Exception) {
                result.error("PREPARE_ERROR", e.message, null)
            }
        }
    }
}
