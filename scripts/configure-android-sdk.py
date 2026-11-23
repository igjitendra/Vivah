#!/usr/bin/env python3
"""
configure-android-sdk.py

Configures Android compileSdk to 36, signing configuration, and native library packaging across the generated Android project:
1. Updates android/gradle.properties with:
   - android.suppressUnsupportedCompileSdk=36
2. Configures compileSdk = 36, targetSdk = 35, minSdk = 21 in android/app/build.gradle.kts or android/app/build.gradle
   and ensures applicationId & namespace match com.procsctools.vyavahaar
3. Injects safe v1 + v2 signingConfigs into release buildType (falls back to debug signing if no key.properties)
   so release APK is ALWAYS SIGNED and installable on all Android versions.
4. Updates AndroidManifest.xml:
   - android:label="व्यवहार"
   - strips deprecated android:extractNativeLibs for AGP 8+ packaging compatibility
5. Injects safe subprojects compileSdkVersion 36 block in root build.gradle / build.gradle.kts.
"""

import os
import re

print("=" * 60)
print("🔧 Vyavahaar Android SDK Configuration (compileSdk 36, Signing & Native SQLite)")
print("=" * 60)

root_dir = os.getcwd()
android_dir = os.path.join(root_dir, "android")

if not os.path.isdir(android_dir):
    print("No android directory found at:", android_dir)
    exit(0)

# 1. Update android/gradle.properties
gradle_props = os.path.join(android_dir, "gradle.properties")
if os.path.isfile(gradle_props):
    with open(gradle_props, "r", encoding="utf-8") as f:
        content = f.read()
    new_props = []
    if "android.suppressUnsupportedCompileSdk" not in content:
        new_props.append("android.suppressUnsupportedCompileSdk=36")
    if new_props:
        with open(gradle_props, "a", encoding="utf-8") as f:
            f.write("\n" + "\n".join(new_props) + "\n")
        print("✅ Added properties to gradle.properties:", new_props)
    else:
        print("ℹ️ gradle.properties already configured with required properties")

# 2. Update android/app/build.gradle.kts or android/app/build.gradle
app_gradle_kts = os.path.join(android_dir, "app", "build.gradle.kts")
if os.path.isfile(app_gradle_kts):
    with open(app_gradle_kts, "r", encoding="utf-8") as f:
        content = f.read()
    content = re.sub(r"\bcompileSdk\s*=\s*(?:flutter\.compileSdkVersion|\d+)\b", "compileSdk = 36", content)
    content = re.sub(r"\btargetSdk\s*=\s*(?:flutter\.targetSdkVersion|\d+)\b", "targetSdk = 35", content)
    content = re.sub(r"\bminSdk\s*=\s*(?:flutter\.minSdkVersion|\d+)\b", "minSdk = 21", content)
    content = re.sub(r'applicationId\s*=\s*["\'][^"\']+["\']', 'applicationId = "com.procsctools.vyavahaar"', content)
    content = re.sub(r'namespace\s*=\s*["\'][^"\']+["\']', 'namespace = "com.procsctools.vyavahaar"', content)
    
    # Ensure release signing fallback to debug so APK is never unsigned
    if "signingConfigs.getByName(\"release\")" not in content and "signingConfigs.debug" not in content:
        content = re.sub(r'buildTypes\s*\{\s*release\s*\{', 'buildTypes {\n        release {\n            signingConfig = signingConfigs.getByName("debug")', content)
        
    with open(app_gradle_kts, "w", encoding="utf-8") as f:
        f.write(content)
    print("✅ Configured android/app/build.gradle.kts with compileSdk = 36, applicationId = com.procsctools.vyavahaar")

app_gradle_groovy = os.path.join(android_dir, "app", "build.gradle")
if os.path.isfile(app_gradle_groovy):
    with open(app_gradle_groovy, "r", encoding="utf-8") as f:
        content = f.read()
    content = re.sub(r"\bcompileSdkVersion\s+(?:flutter\.compileSdkVersion|\d+)\b", "compileSdkVersion 36", content)
    content = re.sub(r"\bcompileSdk\s*=\s*(?:flutter\.compileSdkVersion|\d+)\b", "compileSdk = 36", content)
    content = re.sub(r"\btargetSdkVersion\s+(?:flutter\.targetSdkVersion|\d+)\b", "targetSdkVersion 35", content)
    content = re.sub(r"\bminSdkVersion\s+(?:flutter\.minSdkVersion|\d+)\b", "minSdkVersion 21", content)
    content = re.sub(r'applicationId\s+["\'][^"\']+["\']', 'applicationId "com.procsctools.vyavahaar"', content)
    content = re.sub(r'namespace\s+["\'][^"\']+["\']', 'namespace "com.procsctools.vyavahaar"', content)

    # Inject signing config reading key.properties with fallback to debug keystore
    signing_groovy_block = """
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            if (keystorePropertiesFile.exists()) {
                keyAlias keystoreProperties['keyAlias'] ?: 'vyavahaarkey'
                keyPassword keystoreProperties['keyPassword'] ?: 'vyavahaar123'
                storeFile file(keystoreProperties['storeFile'] ?: 'upload-keystore.jks')
                storePassword keystoreProperties['storePassword'] ?: 'vyavahaar123'
            } else if (file('upload-keystore.jks').exists()) {
                keyAlias 'vyavahaarkey'
                keyPassword 'vyavahaar123'
                storeFile file('upload-keystore.jks')
                storePassword 'vyavahaar123'
            }
            v1SigningEnabled true
            v2SigningEnabled true
        }
    }
    buildTypes {
        release {
            signingConfig (keystorePropertiesFile.exists() || file('upload-keystore.jks').exists()) ? signingConfigs.release : signingConfigs.debug
        }
    }
}
"""
    if "keystoreProperties" not in content:
        content += "\n" + signing_groovy_block + "\n"
        print("✅ Injected signing configuration into android/app/build.gradle")

    with open(app_gradle_groovy, "w", encoding="utf-8") as f:
        f.write(content)
    print("✅ Configured android/app/build.gradle with compileSdkVersion 36, applicationId = com.procsctools.vyavahaar")

