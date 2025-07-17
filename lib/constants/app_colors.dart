import 'package:flutter/material.dart';

class AppColors {
  // Main Theme Colors - Semantic Naming
  // 🎨 Để thay đổi màu chủ đạo của toàn bộ app, chỉ cần thay đổi dòng này:
  static const Color mainColor = Color(0xFF2196F3);        // Blue - màu chủ đạo
  
  // Các màu phụ sẽ tự động tính toán dựa trên mainColor
  static const Color mainColorDark = Color(0xFF1976D2);     // Blue dark - màu chủ đạo đậm
  static const Color mainColorLight = Color(0xFF64B5F6);    // Blue light - màu chủ đạo nhạt
  static const Color mainColorAccent = Color(0xFF40C4FF);   // Blue accent - màu nhấn
  
  // Secondary Colors - Functional
  static const Color successColor = Color(0xFF4CAF50);      // Green - thành công
  static const Color warningColor = Color(0xFFFF9800);      // Orange - cảnh báo
  static const Color errorColor = Color(0xFFF44336);        // Red - lỗi
  static const Color infoColor = Color(0xFF2196F3);         // Blue - thông tin
  
  // Background Colors
  static const Color backgroundPrimary = Color(0xFFF5F5F5); // Nền chính
  static const Color backgroundSecondary = Color(0xFFFFFFFF); // Nền phụ
  static const Color backgroundCard = Color(0xFFFFFFFF);     // Nền card
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);       // Text chính
  static const Color textSecondary = Color(0xFF757575);     // Text phụ
  static const Color textHint = Color(0xFF9E9E9E);          // Text gợi ý
  static const Color textOnMain = Color(0xFFFFFFFF);        // Text trên màu chủ đạo
  
  // Border Colors
  static const Color borderLight = Color(0xFFE0E0E0);       // Border nhẹ
  static const Color borderMedium = Color(0xFFBDBDBD);      // Border trung bình
  static const Color borderDark = Color(0xFF9E9E9E);        // Border đậm
  
  // Shadow Colors
  static const Color shadowLight = Color(0x1A000000);       // Bóng nhẹ
  static const Color shadowMedium = Color(0x33000000);      // Bóng trung bình
  static const Color shadowDark = Color(0x4D000000);        // Bóng đậm
  
  // Gradient Colors
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [mainColor, mainColorDark],
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundPrimary, backgroundSecondary],
  );
  
  // 🎨 VÍ DỤ THAY ĐỔI MÀU:
  // Để đổi sang xanh lá: mainColor = Color(0xFF4CAF50)
  // Để đổi sang tím: mainColor = Color(0xFF9C27B0)
  // Để đổi sang đỏ: mainColor = Color(0xFFF44336)
  // Để đổi sang cam: mainColor = Color(0xFFFF9800)
  
  // Deprecated - Để tương thích ngược, sẽ xóa sau
  @deprecated
  static const Color primaryBlue = mainColor;
  @deprecated
  static const Color primaryBlueDark = mainColorDark;
  @deprecated
  static const Color primaryBlueLight = mainColorLight;
  @deprecated
  static const Color primaryBlueAccent = mainColorAccent;
  @deprecated
  static const Color success = successColor;
  @deprecated
  static const Color warning = warningColor;
  @deprecated
  static const Color error = errorColor;
  @deprecated
  static const Color info = infoColor;
  @deprecated
  static const Color backgroundLight = backgroundPrimary;
  @deprecated
  static const Color backgroundWhite = backgroundSecondary;
  @deprecated
  static const Color textOnPrimary = textOnMain;
  @deprecated
  static const LinearGradient primaryGradient = mainGradient;
} 