package com.example.ocr_scanner_app

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.View
import android.view.WindowManager
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.net.NetworkInterface
import java.net.InetAddress

class MainActivity : FlutterActivity() {
    private val KIOSK_CHANNEL = "com.example.ocr_scanner_app/kiosk"
    private val TAILSCALE_CHANNEL = "com.example.ocr_scanner_app/tailscale"
    private val INSTALL_CHANNEL = "com.example.ocr_scanner_app/install"
    private var isInKioskMode = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // APK Install Channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            INSTALL_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "installApk" -> {
                    val filePath = call.argument<String>("filePath") ?: ""
                    try {
                        val file = File(filePath)
                        if (!file.exists()) {
                            result.error("FILE_NOT_FOUND", "APK file not found: $filePath", null)
                            return@setMethodCallHandler
                        }

                        // Android 8+ için izin kontrolü
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            if (!packageManager.canRequestPackageInstalls()) {
                                // İzin yok - ayarlara yönlendir
                                val intent = Intent(
                                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                                    Uri.parse("package:$packageName")
                                )
                                startActivity(intent)
                                result.success("PERMISSION_REQUESTED")
                                return@setMethodCallHandler
                            }
                        }

                        // FileProvider ile URI oluştur
                        val apkUri = FileProvider.getUriForFile(
                            this,
                            "${applicationContext.packageName}.fileprovider",
                            file
                        )