# 3. Inject safe subprojects block in root android/build.gradle.kts or android/build.gradle
root_gradle_kts = os.path.join(android_dir, "build.gradle.kts")
root_gradle_groovy = os.path.join(android_dir, "build.gradle")

subprojects_kts_block = """
// Force compileSdk 36 across all library subprojects (e.g. file_picker)
subprojects {
    val p = this
    val configureAndroid = {
        if (p.hasProperty("android")) {
            val androidExt = p.extensions.findByName("android")
            if (androidExt != null) {
                try {
                    val method = androidExt.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                    method.invoke(androidExt, 36)
                } catch (_: Throwable) {
                    try {
                        val method = androidExt.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                        method.invoke(androidExt, 36)
                    } catch (_: Throwable) {}
                }
            }
        }
    }
    if (p.state.executed) {
        configureAndroid()
    } else {
        p.afterEvaluate { configureAndroid() }
    }
}
"""

subprojects_groovy_block = """
// Force compileSdk 36 across all library subprojects (e.g. file_picker)
subprojects {
    def configureAndroid = {
        if (project.hasProperty('android')) {
            try {
                project.android {
                    compileSdkVersion 36
                }
            } catch (Throwable ignored) {}
        }
    }
    if (project.state.executed) {
        configureAndroid()
    } else {
        project.afterEvaluate { configureAndroid() }
    }
}
"""

if os.path.isfile(root_gradle_kts):
    with open(root_gradle_kts, "r", encoding="utf-8") as f:
        content = f.read()
    if "Force compileSdk 36" not in content:
        content += "\n" + subprojects_kts_block + "\n"
        with open(root_gradle_kts, "w", encoding="utf-8") as f:
            f.write(content)
        print("✅ Injected subprojects block into root build.gradle.kts")
    else:
        print("ℹ️ Root build.gradle.kts already contains compileSdk 36 subprojects block")

if os.path.isfile(root_gradle_groovy):
    with open(root_gradle_groovy, "r", encoding="utf-8") as f:
        content = f.read()
    if "Force compileSdk 36" not in content:
        content += "\n" + subprojects_groovy_block + "\n"
        with open(root_gradle_groovy, "w", encoding="utf-8") as f:
            f.write(content)
        print("✅ Injected subprojects block into root build.gradle")
    else:
        print("ℹ️ Root build.gradle already contains compileSdk 36 subprojects block")

# 4. Patch AndroidManifest.xml for label, permissions, and package queries
manifest_files = [
    os.path.join(android_dir, "app", "src", "main", "AndroidManifest.xml"),
    os.path.join(android_dir, "app", "src", "debug", "AndroidManifest.xml"),
]

permissions_and_queries = """
    <!-- Contact Book & Intent Permissions for Vyavahaar Offline Contacts Import -->
    <uses-permission android:name="android.permission.READ_CONTACTS" />
    <uses-permission android:name="android.permission.WRITE_CONTACTS" />
    <uses-permission android:name="android.permission.CALL_PHONE" />

    <!-- Android 11+ Package Visibility Queries for Dial, SMS, Mail & WhatsApp -->
    <queries>
        <intent>
            <action android:name="android.intent.action.DIAL" />
            <data android:scheme="tel" />
        </intent>
        <intent>
            <action android:name="android.intent.action.SENDTO" />
            <data android:scheme="smsto" />
        </intent>
        <intent>
            <action android:name="android.intent.action.SENDTO" />
            <data android:scheme="mailto" />
        </intent>
        <package android:name="com.whatsapp" />
        <package android:name="com.whatsapp.w4b" />
    </queries>

    <application"""

for mf in manifest_files:
    if os.path.isfile(mf):
        with open(mf, "r", encoding="utf-8") as f:
            mcontent = f.read()
        # Set label to व्यवहार
        mcontent = re.sub(r'android:label="[^"]*"', 'android:label="व्यवहार"', mcontent)
        # Strip android:extractNativeLibs to prevent AGP 8 PackageAndroidArtifact error
        mcontent = re.sub(r'\s+android:extractNativeLibs="[^"]*"', '', mcontent)
        # Inject permissions if not present
        if "android.permission.READ_CONTACTS" not in mcontent and "<application" in mcontent:
            mcontent = mcontent.replace("<application", permissions_and_queries, 1)
        with open(mf, "w", encoding="utf-8") as f:
            f.write(mcontent)
        print(f"✅ Configured {os.path.relpath(mf, root_dir)} with android:label='व्यवहार' and contacts permissions")

print("=" * 60)
print("🎉 Android configuration completed successfully!")
print("=" * 60)
