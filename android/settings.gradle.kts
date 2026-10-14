pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

// Auto-patch legacy plugins using deprecated 'proguard-android.txt' for AGP 9.0+ compatibility
val pubCachePath = System.getenv("PUB_CACHE") ?: (System.getProperty("user.home") + "/AppData/Local/Pub/Cache/hosted/pub.dev")
val pubCacheDir = file(pubCachePath)
if (pubCacheDir.exists()) {
    pubCacheDir.walkTopDown().maxDepth(4).filter { it.name == "build.gradle" && it.path.contains("flutter_inappwebview_android") }.forEach { bg ->
        val content = bg.readText()
        if (content.contains("proguard-android.txt")) {
            bg.writeText(content.replace("proguard-android.txt", "proguard-android-optimize.txt"))
        }
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
    id("com.google.gms.google-services") version "4.5.0" apply false
}

include(":app")
