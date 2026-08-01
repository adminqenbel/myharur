import os
import shutil
import subprocess

def main():
    # 1. Copy Beta APK
    src_apk = r"d:\harur\frontend\build\app\outputs\flutter-apk\app-release.apk"
    beta_apk = r"d:\harur\myharur-beta.apk"
    print("Copying beta APK...")
    shutil.copy2(src_apk, beta_apk)

    # 2. Update AndroidManifest.xml to production name
    manifest_path = r"d:\harur\frontend\android\app\src\main\AndroidManifest.xml"
    with open(manifest_path, "r", encoding="utf-8") as f:
        content = f.read()
    
    content = content.replace('android:label="MyHarur Beta"', 'android:label="MyHarur"')
    
    with open(manifest_path, "w", encoding="utf-8") as f:
        f.write(content)
    print("Updated AndroidManifest.xml to production label")

    # 3. Build Production APK
    print("Building production APK...")
    subprocess.run([r"d:\flutter\bin\flutter.bat", "build", "apk", "--release"], cwd=r"d:\harur\frontend", check=True)

    # 4. Copy Production APK
    prod_apk = r"d:\harur\myharur.apk"
    print("Copying production APK...")
    shutil.copy2(src_apk, prod_apk)
    
    # Optional: also copy to backend/static if required
    static_apk = r"d:\harur\backend\static\myharur.apk"
    if os.path.exists(os.path.dirname(static_apk)):
        shutil.copy2(src_apk, static_apk)

    # 5. Git commit and push
    print("Committing and pushing to git...")
    subprocess.run(["git", "add", "."], cwd=r"d:\harur", check=True)
    subprocess.run(["git", "commit", "-m", "Version 2026.1.0: Add dedicated beta and prod APKs"], cwd=r"d:\harur")
    subprocess.run(["git", "push"], cwd=r"d:\harur", check=True)
    
    print("All done!")

if __name__ == '__main__':
    main()