                        val intent = Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(apkUri, "application/vnd.android.package-archive")
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
                        }
                        startActivity(intent)
                        result.success("INSTALLING")
                    } catch (e: Exception) {
                        result.error("INSTALL_ERROR", e.message, null)
                    }
                }
                "canInstallPackages" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        result.success(packageManager.canRequestPackageInstalls())
                    } else {
                        result.success(true)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Kiosk Mode Channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            KIOSK_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setKioskMode" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    result.success(setKioskMode(enabled))
                }
                "setFullscreen" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    setFullscreenMode(enabled)
                    result.success(null)
                }
                "hideSystemUI" -> {
                    val hide = call.argument<Boolean>("hide") ?: false
                    hideSystemUI(hide)
                    result.success(null)
                }
                "lockTaskMode" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    result.success(lockTaskMode(enabled))
                }
                "disableBackButton" -> {
                    disableBackButton()
                    result.success(null)
                }
                "preventHomeButton" -> {
                    preventHomeButton()
                    result.success(null)
                }
                "preventScreenCapture" -> {
                    val prevent = call.argument<Boolean>("prevent") ?: false
                    preventScreenCapture(prevent)
                    result.success(null)
                }
                "exitKioskMode" -> {
                    val password = call.argument<String>("password") ?: ""
                    // Developer şifresi ile çıkılabilir
                    result.success(password == "el1984" && exitKioskMode())
                }
                else -> result.notImplemented()
            }
        }

        // Tailscale Channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            TAILSCALE_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkTailscaleStatus" -> {
                    result.success(isTailscaleRunning())
                }
                "startTailscale" -> {
                    val authKey = call.argument<String>("authKey")
                    // Tailscale uygulamasını başlat
                    try {
                        val intent = Intent(Intent.ACTION_VIEW)
                        intent.data = Uri.parse("tailscale://")
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        
                        if (intent.resolveActivity(packageManager) != null) {
                            startActivity(intent)
                            result.success(true)
                        } else {
                            // Intent çalışmazsa direkt package launch
                            val launchIntent = packageManager.getLaunchIntentForPackage("com.tailscale.ipn")
                            if (launchIntent != null) {
                                startActivity(launchIntent)
                                result.success(true)
                            } else {
                                result.success(false)
                            }
                        }
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "stopTailscale" -> {
                    // Tailscale'i durdurmak için intent gönder
                    try {
                        val intent = Intent("com.tailscale.ipn.STOP")
                        sendBroadcast(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "getLocalIP" -> {
                    // Tailscale IP'sini al (100.x.x.x formatında)
                    val tailscaleIP = getTailscaleIP()
                    result.success(tailscaleIP)
                }
                "getHostname" -> {
                    result.success(Build.DEVICE)
                }
                "getPeers" -> {
                    // Tailscale peer listesi - şimdilik mock
                    result.success(listOf(
                        mapOf("name" to "Router", "ip" to "100.100.100.100"),
                        mapOf("name" to "Laptop", "ip" to "100.100.100.101")
                    ))
                }
                "getStatus" -> {
                    val isConnected = isTailscaleRunning()
                    val localIP = if (isConnected) getTailscaleIP() else null
                    result.success(mapOf(
                        "isConnected" to isConnected,
                        "localIP" to localIP,
                        "version" to "1.0.0"
                    ))
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setKioskMode(enabled: Boolean): Boolean {
        isInKioskMode = enabled
        if (enabled) {
            hideSystemUI(true)
            lockTaskMode(true)
            preventScreenCapture(true)
        } else {
            hideSystemUI(false)
            lockTaskMode(false)
            preventScreenCapture(false)
        }
        return true
    }

    private fun setFullscreenMode(enabled: Boolean) {
        if (enabled) {
            window.setFlags(
                WindowManager.LayoutParams.FLAG_FULLSCREEN,
                WindowManager.LayoutParams.FLAG_FULLSCREEN
            )
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
        }
    }

    private fun hideSystemUI(hide: Boolean) {
        if (hide) {
            val flags = (View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY)
            window.decorView.systemUiVisibility = flags
        } else {
            val flags = View.SYSTEM_UI_FLAG_LAYOUT_STABLE
            window.decorView.systemUiVisibility = flags
        }
    }

    private fun lockTaskMode(enabled: Boolean): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                if (enabled) {
                    startLockTask()
                } else {
                    stopLockTask()
                }
            }
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun disableBackButton() {
        // Geri tuşu devre dışı bırakılır onBackPressed override ile
    }

    private fun preventHomeButton() {
        // Home tuşu engelleme (Device Owner Mode gerekli)
    }

    private fun preventScreenCapture(prevent: Boolean) {
        if (prevent) {
            window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE
            )
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }

    private fun exitKioskMode(): Boolean {
        isInKioskMode = false
        setFullscreenMode(false)
        hideSystemUI(false)
        lockTaskMode(false)
        preventScreenCapture(false)
        return true
    }

    private fun isTailscaleInstalled(): Boolean {
        return try {
            packageManager.getApplicationInfo("com.tailscale.ipn", 0) != null
        } catch (e: Exception) {
            false
        }
    }

    private fun isTailscaleRunning(): Boolean {
        if (!isTailscaleInstalled()) return false
        
        // Tailscale IP'si varsa çalışıyor demektir
        val tailscaleIP = getTailscaleIP()
        return tailscaleIP != null && tailscaleIP.isNotEmpty()
    }

    private fun getTailscaleIP(): String? {
        try {
            val interfaces = NetworkInterface.getNetworkInterfaces()
            while (interfaces.hasMoreElements()) {
                val networkInterface = interfaces.nextElement()
                val name = networkInterface.name
                
                // Tailscale interface'i "tailscale0" veya "utun" ile başlar
                if (name.startsWith("tailscale") || name.startsWith("utun")) {
                    val addresses = networkInterface.inetAddresses
                    while (addresses.hasMoreElements()) {
                        val address = addresses.nextElement()
                        
                        // IPv4 adresi ve 100.x.x.x formatında mı kontrol et
                        if (!address.isLoopbackAddress && address is InetAddress) {
                            val ip = address.hostAddress
                            if (ip != null && ip.startsWith("100.")) {
                                return ip
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return null
    }

    override fun onBackPressed() {
        if (!isInKioskMode) {
            super.onBackPressed()
        }
        // Kiosk modunda geri tuşu engellendi
    }
}

