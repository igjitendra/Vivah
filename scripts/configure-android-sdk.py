import os

print("Configuring Android compileSdk 36...")

root_dir = os.getcwd()
android_dir = os.path.join(root_dir, "android")

if not os.path.isdir(android_dir):
    print("No android directory found, skipping.")
    exit(0)

# 1. Update android/build.gradle or android/build.gradle.kts
gradle_kts = os.path.join(android_dir, "build.gradle.kts")
gradle_groovy = os.path.join(android_dir, "build.gradle")

if os.path.isfile(gradle_kts):
    print("Found android/build.gradle.kts, appending subproject compileSdk 36...")
    with open(gradle_kts, "r", encoding="utf-8") as f:
        content = f.read()
    if "compileSdkVersion(36)" not in content:
        subproject_code = """
subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
            android?.compileSdkVersion(36)
        }
    }
}
"""
        with open(gradle_kts, "a", encoding="utf-8") as f:
            f.write(subproject_code)
elif os.path.isfile(gradle_groovy):
    print("Found android/build.gradle, appending subproject compileSdkVersion 36...")
    with open(gradle_groovy, "r", encoding="utf-8") as f:
        content = f.read()
    if "compileSdkVersion 36" not in content:
        subproject_code = """
subprojects {
    afterEvaluate { project ->
        if (project.hasProperty('android')) {
            project.android {
                compileSdkVersion 36
            }
        }
    }
}
"""
        with open(gradle_groovy, "a", encoding="utf-8") as f:
            f.write(subproject_code)

# 2. Update android/app/build.gradle or android/app/build.gradle.kts
app_gradle_kts = os.path.join(android_dir, "app", "build.gradle.kts")
app_gradle_groovy = os.path.join(android_dir, "app", "build.gradle")

if os.path.isfile(app_gradle_kts):
    print("Updating android/app/build.gradle.kts...")
    with open(app_gradle_kts, "r", encoding="utf-8") as f:
        content = f.read()
    content = content.replace("compileSdk = flutter.compileSdkVersion", "compileSdk = 36")
    with open(app_gradle_kts, "w", encoding="utf-8") as f:
        f.write(content)

if os.path.isfile(app_gradle_groovy):
    print("Updating android/app/build.gradle...")
    with open(app_gradle_groovy, "r", encoding="utf-8") as f:
        content = f.read()
    content = content.replace("compileSdkVersion flutter.compileSdkVersion", "compileSdkVersion 36")
    content = content.replace("compileSdk = flutter.compileSdkVersion", "compileSdk = 36")
    with open(app_gradle_groovy, "w", encoding="utf-8") as f:
        f.write(content)

print("Android compileSdk configuration completed successfully!")
