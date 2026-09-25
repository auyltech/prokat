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

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.1" apply false
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") version("4.5.0") apply false
    id("com.google.firebase.crashlytics") version("3.0.8") apply false
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

include(":app")

// play_install_referrer 0.5.0 always applies kotlin-android and the old
// compileSdkVersion DSL. AGP 9 with built-in Kotlin rejects that. Copy a
// compatible build file over the pub-cache project before it is evaluated.
gradle.beforeProject {
    if (name != "play_install_referrer") return@beforeProject
    val patched = settingsDir.resolve("patches/play_install_referrer.build.gradle")
    val target = projectDir.resolve("build.gradle")
    if (!patched.isFile || !target.isFile) return@beforeProject
    if (target.readText() != patched.readText()) {
        target.writeText(patched.readText())
    }
}
