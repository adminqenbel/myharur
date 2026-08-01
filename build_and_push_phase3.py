import os
import shutil
import subprocess

def main():
    src_apk = r"d:\harur\frontend\build\app\outputs\flutter-apk\app-release.apk"
    prod_apk = r"d:\harur\myharur.apk"
    static_apk = r"d:\harur\backend\static\myharur.apk"
    
    print("Building Production APK...")
    subprocess.run([r"d:\flutter\bin\flutter.bat", "build", "apk", "--release"], cwd=r"d:\harur\frontend", check=True)
    
    print("Copying APK...")
    shutil.copy2(src_apk, prod_apk)
    if os.path.exists(os.path.dirname(static_apk)):
        shutil.copy2(src_apk, static_apk)

    print("Committing and pushing to git...")
    subprocess.run(["git", "add", "."], cwd=r"d:\harur", check=True)
    subprocess.run(["git", "commit", "-m", "V4 UI Modernization: Phase 3 & 4 completed (Nav and Home Screen)"], cwd=r"d:\harur")
    subprocess.run(["git", "push"], cwd=r"d:\harur", check=True)
    
    print("All done!")

if __name__ == '__main__':
    main()
