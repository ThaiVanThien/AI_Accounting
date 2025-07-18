@echo off
echo.
echo ========================================
echo   AI Accounting - Icon Generator
echo ========================================
echo.

:: Kiểm tra file logo có tồn tại không
if not exist "assets\images\AI_Accounting.jpg" (
    echo ❌ Không tìm thấy file logo!
    echo.
    echo Vui lòng đặt file AI_Accounting.jpg vào thư mục:
    echo assets\images\AI_Accounting.jpg
    echo.
    echo 📋 Đường dẫn đầy đủ: %CD%\assets\images\AI_Accounting.jpg
    echo.
    pause
    exit /b 1
)

:: Kiểm tra file banner có tồn tại không
if not exist "assets\images\Banner_AI.png" (
    echo ❌ Không tìm thấy file banner!
    echo.
    echo Vui lòng đặt file Banner_AI.png vào thư mục:
    echo assets\images\Banner_AI.png
    echo.
    echo 📋 Đường dẫn đầy đủ: %CD%\assets\images\Banner_AI.png
    echo.
    pause
    exit /b 1
)

echo ✅ Đã tìm thấy logo: assets\images\AI_Accounting.jpg
echo ✅ Đã tìm thấy banner: assets\images\Banner_AI.png
echo.

:: Tạo icons
echo 🚀 Đang tạo icons cho tất cả nền tảng...
dart run flutter_launcher_icons:main

if %errorlevel% neq 0 (
    echo.
    echo ❌ Lỗi khi tạo icons!
    pause
    exit /b 1
)

echo.
echo 🎨 Đang tạo splash screen...
dart run flutter_native_splash:create

if %errorlevel% neq 0 (
    echo.
    echo ❌ Lỗi khi tạo icons!
    echo Vui lòng kiểm tra:
    echo 1. File logo có đúng định dạng không
    echo 2. Kích thước logo có đủ lớn không (khuyến nghị 1024x1024)
    echo 3. Chạy flutter pub get trước
    echo.
    pause
    exit /b 1
)

echo.
echo ✅ Tạo icons thành công!
echo.

:: Clean và rebuild
echo 🧹 Đang clean project...
flutter clean

echo 📦 Đang cài đặt lại dependencies...
flutter pub get

echo.
echo 🎉 Hoàn thành! Đã tạo xong:
echo   📱 App Icons (Android, iOS, Web, Windows, macOS)
echo   🎨 Splash Screen (Banner AI)
echo   🌟 Adaptive Icons (Android)
echo.
echo 🚀 Bây giờ bạn có thể build app:
echo   flutter build apk          (Android)
echo   flutter build web          (Web)
echo   flutter run                (Test)
echo.
echo 🎭 Splash screen sẽ hiển thị khi app khởi động!
echo.
pause 