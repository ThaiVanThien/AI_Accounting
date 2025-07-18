# AI Accounting - Assets Setup Guide

## Tổng quan

Dự án sử dụng 2 package chính để quản lý assets:
- **flutter_launcher_icons**: Tạo app icons cho tất cả platforms
- **flutter_native_splash**: Tạo splash screen với app initialization

## 📱 Flutter Launcher Icons

### Cấu hình trong pubspec.yaml

```yaml
flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/images/AI_Accounting.jpg"
  min_sdk_android: 21
  
  # Android Adaptive Icon (recommended)
  adaptive_icon_background: "#2196F3" # Nền xanh brand
  adaptive_icon_foreground: "assets/images/AI_Accounting.jpg"
  
  # Legacy icon fallback cho old Android versions
  android_legacy: true
  
  # Web PWA configuration  
  web:
    generate: true
    image_path: "assets/images/AI_Accounting.jpg"
    background_color: "#2196F3"
    theme_color: "#2196F3"
    
  # Desktop platforms
  windows:
    generate: true
    image_path: "assets/images/AI_Accounting.jpg"
  macos:
    generate: true
    image_path: "assets/images/AI_Accounting.jpg"
```

### Lệnh tạo icons

```bash
dart run flutter_launcher_icons:main
```

### Platforms được hỗ trợ

- ✅ **Android**: Adaptive icons + legacy fallback
- ✅ **iOS**: All icon sizes (iPhone, iPad, App Store)
- ✅ **Web**: PWA manifest icons
- ✅ **Windows**: Desktop app icon
- ✅ **macOS**: App bundle icon

## 🎨 Flutter Native Splash

### Cấu hình trong pubspec.yaml

```yaml
flutter_native_splash:
  # Sử dụng background_image để stretch image full màn hình
  background_image: "assets/images/Banner_AI.png"
  background_image_dark: "assets/images/Banner_AI.png"
  
  # Platform support
  android: true
  ios: true 
  web: true
  
  # Fullscreen mode (ẩn status bar)
  fullscreen: true
  
  # Android 12+ splash screen configuration
  android_12:
    color: "#2196F3"
    icon_background_color: "#2196F3"
```

### App Initialization trong main.dart

```dart
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  // Preserve splash screen during initialization
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  // Initialize app
  await _initializeApp();
  
  runApp(const KeToAnApp());
}

Future<void> _initializeApp() async {
  // App initialization logic
  await Future.delayed(const Duration(seconds: 2));
  
  // Remove splash when ready
  FlutterNativeSplash.remove();
}
```

### Lệnh tạo splash screen

```bash
dart run flutter_native_splash:create
```

### Features

- ✅ **Full Screen**: Banner_AI.png stretch toàn màn hình
- ✅ **Dark Mode**: Hỗ trợ background_image_dark
- ✅ **App Initialization**: Giữ splash trong khi app khởi tạo
- ✅ **Android 12+**: Adaptive splash với brand colors
- ✅ **Cross Platform**: Android, iOS, Web

## 🔧 Automated Scripts

### Windows (generate_assets.bat)
```bash
./generate_assets.bat
```

### Linux/macOS (generate_assets.sh)
```bash
./generate_assets.sh
```

### Manual Commands
```bash
# 1. Update dependencies
flutter pub get

# 2. Generate icons
dart run flutter_launcher_icons:main

# 3. Generate splash screen
dart run flutter_native_splash:create

# 4. Clean build
flutter clean

# 5. Test build
flutter build apk --debug
```

## 📁 Generated Files

### App Icons
- `android/app/src/main/res/mipmap-*/`: Android icons
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/`: iOS icons
- `web/icons/`: Web PWA icons
- `windows/runner/resources/app_icon.ico`: Windows icon
- `macos/Runner/Assets.xcassets/AppIcon.appiconset/`: macOS icons

### Splash Screen
- `android/app/src/main/res/drawable*/`: Android splash resources
- `ios/Runner/Base.lproj/LaunchScreen.storyboard`: iOS splash
- `web/splash/`: Web splash assets
- `web/index.html`: Updated with splash CSS

## 🚀 Build & Test

```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release

# iOS build
flutter build ios

# Web build
flutter build web
```

## 📝 Notes

1. **Asset Requirements**:
   - App Icon: `assets/images/AI_Accounting.jpg` (1024x1024px recommended)
   - Splash Screen: `assets/images/Banner_AI.png` (Any resolution, will stretch)

2. **Platform Considerations**:
   - Android: Supports both adaptive and legacy icons
   - iOS: Automatically generates all required sizes
   - Web: Creates PWA-ready manifest
   - Desktop: Native platform icons

3. **Troubleshooting**:
   - Always run `flutter clean` after generating assets
   - Test on real devices for splash screen verification
   - Check assets folder structure before running commands

## 🔄 Workflow

1. Update `AI_Accounting.jpg` or `Banner_AI.png` in `assets/images/`
2. Run `./generate_assets.bat` (Windows) or `./generate_assets.sh` (Unix)
3. Test with `flutter build apk --debug`
4. Deploy to target platforms

---

> **Generated by**: flutter_launcher_icons ^0.13.1 + flutter_native_splash ^2.4.6 