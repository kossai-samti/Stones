# Litha

Litha is a private, offline Flutter collection journal. Stones, hunt items,
memories, and photos are stored only on the device.

## Build an Android APK

```powershell
flutter pub get
flutter build apk
```

The resulting APK is at `build\app\outputs\flutter-apk\app-release.apk`.

## Data and photos

Records are stored in an on-device SQLite database. Photos picked from the
camera or gallery are copied into the app's private storage, so the app does
not need an internet connection, a server, or PostgreSQL.

Uninstalling the app removes its private data. Add an export or backup feature
before moving to another phone if the saved collection needs to be retained.
