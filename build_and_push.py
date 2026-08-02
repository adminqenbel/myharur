import os
import shutil
import subprocess

def main():
    manifest_path = r"d:\harur\frontend\android\app\src\main\AndroidManifest.xml"
    src_apk = r"d:\harur\frontend\build\app\outputs\flutter-apk\app-release.apk"
    
    # Helper to update label
    def update_label(new_label):
        with open(manifest_path, "r", encoding="utf-8") as f:
            content = f.read()
        import re
        content = re.sub(r'android:label="[^"]+"', f'android:label="{new_label}"', content)
        with open(manifest_path, "w", encoding="utf-8") as f:
            f.write(content)

    # 1. Build Beta APK
    # print("Setting label to MyHarur Beta...")
    # update_label("MyHarur Beta")
    # print("Building Beta APK...")
    # subprocess.run([r"d:\flutter\bin\flutter.bat", "build", "apk", "--release"], cwd=r"d:\harur\frontend", check=True)
    
    beta_apk = r"d:\harur\myharur-beta.apk"
    # print("Copying beta APK...")
    # shutil.copy2(src_apk, beta_apk)

    # 2. Build Production APK
    print("Setting label to MyHarur...")
    update_label("MyHarur")
    print("Building production APK...")
    subprocess.run([r"d:\flutter\bin\flutter.bat", "build", "apk", "--release"], cwd=r"d:\harur\frontend", check=True)

    prod_apk = r"d:\harur\myharur.apk"
    print("Copying production APK...")
    shutil.copy2(src_apk, prod_apk)
    
    # Optional: also copy to backend/static if required
    static_apk = r"d:\harur\backend\static\myharur.apk"
    static_beta_apk = r"d:\harur\backend\static\myharur-beta.apk"
    if os.path.exists(os.path.dirname(static_apk)):
        shutil.copy2(src_apk, static_apk)
        shutil.copy2(beta_apk, static_beta_apk)

    # 3. Git commit and push
    print("Committing and pushing to git...")
    subprocess.run(["git", "add", "."], cwd=r"d:\harur", check=True)
    subprocess.run(["git", "commit", "-m", "Update logo and rebuild apk"], cwd=r"d:\harur")
    subprocess.run(["git", "push"], cwd=r"d:\harur", check=True)
    
    print("All done!")

if __name__ == '__main__':
    main()
