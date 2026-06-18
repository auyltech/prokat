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
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
