package com.example.app_uninstaller_new

import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Environment
import android.os.StatFs
import android.util.Base64
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "app_uninstaller/apps"
    private val UNINSTALL_REQUEST_CODE = 1
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, 
            CHANNEL
        )
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getStorageInfo" -> {
                    val storageInfo = getDeviceStorageInfo()
                    result.success(hashMapOf(
                        "totalStorage" to storageInfo["totalStorage"].toString(),
                        "usedStorage" to storageInfo["usedStorage"].toString(),
                        "availableStorage" to storageInfo["availableStorage"].toString(),
                        "usedPercentage" to storageInfo["usedPercentage"].toString()
                    ))
                }
                "getInstalledApps" -> {
                    try {
                        val apps = getInstalledApplications()
                        result.success(apps)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Uygulama listesi alınamadı", e)
                        result.error("GET_APPS_ERROR", "Uygulama listesi alınamadı: ${e.message}", null)
                    }
                }
                "getAppPermissions" -> {
                    val packageName = call.arguments as String
                    try {
                        val permissions = getAppPermissions(packageName)
                        result.success(permissions)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "İzinler alınamadı", e)
                        result.error("GET_PERMISSIONS_ERROR", "İzinler alınamadı: ${e.message}", null)
                    }
                }
                "uninstallApp" -> {
                    val packageName = call.arguments as String
                    val intent = Intent(Intent.ACTION_UNINSTALL_PACKAGE)
                    intent.data = Uri.parse("package:$packageName")
                    intent.putExtra(Intent.EXTRA_RETURN_RESULT, true)
                    startActivityForResult(intent, UNINSTALL_REQUEST_CODE)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    // Uygulama ikonunu base64'e çeviren yardımcı metod
    private fun drawableToBase64(drawable: Drawable): String {
        val bitmap = Bitmap.createBitmap(
            drawable.intrinsicWidth, 
            drawable.intrinsicHeight, 
            Bitmap.Config.ARGB_8888
        )
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)

        val outputStream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
        val byteArray = outputStream.toByteArray()
        return Base64.encodeToString(byteArray, Base64.NO_WRAP)
    }

    private fun getInstalledApplications(): List<Map<String, Any?>> {
        val packageManager = applicationContext.packageManager
        
        val flags = PackageManager.GET_META_DATA or 
                    PackageManager.GET_SHARED_LIBRARY_FILES or 
                    PackageManager.MATCH_ALL

        return packageManager.getInstalledApplications(flags)
            .filter { app -> 
                !isSystemApp(app) && 
                packageManager.getLaunchIntentForPackage(app.packageName) != null 
            }
            .map { app ->
                val packageName = app.packageName
                val appName = packageManager.getApplicationLabel(app).toString()
                val packageInfo = packageManager.getPackageInfo(packageName, PackageManager.GET_PERMISSIONS)
                
                val appIcon = drawableToBase64(packageManager.getApplicationIcon(app))
                
                hashMapOf(
                    "packageName" to packageName,
                    "appName" to appName,
                    "appIcon" to "data:image/png;base64,$appIcon",
                    "size" to (packageInfo.applicationInfo.sourceDir?.let { File(it).length() / (1024 * 1024.0) } ?: 0.0),
                    "lastUsedTime" to packageInfo.lastUpdateTime,
                    "installedTime" to packageInfo.firstInstallTime,
                    "permissions" to getAppPermissions(packageName),
                    "category" to getCategoryName(app)
                )
            }
    }

    private fun isSystemApp(app: ApplicationInfo): Boolean {
        return (app.flags and ApplicationInfo.FLAG_SYSTEM) != 0
    }

    private fun getAppPermissions(packageName: String): List<String> {
        val packageManager = applicationContext.packageManager
        val packageInfo = packageManager.getPackageInfo(packageName, PackageManager.GET_PERMISSIONS)
        
        return packageInfo.requestedPermissions?.mapNotNull { permission ->
            when {
                permission.contains("CAMERA") -> "Kamera"
                permission.contains("LOCATION") -> "Konum"
                permission.contains("STORAGE") -> "Depolama"
                permission.contains("MICROPHONE") -> "Mikrofon"
                permission.contains("CONTACTS") -> "Kişiler"
                permission.contains("PHONE") -> "Telefon"
                else -> null
            }
        } ?: listOf()
    }

    private fun getCategoryName(app: ApplicationInfo): String {
        return when {
            (app.flags and ApplicationInfo.FLAG_IS_GAME) != 0 -> "Oyun"
            (app.flags and ApplicationInfo.FLAG_SYSTEM) != 0 -> "Sistem"
            else -> "Diğer"
        }
    }

    // Uygulama kaldırma sonucunu işle
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == UNINSTALL_REQUEST_CODE) {
            val success = resultCode == RESULT_OK
            Log.d("MainActivity", "Uygulama kaldırma sonucu: $success")
            
            // Sonucu Flutter tarafına bildir
            methodChannel?.invokeMethod("uninstallResult", success)
        }
    }

    private fun getDeviceStorageInfo(): Map<String, Any> {
        val statFs = StatFs(Environment.getDataDirectory().path)
        val totalBytes = statFs.totalBytes
        val availableBytes = statFs.availableBytes
        val usedBytes = totalBytes - availableBytes

        return hashMapOf(
            "totalStorage" to totalBytes.toString(),
            "usedStorage" to usedBytes.toString(),
            "availableStorage" to availableBytes.toString(),
            "usedPercentage" to ((usedBytes.toDouble() / totalBytes) * 100).toInt().toString()
        )
    }
}
