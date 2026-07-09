import java.io.FileInputStream
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.auyltech.prokat"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
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
        
        // Automated config.json lookup during compilation pipeline
        val configFile = project.rootProject.file("../config.json")
        if (configFile.exists()) {
            val jsonText = configFile.readText()
            val match = Regex("\"MAPBOX_TOKEN\"\\s*:\\s*\"([^\"]+)\"").find(jsonText)
            if (match != null) {
                // Fixed: Explicitly select index 1 to read the string match group
                mapboxToken = match.groupValues[1]
            }
        }
        
        // Environment fallback flag check
        if (mapboxToken.isEmpty()) {
            mapboxToken = System.getenv("MAPBOX_TOKEN") ?: ""
        }
        
        manifestPlaceholders["MAPBOX_TOKEN"] = mapboxToken
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
