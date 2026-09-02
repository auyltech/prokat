import java.io.FileInputStream
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val googleServicesFile = file("google-services.json")
if (googleServicesFile.exists()) {
    apply(plugin = "com.google.gms.google-services")
    apply(plugin = "com.google.firebase.crashlytics")
}

android {
    namespace = "com.auyltech.prokat"
    compileSdk {
        version = release(37) {
            minorApiLevel = 0
        }
    }
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    buildFeatures {
        resValues = true
    }

    signingConfigs {
        create("release") {
            if (keystoreProperties.isEmpty) {
                // Fallback to debug configs so building in debug mode doesn't break if properties missing
                storeFile = file("../debug.keystore")
                storePassword = "android"
                keyAlias = "androiddebugkey"
                keyPassword = "android"
            } else {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    defaultConfig {
        applicationId = "com.auyltech.prokat"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        var mapboxToken = ""

        val envFile = project.rootProject.file("../.env")
        if (envFile.exists()) {
            val envProperties = Properties()
            FileInputStream(envFile).use(envProperties::load)
            mapboxToken = envProperties
                .getProperty("MAPBOX_TOKEN", "")
                .trim()
                .removeSurrounding("\"")
                .removeSurrounding("'")
        }

        val envLocalFile = project.rootProject.file("../.env.local")
        if (envLocalFile.exists()) {
            val envLocalProperties = Properties()
            FileInputStream(envLocalFile).use(envLocalProperties::load)
            val localToken = envLocalProperties
                .getProperty("MAPBOX_TOKEN", "")
                .trim()
                .removeSurrounding("\"")
                .removeSurrounding("'")
            if (localToken.isNotEmpty()) {
                mapboxToken = localToken
            }
        }
        
        // Backward-compatible fallback for existing developer setups.
        if (mapboxToken.isEmpty()) {
            val configFile = project.rootProject.file("../config.json")
            if (configFile.exists()) {
                val jsonText = configFile.readText()
                val match = Regex("\"MAPBOX_TOKEN\"\\s*:\\s*\"([^\"]+)\"").find(jsonText)
                if (match != null) {
                    mapboxToken = match.groupValues[1]
                }
            }
        }
        
        // Environment fallback flag check
        if (mapboxToken.isEmpty()) {
            mapboxToken = System.getenv("MAPBOX_TOKEN") ?: ""
        }

        if (mapboxToken.isEmpty()) {
            throw GradleException(
                "MAPBOX_TOKEN is missing. Add it to prokat/.env or prokat/.env.local.",
            )
        }

        manifestPlaceholders["MAPBOX_TOKEN"] = mapboxToken
        resValue("string", "mapbox_access_token", mapboxToken)
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}
