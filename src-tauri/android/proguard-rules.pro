# Alouette Android ProGuard Rules
# This file ensures TTS functionality works in release builds

# TTS相关类保持不混淆
-keep class * extends android.speech.tts.** { *; }
-keep class android.speech.tts.** { *; }
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Tauri WebView相关
-keep class com.alouette.app.** { *; }
-keep class app.tauri.** { *; }
-keepclassmembers class app.tauri.** { *; }

# 保持所有原生方法
-keepclasseswithmembernames class * {
    native <methods>;
}

# 保持WebView JavaScript接口
-keepclassmembers class fqcn.of.javascript.interface.for.webview {
   public *;
}

# 保持调试信息用于错误追踪
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# 网络相关类不混淆（用于Edge TTS API）
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }
-dontwarn okhttp3.**
-dontwarn retrofit2.**

# JSON序列化相关
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class com.fasterxml.jackson.** { *; }

# 保持Rust JNI库
-keep class rust.** { *; }
-keepclassmembers class rust.** { *; }

# WebView相关
-keep class androidx.webkit.** { *; }
-keep class android.webkit.** { *; }
-keepclassmembers class android.webkit.** { *; }

# 禁用过度优化可能破坏TTS功能
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizations !code/allocation/variable
