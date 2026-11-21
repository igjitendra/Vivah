#!/usr/bin/env python3
"""
configure-android-sdk.py

Configures Android compileSdk to 36 across the generated Android project:
1. Updates android/gradle.properties with android.suppressUnsupportedCompileSdk=36
2. Configures compileSdk = 36 in android/app/build.gradle.kts or android/app/build.gradle
3. Injects a safe subprojects afterEvaluate block into root android/build.gradle.kts or
   android/build.gradle to force compileSdkVersion 36 across all plugin subprojects (e.g. file_picker),
   handling already-evaluated projects safely to avoid InvalidUserCodeException.
"""

import os
import re

print("=" * 60)
print("🔧 Vyavahaar Android SDK Configuration (compileSdk 36)")
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
    if "android.suppressUnsupportedCompileSdk" not in content:
        with open(gradle_props, "a", encoding="utf-8") as f:
            f.write("\nandroid.suppressUnsupportedCompileSdk=36\n")
        print("✅ Added android.suppressUnsupportedCompileSdk=36 to gradle.properties")
    else:
        print("ℹ️ gradle.properties already has suppressUnsupportedCompileSdk")

# 2. Update android/app/build.gradle.kts or android/app/build.gradle
app_gradle_kts = os.path.join(android_dir, "app", "build.gradle.kts")
if os.path.isfile(app_gradle_kts):
    with open(app_gradle_kts, "r", encoding="utf-8") as f:
        content = f.read()
    content = re.sub(r"\bcompileSdk\s*=\s*(?:flutter\.compileSdkVersion|\d+)\b", "compileSdk = 36", content)
    content = re.sub(r"\btargetSdk\s*=\s*(?:flutter\.targetSdkVersion|\d+)\b", "targetSdk = 35", content)
    content = re.sub(r"\bminSdk\s*=\s*(?:flutter\.minSdkVersion|\d+)\b", "minSdk = 21", content)
    with open(app_gradle_kts, "w", encoding="utf-8") as f:
        f.write(content)
    print("✅ Configured android/app/build.gradle.kts with compileSdk = 36")

app_gradle_groovy = os.path.join(android_dir, "app", "build.gradle")
if os.path.isfile(app_gradle_groovy):
    with open(app_gradle_groovy, "r", encoding="utf-8") as f:
        content = f.read()
    content = re.sub(r"\bcompileSdkVersion\s+(?:flutter\.compileSdkVersion|\d+)\b", "compileSdkVersion 36", content)
    content = re.sub(r"\bcompileSdk\s*=\s*(?:flutter\.compileSdkVersion|\d+)\b", "compileSdk = 36", content)
    content = re.sub(r"\btargetSdkVersion\s+(?:flutter\.targetSdkVersion|\d+)\b", "targetSdkVersion 35", content)
    content = re.sub(r"\bminSdkVersion\s+(?:flutter\.minSdkVersion|\d+)\b", "minSdkVersion 21", content)
    with open(app_gradle_groovy, "w", encoding="utf-8") as f:
        f.write(content)
    print("✅ Configured android/app/build.gradle with compileSdkVersion 36")

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
        p.afterEvaluate {
            configureAndroid()
        }
    }
}
"""

subprojects_groovy_block = """
// Force compileSdkVersion 36 across all library subprojects (e.g. file_picker)
subprojects { project ->
    def configureAndroid = {
        if (project.hasProperty('android')) {
            project.android {
                compileSdkVersion 36
            }
        }
    }
    if (project.state.executed) {
        configureAndroid()
    } else {
        project.afterEvaluate {
            configureAndroid()
        }
    }
}
"""

if os.path.isfile(root_gradle_kts):
    with open(root_gradle_kts, "r", encoding="utf-8") as f:
        content = f.read()
    if "configureAndroid" not in content and "compileSdkVersion" not in content:
        with open(root_gradle_kts, "a", encoding="utf-8") as f:
            f.write(subprojects_kts_block)
        print("✅ Injected safe subprojects compileSdk 36 block into android/build.gradle.kts")
    else:
        print("ℹ️ android/build.gradle.kts already configured with subprojects compileSdk block")

if os.path.isfile(root_gradle_groovy):
    with open(root_gradle_groovy, "r", encoding="utf-8") as f:
        content = f.read()
    if "configureAndroid" not in content and "compileSdkVersion 36" not in content:
        with open(root_gradle_groovy, "a", encoding="utf-8") as f:
            f.write(subprojects_groovy_block)
        print("✅ Injected safe subprojects compileSdk 36 block into android/build.gradle")
    else:
        print("ℹ️ android/build.gradle already configured with subprojects compileSdk block")

print("=" * 60)
print(" Android configuration completed successfully!")
print("=" * 60)
