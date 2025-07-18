#!/bin/bash

echo ""
echo "========================================"
echo "   AI Accounting - Icon Generator"
echo "========================================"
echo ""

# Kiểm tra file logo có tồn tại không
if [ ! -f "assets/images/AI_Accounting.jpg" ]; then
    echo "❌ Không tìm thấy file logo!"
    echo ""
    echo "Vui lòng đặt file AI_Accounting.jpg vào thư mục:"
    echo "assets/images/AI_Accounting.jpg"
    echo ""
    echo "📋 Đường dẫn đầy đủ: $(pwd)/assets/images/AI_Accounting.jpg"
    echo ""
    exit 1
fi

# Kiểm tra file banner có tồn tại không
if [ ! -f "assets/images/Banner_AI.png" ]; then
    echo "❌ Không tìm thấy file banner!"
    echo ""
    echo "Vui lòng đặt file Banner_AI.png vào thư mục:"
    echo "assets/images/Banner_AI.png"
    echo ""
    echo "📋 Đường dẫn đầy đủ: $(pwd)/assets/images/Banner_AI.png"
    echo ""
    exit 1
fi

echo "✅ Đã tìm thấy logo: assets/images/AI_Accounting.jpg"
echo "✅ Đã tìm thấy banner: assets/images/Banner_AI.png"
echo ""

# Tạo icons
echo "🚀 Đang tạo icons cho tất cả nền tảng..."
dart run flutter_launcher_icons:main

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Lỗi khi tạo icons!"
    exit 1
fi

echo ""
echo "🎨 Đang tạo splash screen..."
dart run flutter_native_splash:create

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Lỗi khi tạo icons!"
    echo "Vui lòng kiểm tra:"
    echo "1. File logo có đúng định dạng không"
    echo "2. Kích thước logo có đủ lớn không (khuyến nghị 1024x1024)"
    echo "3. Chạy flutter pub get trước"
    echo ""
    exit 1
fi

echo ""
echo "✅ Tạo icons thành công!"
echo ""

# Clean và rebuild
echo "🧹 Đang clean project..."
flutter clean

echo "📦 Đang cài đặt lại dependencies..."
flutter pub get

echo ""
echo "🎉 Hoàn thành! Icons đã được tạo cho:"
echo "  📱 Android"
echo "  🍎 iOS"
echo "  🌐 Web"
echo "  💻 Windows"
echo "  🖥️  macOS"
echo ""
echo "🚀 Bây giờ bạn có thể build app:"
echo "  flutter build apk          (Android)"
echo "  flutter build web          (Web)"
echo "  flutter run                (Test)"
echo "" 