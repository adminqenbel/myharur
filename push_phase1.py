import os
import shutil
import subprocess
import time

def main():
    src_apk = r"d:\harur\frontend\build\app\outputs\flutter-apk\app-release.apk"
    prod_apk = r"d:\harur\myharur.apk"
    static_apk = r"d:\harur\backend\static\myharur.apk"
    
    # Wait up to 60 seconds for the APK to appear
    print("Waiting for APK to finish building...")
    for _ in range(30):
        if os.path.exists(src_apk):
            break
        time.sleep(2)
        
    print("Copying APK...")
    shutil.copy2(src_apk, prod_apk)
    if os.path.exists(os.path.dirname(static_apk)):
        shutil.copy2(src_apk, static_apk)

    print("Committing and pushing to git...")
    subprocess.run(["git", "add", "."], cwd=r"d:\harur", check=True)
    subprocess.run(["git", "commit", "-m", "V4 UI Modernization: Phase 1 & 2 completed (Design System updated)"], cwd=r"d:\harur")
    subprocess.run(["git", "push"], cwd=r"d:\harur", check=True)
    
    print("All done!")

if __name__ == '__main__':
    main()
