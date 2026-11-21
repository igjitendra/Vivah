import os

print("Configuring Android compileSdk 36...")

root_dir = os.getcwd()
android_dir = os.path.join(root_dir, "android")

if not os.path.isdir(android_dir):
    print("No android directory found, skipping.")
    exit(0)

# 1. Update android/gradle.properties
gradle_props = os.path.join(android_dir, "gradle.properties")
if os.path.isfile(gradle_props):
    with open(gradle_props, "a", encoding="utf-8") as f:
        f.write("\nandroid.suppressUnsupportedCompileSdk=36\n")

# 2. Update android/build.gradle or android/build.gradle.kts
gradle_kts = os.path.join(android_dir, "build.gradle.kts")
gradle_groovy = os.path.join(android_dir, "build.gradle")

if os.path.isfile(gradle_kts):
    print("Found android/build.gradle.kts, configuring subprojects via reflection...")
    with open(gradle_kts, "r", encoding="utf-8") as f:
        content = f.read()
    if "compileSdkVersion" not in content:
        subproject_code = """
subprojects {
    afterEvaluate {
        val androidExt = project.extensions.findByName("android")
        if (androidExt != null) {
            try {
                val method = androidExt.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                method.invoke(androidExt, 36)
            } catch (e: Exception) {
                // ignore
            }
        }
    }
}
"""
        with open(gradle_kts, "a", encoding="utf-8") as f:
            f.write(subproject_code)

if os.path.isfile(gradle_groovy):
    print("Found android/build.gradle, configuring subprojects...")
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

# 3. Update android/app/build.gradle.kts or android/app/build.gradle
app_gradle_kts = os.path.join(android_dir, "app", "build.gradle.kts")
app_gradle_groovy = os.path.join(android_dir, "app", "build.gradle")

if os.path.isfile(app_gradle_kts):
    print("Updating android/app/build.gradle.kts compileSdk = 36...")
    with open(app_gradle_kts, "r", encoding="utf-8") as f:
        content = f.read()
    content = content.replace("compileSdk = flutter.compileSdkVersion", "compileSdk = 36")
    with open(app_gradle_kts, "w", encoding="utf-8") as f:
        f.write(content)

if os.path.isfile(app_gradle_groovy):
    print("Updating android/app/build.gradle compileSdkVersion 36...")
    with open(app_gradle_groovy, "r", encoding="utf-8") as f:
        content = f.read()
    content = content.replace("compileSdkVersion flutter.compileSdkVersion", "compileSdkVersion 36")
    content = content.replace("compileSdk = flutter.compileSdkVersion", "compileSdk = 36")
    with open(app_gradle_groovy, "w", encoding="utf-8") as f:
        f.write(content)

print("Android compileSdk configuration completed successfully!")
