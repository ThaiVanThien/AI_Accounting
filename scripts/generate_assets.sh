#!/bin/bash

echo "========================================"
echo " AI ACCOUNTING - ASSET GENERATION"
echo "========================================"
echo

echo "[1/4] Getting Flutter dependencies..."
flutter pub get

echo
echo "[2/4] Generating app launcher icons..."
dart run flutter_launcher_icons:main

echo
echo "[3/4] Generating splash screen..."
dart run flutter_native_splash:create

echo
echo "[4/4] Cleaning build cache..."
flutter clean

echo
echo "========================================"
echo " ASSET GENERATION COMPLETED!"
echo "========================================"
echo
echo "Generated assets:"
echo "- App Icons: All platforms (Android, iOS, Web, Windows, macOS)"
echo "- Splash Screen: Full-screen Banner_AI.png"
echo "- Android 12+ splash: Adaptive with brand colors"
echo
echo "To test: flutter build apk --debug"
echo 