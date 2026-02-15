// android/app/src/main/kotlin/net/jonhanson/flutter_native_splash/FlutterNativeSplashPlugin.kt
package net.jonhanson.flutter_native_splash

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin

/**
 * Stub plugin for flutter_native_splash.
 *
 * Newer versions of flutter_native_splash are build-time only and do not ship
 * a runtime Android plugin, but the GeneratedPluginRegistrant still tries
 * to register this class.
 *
 * This no-op implementation keeps the Android build happy and has no effect
 * at runtime.
 */
class FlutterNativeSplashPlugin : FlutterPlugin {

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        // No-op: splash is configured at build time only.
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        // No-op.
    }
}
