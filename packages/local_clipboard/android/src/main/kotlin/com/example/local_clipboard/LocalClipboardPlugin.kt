package com.example.local_clipboard

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import android.content.ComponentName
import android.provider.Settings
import android.text.TextUtils


class LocalClipboardPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel : MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.example.viocebubble/clipboard")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "copy" -> {
                val text = call.arguments as? String
                if (text != null) {
                    copyToClipboard(text)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENT", "Text to copy is null", null)
                }
            }
            "copyFiles" -> {
                val filePaths = call.arguments as? List<String>
                if (filePaths != null) {
                    val success = copyFilesToClipboard(filePaths)
                    result.success(success)
                } else {
                    result.error("INVALID_ARGUMENT", "File paths list is null", null)
                }
            }
            "sendToWhatsApp" -> {
                val filePaths = call.arguments as? List<String>
                if (filePaths != null) {
                    val success = sendMultipleToWhatsApp(filePaths)
                    result.success(success)
                } else {
                    result.error("INVALID_ARGUMENT", "File paths list is null", null)
                }
            }
            "isAccessibilityServiceEnabled" -> {
                result.success(isAccessibilityServiceEnabled())
            }
            "openAccessibilitySettings" -> {
                openAccessibilitySettings()
                result.success(true)
            }
            "injectText" -> {
                val text = call.arguments as? String
                if (text != null) {
                    val success = injectText(text)
                    result.success(success)
                } else {
                    result.error("INVALID_ARGUMENT", "Text to inject is null", null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun copyToClipboard(text: String) {
        val intent = Intent().apply {
            setClassName(context.packageName, "com.example.viocebubble.TransparentClipboardActivity")
            putExtra("text", text)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_ANIMATION
        }
        context.startActivity(intent)
    }

    private fun copyFilesToClipboard(filePaths: List<String>): Boolean {
        return try {
            val intent = Intent().apply {
                setClassName(context.packageName, "com.example.viocebubble.TransparentClipboardActivity")
                putStringArrayListExtra("files", ArrayList(filePaths))
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_ANIMATION
            }
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun sendMultipleToWhatsApp(filePaths: List<String>): Boolean {
        val authority = "${context.packageName}.fileprovider"
        val uris = ArrayList<Uri>()
        for (path in filePaths) {
            val file = File(path)
            if (file.exists()) {
                val uri = FileProvider.getUriForFile(context, authority, file)
                uris.add(uri)
            }
        }
        if (uris.isEmpty()) return false

        // Try standard WhatsApp first
        val success = startWhatsAppIntent("com.whatsapp", uris)
        if (success) return true

        // Try WhatsApp Business next
        return startWhatsAppIntent("com.whatsapp.w4b", uris)
    }

    private fun startWhatsAppIntent(packageName: String, uris: ArrayList<Uri>): Boolean {
        return try {
            val intent = Intent().apply {
                action = Intent.ACTION_SEND_MULTIPLE
                type = "image/*"
                setPackage(packageName)
                putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
            }
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val expectedComponentName = ComponentName(context.packageName, "com.example.viocebubble.VoiceBubbleAccessibilityService")
        val enabledServicesSetting = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        val colonSplitter = TextUtils.SimpleStringSplitter(':')
        colonSplitter.setString(enabledServicesSetting)
        while (colonSplitter.hasNext()) {
            val componentNameString = colonSplitter.next()
            val enabledService = ComponentName.unflattenFromString(componentNameString)
            if (enabledService != null && enabledService == expectedComponentName) {
                return true
            }
        }
        return false
    }

    private fun openAccessibilitySettings() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        context.startActivity(intent)
    }

    private fun injectText(text: String): Boolean {
        return try {
            val clazz = Class.forName("com.example.viocebubble.VoiceBubbleAccessibilityService")
            val companionField = clazz.getField("Companion")
            val companionObj = companionField.get(null)
            val method = companionObj.javaClass.getMethod("injectText", Context::class.java, String::class.java)
            method.invoke(companionObj, context, text) as Boolean
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
