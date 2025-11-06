# Barangay Quest Flutter

Flutter app that mirrors the Barangay Quest website, powered by Firebase Auth, Firestore, and Storage.

## Prerequisites

- Flutter SDK installed and on PATH (3.22+ recommended)
- Dart SDK (bundled with Flutter)
- Firebase project (current web uses projectId: `barangay-quest-mobile`)
- For Android builds: Android Studio + Android SDK

## Current state

- Web is already wired to Firebase via `lib/firebase_options.dart` (Web-only) and runs in Chrome.
- Android/iOS config will be added next either via FlutterFire CLI or manual values from Firebase Console.

## 1) Create platform scaffolding (if missing)

From this folder:

```powershell
flutter create .
```

## 2) Firebase configuration

### Option A: Manual (Web already set; add Android later)

1. In Firebase Console, open your project (e.g., "Barangay Quest Mobile").
2. Add an Android app with the package name shown in `android/app/build.gradle`:
   - applicationId: `com.example.barangay_quest_flutter` (you can rename later to your domain)
3. Copy the Android app config values (apiKey, appId, projectId, messagingSenderId, storageBucket) from Project Settings → Your Apps → Android.
4. Update `lib/firebase_options.dart` to include Android options (we'll do this once you provide the values or we run FlutterFire).
5. Optional: Download `google-services.json` and place it at `android/app/google-services.json`.

### Option B: FlutterFire CLI (recommended when CLI has project access)

```powershell
dart pub global activate flutterfire_cli
flutterfire configure --project=barangay-quest-mobile --platforms=android,ios,web
```

This will create:

- `lib/firebase_options.dart` (multi-platform)
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

## 3) Install dependencies

```powershell
flutter pub get
```

## 4) Run

```powershell
flutter run -d chrome      # web (works today)
flutter run -d android     # Android (after Step 2 + Android Studio/SDK)
```

## Notes

- Collections used: `quests`, `applications`, `users` (same schema as the website).
- Screens included: Login, Signup, Home (latest quests), Find Jobs (search), Quest Detail (apply), Post Job, My Applications, My Quests.
- If FlutterFire CLI can't see your Firebase project, share the project with the Google account logged into your CLI or provide the Android config values so we can add them manually.
