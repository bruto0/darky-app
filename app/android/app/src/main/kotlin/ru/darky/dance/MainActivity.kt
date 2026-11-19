package ru.darky.dance

import android.content.pm.PackageManager
import android.view.WindowManager
import android.webkit.WebView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "ru.darky.dance/browser"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getBrowserInfo" -> result.success(readBrowserInfo())
                    "setSecureFlag" -> {
                        val secure = call.arguments as? Boolean ?: false
                        if (secure) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun readBrowserInfo(): Map<String, Any?> {
        val chromeVersion = packageVersion("com.android.chrome", enabledOnly = true)
        val webViewVersion = try {
            WebView.getCurrentWebViewPackage()?.versionName
        } catch (_: Throwable) {
            null
        }
        return mapOf(
            "chromeVersion" to chromeVersion,
            "webviewVersion" to webViewVersion,
        )
    }

    private fun packageVersion(packageName: String, enabledOnly: Boolean): String? {
        return try {
            val info = packageManager.getPackageInfo(packageName, 0)
            if (enabledOnly && info.applicationInfo?.enabled != true) null else info.versionName
        } catch (_: PackageManager.NameNotFoundException) {
            null
        } catch (_: Throwable) {
            null
        }
    }
}
