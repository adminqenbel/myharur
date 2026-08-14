# Local run and preview

Once the Flutter SDK is responsive, run these commands from the repository root:

```powershell
D:\flutter\bin\flutter.bat pub get
D:\flutter\bin\flutter.bat analyze
D:\flutter\bin\flutter.bat test
D:\flutter\bin\flutter.bat run -d chrome
```

For a Render static-site preview, the build command is:

```powershell
D:\flutter\bin\flutter.bat build web --release
```

Publish the `build/web` directory as the static site output. The backend remains Supabase; do not put any database credential, service-role key, or OAuth client secret in Render or Flutter build arguments.

## Current local limitation

On 2026-08-14 the installed Flutter command started but did not produce any output or complete project scaffolding. The UI source in this repository is complete enough to run after the SDK issue is cleared. Typical local checks are to close stale `dart.exe` Flutter tool processes, confirm the Flutter SDK checkout is healthy, then run `flutter doctor -v`.
