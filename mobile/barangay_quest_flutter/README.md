# Barangay Quest Flutter

Flutter mobile app that mirrors the Barangay Quest website, powered by Firebase Auth and Firestore.

## Prerequisites

- Flutter SDK installed and on PATH (3.22+ recommended)
- Dart SDK (bundled with Flutter)
- Firebase project access to the same project used by the web app (projectId: `barangay-quest`)
- FlutterFire CLI installed

## 1) Create platform scaffolding

From this folder:

```powershell
# If not already created by us, generate android/ios/web folders
flutter create .
```

## 2) Add Firebase configuration

Generate `firebase_options.dart` and platform config (google-services.json / GoogleService-Info.plist):

```powershell
# Install FlutterFire CLI if needed
dart pub global activate flutterfire_cli

# Login & link to the existing Firebase project
flutterfire configure --project=barangay-quest --platforms=android,ios,web
```

That command will create:

- lib/firebase_options.dart
- android/app/google-services.json
- ios/Runner/GoogleService-Info.plist

## 3) Install dependencies

```powershell
flutter pub get
```

## 4) Run

```powershell
flutter run -d chrome      # web
flutter run -d windows     # desktop (optional)
flutter run -d android     # Android device
```

## Notes

- The app reads collections `quests`, `applications`, and `users` using the same schema as the web.
- Initial screens include: Login, Signup, Home (latest quests), Find Jobs (search), Quest Detail (apply).
- Extend with Post Job, My Applications, My Quests as next steps.
