# Protect Mesh Networking Hardware Callbacks & Plugins
-keep class com.google.android.gms.nearby.** { *; }
-keep class com.pkmnapps.nearby_connections.** { *; }
-keep class com.pauldemarco.flutter_blue_plus.** { *; }

# Protect ML Kit Translation Engine & Download Managers
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_translate.** { *; }
-keep class com.google.android.datatransport.** { *; }