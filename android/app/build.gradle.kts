plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")   
}

android {
    namespace = "com.example.rewirex"

    compileSdk = 36   // ✅ IMPORTANT

    ndkVersion = "27.0.12077973"   // ✅ IMPORTANT

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.rewirex"

        minSdk = flutter.minSdkVersion
        targetSdk = 34   // keep this

        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // ✅ Required for flutter_local_notifications
coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
