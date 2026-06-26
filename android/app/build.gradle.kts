plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Load local.properties so MAPS_API_KEY is available as a Gradle property
val localProps = java.util.Properties()
val localPropsFile = rootProject.file("local.properties")
if (localPropsFile.exists()) {
    localPropsFile.inputStream().use { localProps.load(it) }
}

android {
    namespace = "com.dirtyboxing.datafightcentral"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.dirtyboxing.datafightcentral"
        // minSdk 21 required for Firebase
        minSdk = 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Enable multidex for Firebase
        multiDexEnabled = true

        // Inject Maps API key from local.properties (not committed to VCS)
        // Preferred key name: MAPS_API_KEY_ANDROID
        // Backward-compatible fallback: MAPS_API_KEY
        val androidMapsKey = localProps.getProperty(
            "MAPS_API_KEY_ANDROID",
            localProps.getProperty("MAPS_API_KEY", "")
        )
        resValue("string", "google_maps_key", androidMapsKey)
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.8.0"))
    implementation("com.google.firebase:firebase-analytics-ktx")
    implementation("androidx.multidex:multidex:2.0.1")
}
