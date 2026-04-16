import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
require(keystorePropertiesFile.exists()) { "Missing android/key.properties for release signing." }
keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

fun resolveLlvmStripExecutable(): File {
    val sdkDir =
        localProperties.getProperty("sdk.dir")
            ?: System.getenv("ANDROID_HOME")
            ?: System.getenv("ANDROID_SDK_ROOT")
            ?: error("Android SDK path not found in local.properties, ANDROID_HOME, or ANDROID_SDK_ROOT.")

    val preferredNdk = File(
        sdkDir,
        "ndk/${android.ndkVersion}/toolchains/llvm/prebuilt/windows-x86_64/bin/llvm-strip.exe",
    )
    if (preferredNdk.exists()) {
        return preferredNdk
    }

    val fallback = File(sdkDir, "ndk")
        .listFiles()
        ?.sortedByDescending { it.name }
        ?.map { File(it, "toolchains/llvm/prebuilt/windows-x86_64/bin/llvm-strip.exe") }
        ?.firstOrNull { it.exists() }

    return fallback ?: error("Unable to locate llvm-strip.exe in the Android NDK.")
}

android {
    namespace = "com.newtolet.newtolet"
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
        applicationId = "com.newtolet.newtolet"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
            storePassword = keystoreProperties.getProperty("storePassword")
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
        }
    }

    lint {
        abortOnError = false
        checkReleaseBuilds = false
    }

    buildTypes {
        debug {
            // Disable native debug symbol stripping to avoid OOM on low-RAM machines
            packaging {
                jniLibs {
                    keepDebugSymbols += setOf("**/*.so")
                }
            }
        }
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            packaging {
                jniLibs {
                    useLegacyPackaging = true
                }
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

val stripFlutterReleaseSymbols by tasks.registering {
    dependsOn("mergeReleaseNativeLibs")
    dependsOn("stripReleaseDebugSymbols")

    doLast {
        val stripExecutable = resolveLlvmStripExecutable()
        val nativeLibDirs = listOf(
            file("$buildDir/intermediates/merged_native_libs/release/mergeReleaseNativeLibs/out/lib"),
            file("$buildDir/intermediates/stripped_native_libs/release/stripReleaseDebugSymbols/out/lib"),
        )

        nativeLibDirs.forEach { nativeLibDir ->
            if (!nativeLibDir.exists()) {
                return@forEach
            }

            nativeLibDir
                .walkTopDown()
                .filter { it.isFile && it.extension == "so" }
                .forEach { nativeLib ->
                    exec {
                        commandLine(stripExecutable.absolutePath, "--strip-debug", nativeLib.absolutePath)
                    }
                }
        }
    }
}

tasks.matching { task ->
    task.name == "packageRelease" ||
        task.name == "packageReleaseBundle" ||
        task.name == "bundleRelease"
}.configureEach {
    dependsOn(stripFlutterReleaseSymbols)
}
