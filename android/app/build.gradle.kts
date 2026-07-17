import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.firebase.crashlytics")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val releaseKeystoreFile = file("upload-keystore.jks")
val requiredSigningProperties = listOf("keyAlias", "keyPassword", "storePassword")
val hasReleaseSigning =
    releaseKeystoreFile.exists() &&
        requiredSigningProperties.all { keystoreProperties.getProperty(it)?.isNotBlank() == true }

android {
    namespace = "com.dude.dudeapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.dude.dudeapp"
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = releaseKeystoreFile
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        getByName("release") {
            check(hasReleaseSigning) {
                "Release APK signing is not configured. Add android/key.properties and " +
                    "android/app/upload-keystore.jks before running a release build."
            }
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

// Fix Zego iOS ringtone audio session before every Android build.
val applyZegoPatch by tasks.registering(Exec::class) {
    workingDir = rootProject.projectDir.parentFile
    commandLine("dart", "run", "tool/apply_zego_patch.dart")
}
tasks.named("preBuild").configure {
    dependsOn(applyZegoPatch)
}

dependencies {
    // Firebase BoM — keeps all Firebase library versions in sync automatically
    implementation(platform("com.google.firebase:firebase-bom:33.1.0"))

    // Firebase Cloud Messaging — provides FirebaseMessagingService + RemoteMessage
    // that MyFirebaseMessagingService.kt extends
    implementation("com.google.firebase:firebase-messaging")
    implementation("im.zego:zpns-fcm:2.8.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("com.google.android.gms:play-services-auth-api-phone:18.3.0")
    implementation(platform("com.google.firebase:firebase-bom:34.12.0"))

    // Add the dependencies for the Crashlytics and Analytics libraries
    // When using the BoM, you don't specify versions in Firebase library dependencies
    implementation("com.google.firebase:firebase-crashlytics")
    implementation("com.google.firebase:firebase-analytics")
    // Required by flutter_local_notifications on some Android toolchains
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
