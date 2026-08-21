plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.communityapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        create("release") {
            storeFile = file("release-keystore.jks")
            storePassword = System.getenv("KEYSTORE_STORE_PASSWORD") ?: ""
            keyAlias = System.getenv("KEYSTORE_KEY_ALIAS") ?: ""
            keyPassword = System.getenv("KEYSTORE_KEY_PASSWORD") ?: ""
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.communityapp"

        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion  // Firebase Auth requires min 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
    }


}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// Strip unused Lucide variable font weights before compress step
tasks.register("stripLucideVariableFonts") {
    doLast {
        val dirs = listOf(
            "intermediates/assets/release/mergeReleaseAssets/flutter_assets/packages/lucide_icons_flutter/assets/build_font",
            "intermediates/flutter/release/flutter_assets/packages/lucide_icons_flutter/assets/build_font"
        )
        var count = 0
        dirs.forEach { rel ->
            val dir = layout.buildDirectory.dir(rel).get().asFile
            if (dir.exists()) {
                dir.listFiles()?.filter { it.name.startsWith("LucideVariable") }?.forEach {
                    // Replace with empty file (can't delete - compress task expects it)
                    it.writeBytes(ByteArray(0))
                    count++
                }
            }
        }
        if (count > 0) println("Zeroed $count LucideVariable font files")
    }
}
// Hook before compressReleaseAssets
tasks.configureEach {
    if (name.contains("compressReleaseAssets")) {
        dependsOn("stripLucideVariableFonts")
    }
}
