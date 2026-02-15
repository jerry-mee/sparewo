# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Play Core
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-keep class com.google.android.play.core.common.** { *; }
-keep class com.google.android.play.core.listener.** { *; }

# Keep camera-related classes
-keep class io.flutter.plugins.camera.** { *; }
-keep class androidx.camera.** { *; }
-keep class com.google.android.material.** { *; }
-keep class androidx.lifecycle.** { *; }
-keep class androidx.core.app.** { *; }

# Keep image picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# Keep permission handler
-keep class com.baseflow.permissionhandler.** { *; }

# Keep R8 from complaining about missing classes
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn io.flutter.app.**
-dontwarn io.flutter.plugin.editing.**
-dontwarn io.flutter.plugin.platform.**
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication

# Camera permissions
-dontwarn android.hardware.camera.** 
-dontwarn android.hardware.camera2.**

# Keep classes that implement the FlutterPlugin, MethodCallHandler, etc. interfaces
-keep class * implements io.flutter.plugin.common.MethodCallHandler { *; }
-keep class * implements io.flutter.plugin.common.PluginRegistry$Registrar { *; }
-keep class * implements io.flutter.plugin.common.BinaryMessenger { *; }
-keep class * implements io.flutter.embedding.engine.plugins.FlutterPlugin { *; }
-keep class * implements io.flutter.embedding.engine.plugins.activity.ActivityAware { *; }

# Keep Serializable objects 
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}