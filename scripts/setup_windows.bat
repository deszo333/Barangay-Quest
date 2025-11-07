@echo off
chcp 65001 >nul
setlocal ENABLEDELAYEDEXPANSION

REM =============================================================
REM  Barangay Quest - Windows Setup Script
REM  This installs tools and prepares the repo for running locally.
REM  Requirements installed (via winget):
REM   - Git, Flutter, Android Studio, OpenJDK 17, Node.js LTS
REM  SDK setup steps:
REM   - Set ANDROID_HOME, install cmdline tools, platform-tools, emulator
REM   - Install Android 34 platform + build-tools, create an AVD (Medium_Phone)
REM   - Accept Android SDK licenses
REM  Project steps:
REM   - flutter pub get (mobile)
REM   - npm ci (web)
REM =============================================================

set REPO_ROOT=%~dp0..
set MOBILE_DIR=%REPO_ROOT%\mobile\barangay_quest_flutter
set ANDROID_HOME_DEFAULT=%LOCALAPPDATA%\Android\Sdk

TITLE Barangay Quest - Windows Setup

REM --- Check for winget ---
where winget >nul 2>nul
if errorlevel 1 (
  echo.
  echo [!] winget not found. Please install Windows Package Manager first:
  echo     https://aka.ms/getwinget
  echo Then re-run this script as Administrator.
  pause
  exit /b 1
)

REM --- Install base tools via winget ---
echo.
echo [1/7] Installing Git...
winget install -e --id Git.Git -h || echo (Git install skipped or already installed)

echo.
echo [2/7] Installing Flutter SDK...
winget install -e --id Flutter.Flutter -h || echo (Flutter install skipped or already installed)

REM Use JDK 17 for Android Gradle Plugin compatibility

echo.
echo [3/7] Installing Microsoft OpenJDK 17...
winget install -e --id Microsoft.OpenJDK.17 -h || echo (OpenJDK 17 skipped or already installed)

REM Android Studio bundles SDK Manager/AVD tools

echo.
echo [4/7] Installing Android Studio...
winget install -e --id Google.AndroidStudio -h || echo (Android Studio skipped or already installed)

REM Node for the web app (optional but recommended)

echo.
echo [5/7] Installing Node.js LTS...
winget install -e --id OpenJS.NodeJS.LTS -h || echo (Node.js LTS skipped or already installed)

REM --- Refresh PATH for this session ---
for /f "usebackq delims=" %%i in (`where flutter 2^>nul`) do set FLUTTER_EXE=%%i
if not defined FLUTTER_EXE (
  echo.
  echo [i] Flutter not yet on PATH for this session. Opening a new terminal later may resolve this.
) else (
  echo.
  echo [i] Found Flutter at: %FLUTTER_EXE%
)

REM --- ANDROID_HOME detection ---
if not defined ANDROID_HOME (
  if exist "%ANDROID_HOME_DEFAULT%" (
    set ANDROID_HOME=%ANDROID_HOME_DEFAULT%
  )
)
if not defined ANDROID_HOME (
  echo.
  echo [i] ANDROID_HOME not set. Attempting to detect default SDK path after Android Studio install...
  if exist "%USERPROFILE%\AppData\Local\Android\Sdk" set ANDROID_HOME=%USERPROFILE%\AppData\Local\Android\Sdk
)
if not defined ANDROID_HOME (
  echo.
  echo [!] Could not find Android SDK. You may need to open Android Studio once to finish the setup.
  echo     After that, re-run this script.
) else (
  echo.
  echo [i] ANDROID_HOME=%ANDROID_HOME%
  setx ANDROID_HOME "%ANDROID_HOME%" >nul
  setx ANDROID_SDK_ROOT "%ANDROID_HOME%" >nul
  set PATH=%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\cmdline-tools\latest\bin;%PATH%
)

REM --- Ensure SDK commandline tools are installed ---
set SDKMANAGER=
where sdkmanager >nul 2>nul && for /f "usebackq delims=" %%i in (`where sdkmanager`) do set SDKMANAGER=%%i
if not defined SDKMANAGER (
  if exist "%ANDROID_HOME%\cmdline-tools\latest\bin\sdkmanager.bat" set SDKMANAGER=%ANDROID_HOME%\cmdline-tools\latest\bin\sdkmanager.bat
)

if defined SDKMANAGER (
  echo.
  echo [6/7] Installing Android SDK components...
  call "%SDKMANAGER%" --install ^
    "cmdline-tools;latest" ^
    "platform-tools" ^
    "platforms;android-34" ^
    "build-tools;34.0.0" ^
    "emulator" ^
    "system-images;android-34;google_apis;x86_64"

  echo.
  echo [i] Accepting Android SDK licenses...
  REM feed many 'y' responses to accept
  (for /l %%n in (1,1,100) do @echo y) | call "%SDKMANAGER%" --licenses

  REM Create an AVD if it doesn't exist
  set AVDMANAGER=%ANDROID_HOME%\cmdline-tools\latest\bin\avdmanager.bat
  if exist "%AVDMANAGER%" (
    echo.
    echo [i] Ensuring an AVD named Medium_Phone exists...
    call "%AVDMANAGER%" list avd | findstr /c:"Name: Medium_Phone" >nul
    if errorlevel 1 (
      call "%AVDMANAGER%" create avd -n Medium_Phone -k "system-images;android-34;google_apis;x86_64" --device "pixel_6" --force
    ) else (
      echo     AVD Medium_Phone already exists.
    )
  ) else (
    echo.
    echo [!] avdmanager not found. You can create an emulator later from Android Studio.
  )
) else (
  echo.
  echo [!] sdkmanager not found. If Android Studio is newly installed, open it once to finish SDK setup, then re-run this script.
)

REM --- Project dependencies ---
if exist "%MOBILE_DIR%\pubspec.yaml" (
  echo.
  echo [7/7] Fetching Flutter packages for the mobile app...
  pushd "%MOBILE_DIR%"
  flutter pub get || (echo [!] Failed to run flutter pub get & popd & goto :END)
  popd
) else (
  echo.
  echo [!] Mobile app directory not found at %MOBILE_DIR%
)

REM Root web app dependencies (optional)
if exist "%REPO_ROOT%\package.json" (
  echo.
  echo [opt] Installing web dependencies with npm ci...
  pushd "%REPO_ROOT%"
  call npm ci || echo [!] npm ci failed (web dependencies will need manual install)
  popd
)

:END
echo.
echo =============================================================
echo  Setup complete (or best-effort). Next steps:
echo    1) Start the Android emulator: ^
      "%ANDROID_HOME%\emulator\emulator.exe" -avd Medium_Phone
echo    2) In a new terminal, run:
echo         cd mobile\barangay_quest_flutter
echo         flutter run -d android

echo  If Flutter or SDK paths are not detected immediately, open a new terminal.
echo =============================================================

echo.
pause
exit /b 0
