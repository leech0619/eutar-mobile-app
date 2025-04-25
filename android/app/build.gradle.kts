import java.util.Properties
import java.io.FileInputStream

val dotenv = Properties()
val envFile = rootProject.file(".env")
if (envFile.exists()) {
    FileInputStream(envFile).use { dotenv.load(it) }
}
plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // Google services plugin
    id("kotlin-android") // Kotlin plugin
    id("dev.flutter.flutter-gradle-plugin") // Flutter plugin
}

android {
    namespace = "com.example.eutar"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.eutar"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["MAPS_API_KEY"] = dotenv["GOOGLE_MAPS_API_KEY"].toString() // Ensure it's a string
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug") // Adjust for production signing later
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.11.0"))
    implementation("com.google.firebase:firebase-analytics")
    // Add more dependencies as needed
}
