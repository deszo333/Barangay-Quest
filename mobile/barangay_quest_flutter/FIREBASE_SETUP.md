# Firebase Setup for Android - Barangay Quest Flutter App

This document provides a comprehensive overview of the Firebase configuration for the Android platform in the Barangay Quest Flutter application.

## ✅ Completed Configuration

### 1. Firebase Project Setup
- **Project ID**: `barangay-quest-mobile`
- **Project Number**: `15772392583`
- **Storage Bucket**: `barangay-quest-mobile.firebasestorage.app`

### 2. Android Application Configuration
- **Package Name**: `com.example.barangay_quest_flutter`
- **App ID**: `1:15772392583:android:0db20735088f3ee92cec22`
- **API Key**: `AIzaSyCv7BDHvfWBjl2Q3lztprHlMxWp6TI-tc8`

### 3. Files Configured

#### `lib/firebase_options.dart`
Contains Firebase configuration for both Web and Android platforms:
```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyCv7BDHvfWBjl2Q3lztprHlMxWp6TI-tc8',
  appId: '1:15772392583:android:0db20735088f3ee92cec22',
  messagingSenderId: '15772392583',
  projectId: 'barangay-quest-mobile',
  storageBucket: 'barangay-quest-mobile.firebasestorage.app',
);
```

#### `android/app/google-services.json`
Google Services configuration file downloaded from Firebase Console. This file is required for Firebase services to work on Android.

#### `android/settings.gradle`
Contains the Google Services plugin declaration:
```gradle
id "com.google.gms.google-services" version "4.4.2" apply false
```

#### `android/app/build.gradle`
- Google Services plugin applied: `id "com.google.gms.google-services"`
- Minimum SDK set to 21 (Firebase requirement)

#### `android/app/src/main/AndroidManifest.xml`
- Added INTERNET permission (required for Firebase network operations)

#### `pubspec.yaml`
Firebase and related packages with explicit versions:
- `firebase_core: ^3.6.0` - Core Firebase functionality
- `firebase_auth: ^5.3.1` - Authentication
- `cloud_firestore: ^5.4.4` - Cloud database
- `firebase_storage: ^12.3.4` - File storage
- `image_picker: ^1.1.2` - For uploading images

#### `lib/main.dart`
Firebase initialization on app startup:
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const BarangayQuestApp());
}
```

### 4. Firebase Services Enabled

The app is configured to use the following Firebase services:

1. **Firebase Authentication** - User login and signup
2. **Cloud Firestore** - Real-time database for quests, applications, and user data
3. **Firebase Storage** - Storage for images and files

## 🔧 Requirements

### Minimum Android Version
- **minSdkVersion**: 21 (Android 5.0 Lollipop)
- **targetSdkVersion**: Uses Flutter default (latest stable)
- **compileSdkVersion**: Uses Flutter default

### Required Permissions
- `INTERNET` - Required for all Firebase network operations

## 📱 Building the App

### Development Build
```bash
cd mobile/barangay_quest_flutter
flutter pub get
flutter run
```

### Production Build (APK)
```bash
flutter build apk --release
```

### Production Build (App Bundle)
```bash
flutter build appbundle --release
```

## 🧪 Testing Firebase Connection

To verify Firebase is working correctly:

1. Run the app on an Android device or emulator
2. Try to sign up or log in
3. Check the Firebase Console to see if authentication events are logged
4. Monitor Firestore to see if data is being written/read

## 📋 Firebase Console Access

Make sure you have access to the Firebase Console:
- Console URL: https://console.firebase.google.com/project/barangay-quest-mobile
- Ensure your email (`esquilloauriell@gmail.com`) is added as a project member

## 🔐 Security Notes

1. The `google-services.json` file contains public configuration data and is safe to commit to version control
2. API keys in this file are safe for client-side use and are protected by Firebase Security Rules
3. Ensure Firebase Security Rules are properly configured in the Firebase Console
4. Never commit service account keys or admin SDK credentials

## 📝 Next Steps for iOS

To add Firebase support for iOS:
1. Create an iOS app in the Firebase Console
2. Download the `GoogleService-Info.plist` file
3. Add it to the iOS project
4. Run `flutterfire configure` to update `firebase_options.dart` with iOS configuration

## 🐛 Troubleshooting

### Common Issues

**Issue**: App crashes on startup with Firebase error
- **Solution**: Make sure `google-services.json` is in the correct location (`android/app/`)

**Issue**: Authentication not working
- **Solution**: Check that Firebase Authentication is enabled in the Firebase Console

**Issue**: Firestore operations failing
- **Solution**: Verify Firestore Security Rules allow read/write operations for authenticated users

**Issue**: Build fails with "Could not resolve com.google.gms:google-services"
- **Solution**: Ensure you have internet connection and the Google Services plugin version is correct

## 📚 Additional Resources

- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Android Setup Guide](https://firebase.google.com/docs/android/setup)
- [Firebase Console](https://console.firebase.google.com/)
