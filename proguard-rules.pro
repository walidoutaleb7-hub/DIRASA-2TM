# قواعد حماية ZegoCloud لمنع الإغلاق المفاجئ
-keep class **.zego.** { *; }
-keep class **.**.zego_zpns.** { *; }
-keep class com.zegocloud.** { *; }

# قواعد حماية Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# الحفاظ على فئات Flutter الأساسية
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# إخفاء تحذيرات مكتبات جوجل غير الضرورية
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
