@echo off
echo.
echo ========================================
echo   AI Accounting - Splash Setup Check
echo ========================================
echo.

echo 🔍 Kiểm tra files cần thiết...
echo.

:: Kiểm tra banner trong assets
if exist "assets\images\Banner_AI.png" (
    echo ✅ Banner trong assets: assets\images\Banner_AI.png
    for %%A in ("assets\images\Banner_AI.png") do echo    Size: %%~zA bytes
) else (
    echo ❌ Banner không tồn tại: assets\images\Banner_AI.png
)

:: Kiểm tra background trong drawable
if exist "android\app\src\main\res\drawable\background.png" (
    echo ✅ Background trong drawable: android\app\src\main\res\drawable\background.png
    for %%A in ("android\app\src\main\res\drawable\background.png") do echo    Size: %%~zA bytes
) else (
    echo ❌ Background không tồn tại: android\app\src\main\res\drawable\background.png
)

echo.
echo 📋 Kiểm tra cấu hình XML...

:: Kiểm tra launch_background.xml
if exist "android\app\src\main\res\drawable\launch_background.xml" (
    echo ✅ launch_background.xml tồn tại
    echo 📄 Nội dung file:
    type "android\app\src\main\res\drawable\launch_background.xml"
) else (
    echo ❌ launch_background.xml không tồn tại
)

echo.
echo 🔧 Các lệnh để sửa nếu cần:
echo.
echo 1. Tạo lại splash screen:
echo    dart run flutter_native_splash:create
echo.
echo 2. Clean và rebuild:
echo    flutter clean
echo    flutter pub get
echo    flutter build apk
echo.
echo 3. Nếu vẫn lỗi, chạy cả 2 lệnh:
echo    dart run flutter_launcher_icons:main
echo    dart run flutter_native_splash:create
echo.

pause 