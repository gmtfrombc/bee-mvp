package com.momentumhealth.beemvp

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** AndroidSettingsPlugin for opening Android-specific settings screens */
class AndroidSettingsPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.momentumhealth.beemvp/android_settings")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "openHealthConnectSettings" -> {
                val success = openHealthConnectSettings()
                result.success(success)
            }
            "openAppSettings" -> {
                val success = openAppSettings()
                result.success(success)
            }
            "openGeneralSettings" -> {
                val success = openGeneralSettings()
                result.success(success)
            }
            "canOpenHealthConnectSettings" -> {
                val canOpen = canOpenHealthConnectSettings()
                result.success(canOpen)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun openHealthConnectSettings(): Boolean {
        return try {
            // First try to open Health Connect app settings directly
            val healthConnectPackage = "com.google.android.apps.healthdata"
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", healthConnectPackage, null)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            
            if (intent.resolveActivity(context.packageManager) != null) {
                context.startActivity(intent)
                true
            } else {
                // Fallback to Health Connect permissions if available
                openHealthConnectPermissions()
            }
        } catch (e: Exception) {
            // Fallback to app settings
            openAppSettings()
        }
    }

    private fun openHealthConnectPermissions(): Boolean {
        return try {
            // Try Health Connect specific permissions intent
            val intent = Intent("androidx.health.ACTION_REQUEST_PERMISSIONS").apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            
            if (intent.resolveActivity(context.packageManager) != null) {
                context.startActivity(intent)
                true
            } else {
                false
            }
        } catch (e: Exception) {
            false
        }
    }

    private fun openAppSettings(): Boolean {
        return try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", context.packageName, null)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            
            if (intent.resolveActivity(context.packageManager) != null) {
                context.startActivity(intent)
                true
            } else {
                openGeneralSettings()
            }
        } catch (e: Exception) {
            openGeneralSettings()
        }
    }

    private fun openGeneralSettings(): Boolean {
        return try {
            val intent = Intent(Settings.ACTION_SETTINGS).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            
            if (intent.resolveActivity(context.packageManager) != null) {
                context.startActivity(intent)
                true
            } else {
                false
            }
        } catch (e: Exception) {
            false
        }
    }

    private fun canOpenHealthConnectSettings(): Boolean {
        return try {
            val healthConnectPackage = "com.google.android.apps.healthdata"
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", healthConnectPackage, null)
            }
            intent.resolveActivity(context.packageManager) != null
        } catch (e: Exception) {
            false
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
} 