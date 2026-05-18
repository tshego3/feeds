# Add project specific ProGuard rules here.
-keepclassmembers class * {
    @androidx.compose.runtime.Composable <methods>;
}
-keep class co.za.eoitech.feeds.** { *; }
