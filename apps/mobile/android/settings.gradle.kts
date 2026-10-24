pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    // Flutter is installed through Scoop's `current` junction. Android Studio
    // caches the canonical SDK path, so use that same real path for the
    // composite build to avoid duplicate/missing ExternalProject entries.
    val flutterGradleBuild =
        file("$flutterSdkPath/packages/flutter_tools/gradle")
            .toPath()
            .toRealPath()
            .toString()
    includeBuild(flutterGradleBuild)

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.4.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

include(":app")

rootProject.name = "android"
