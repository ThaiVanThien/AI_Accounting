import 'package:flutter/material.dart';

/// Ví dụ về cách thay đổi màu chủ đạo của toàn bộ app chỉ với 1 dòng code
/// 
/// Để thay đổi màu chủ đạo, chỉ cần thay đổi giá trị của mainColor trong app_colors.dart
/// 
/// Ví dụ:
/// - Đổi sang màu xanh lá: static const Color mainColor = Color(0xFF4CAF50);
/// - Đổi sang màu tím: static const Color mainColor = Color(0xFF9C27B0);
/// - Đổi sang màu đỏ: static const Color mainColor = Color(0xFFF44336);
/// - Đổi sang màu cam: static const Color mainColor = Color(0xFFFF9800);
/// 
/// Tất cả các thành phần UI sẽ tự động cập nhật màu mới:
/// - AppBar
/// - Buttons
/// - Input focus border
/// - Navigation bar
/// - Icons
/// - Gradients
/// - Và tất cả các thành phần khác sử dụng mainColor

class ColorExamples {
  // Ví dụ các bộ màu có thể sử dụng
  static const Map<String, Color> colorThemes = {
    'Blue (Current)': Color(0xFF2196F3),      // Xanh dương - hiện tại
    'Green': Color(0xFF4CAF50),               // Xanh lá
    'Purple': Color(0xFF9C27B0),              // Tím
    'Red': Color(0xFFF44336),                 // Đỏ
    'Orange': Color(0xFFFF9800),              // Cam
    'Teal': Color(0xFF009688),                // Xanh ngọc
    'Indigo': Color(0xFF3F51B5),              // Chàm
    'Pink': Color(0xFFE91E63),                // Hồng
    'Brown': Color(0xFF795548),               // Nâu
    'Deep Purple': Color(0xFF673AB7),         // Tím đậm
  };
  
  /// Hướng dẫn thay đổi màu:
  /// 1. Mở file lib/constants/app_colors.dart
  /// 2. Thay đổi dòng: static const Color mainColor = Color(0xFF2196F3);
  /// 3. Thay 0xFF2196F3 bằng mã màu mong muốn
  /// 4. Hot reload để xem thay đổi
  /// 
  /// Ví dụ để đổi sang màu xanh lá:
  /// static const Color mainColor = Color(0xFF4CAF50);
} 