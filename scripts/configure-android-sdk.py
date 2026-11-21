#!/usr/bin/env python3
"""
configure-android-sdk.py

Ensures Android compileSdk 36 is configured across:
1. android/app/build.gradle.kts / build.gradle
2. android/gradle.properties
3. Flutter plugins in ~/.pub-cache (fixing compileSdk mismatches such as file_picker / flutter_plugin_android_lifecycle)
"""

import os
import re

print("=" * 60)
print("🔧 Vyavahaar Android SDK Configuration")
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

# 2. Clean android/build.gradle.kts / android/build.gradle of any broken AarMetadata / afterEvaluate overrides
for fname in ["build.gradle.kts", "build.gradle"]:
    fpath = os.path.join(android_dir, fname)
    if os.path.isfile(fpath):
        with open(fpath, "r", encoding="utf-8") as f:
            lines = f.readlines()
        clean_lines = []
        for line in lines:
            if "AarMetadata" in line or "tasks.matching" in line:
                continue
            clean_lines.append(line)
        with open(fpath, "w", encoding="utf-8") as f:
            f.writelines(clean_lines)

# Helper function to patch compileSdk in any gradle file
def patch_compile_sdk(text):
    text = re.sub(r"\bcompileSdkVersion\s*=?\s*(?:[12]\d|3[0-5])\b", "compileSdkVersion 36", text)
    text = re.sub(r"\bcompileSdk\s*=\s*(?:flutter\.compileSdkVersion|[12]\d|3[0-5])\b", "compileSdk = 36", text)
    text = re.sub(r"\bcompileSdk\s+(?:flutter\.compileSdkVersion|[12]\d|3[0-5])\b", "compileSdk 36", text)
    text = re.sub(r"\btargetSdkVersion\s+(?:flutter\.targetSdkVersion|\d+)\b", "targetSdkVersion 35", text)
    text = re.sub(r"\btargetSdk\s*=\s*(?:flutter\.targetSdkVersion|\d+)\b", "targetSdk = 35", text)
    text = re.sub(r"\bminSdkVersion\s+(?:flutter\.minSdkVersion|\d+)\b", "minSdkVersion 21", text)
    text = re.sub(r"\bminSdk\s*=\s*(?:flutter\.minSdkVersion|\d+)\b", "minSdk = 21", text)
    return text

# 3. Update android/app/build.gradle.kts / android/app/build.gradle
app_gradle_kts = os.path.join(android_dir, "app", "build.gradle.kts")
if os.path.isfile(app_gradle_kts):
    with open(app_gradle_kts, "r", encoding="utf-8") as f:
        content = f.read()
    new_content = patch_compile_sdk(content)
    with open(app_gradle_kts, "w", encoding="utf-8") as f:
        f.write(new_content)
    print("✅ Updated android/app/build.gradle.kts to compileSdk = 36")

app_gradle_groovy = os.path.join(android_dir, "app", "build.gradle")
if os.path.isfile(app_gradle_groovy):
    with open(app_gradle_groovy, "r", encoding="utf-8") as f:
        content = f.read()
    new_content = patch_compile_sdk(content)
    with open(app_gradle_groovy, "w", encoding="utf-8") as f:
        f.write(new_content)
    print("✅ Updated android/app/build.gradle to compileSdkVersion 36")

# 4. Patch all downloaded plugins in pub cache to use compileSdkVersion / compileSdk 36
cache_candidates = [
    os.environ.get("PUB_CACHE"),
    os.path.expanduser("~/.pub-cache"),
    "/home/runner/.pub-cache",
    "/root/.pub-cache",
]

visited = set()
for pub_cache in cache_candidates:
    if pub_cache and os.path.isdir(pub_cache) and pub_cache not in visited:
        visited.add(pub_cache)
        print(f"🔍 Scanning pub-cache at {pub_cache} for plugin build.gradle files...")
        patched_count = 0
        for root, _, files in os.walk(pub_cache):
            for file in files:
                if file in ("build.gradle", "build.gradle.kts"):
                    target_file = os.path.join(root, file)
                    try:
                        with open(target_file, "r", encoding="utf-8") as f:
                            file_content = f.read()
                        new_content = patch_compile_sdk(file_content)
                        if new_content != file_content:
                            with open(target_file, "w", encoding="utf-8") as f:
                                f.write(new_content)
                            patched_count += 1
                            plugin_name = os.path.basename(os.path.dirname(os.path.dirname(target_file)))
                            print(f"  ⚡ Patched: {plugin_name}/{file} -> compileSdk 36")
                    except Exception as e:
                        pass
        print(f"✅ Successfully patched {patched_count} pub-cache plugin build files in {pub_cache} to compileSdk 36")

print("=" * 60)
print(" Android configuration completed successfully!")
print("=" * 60)
