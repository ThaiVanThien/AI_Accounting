import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppStyles {
  // Text Styles with Montserrat
  static TextStyle headingLarge = GoogleFonts.montserrat(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static TextStyle headingMedium = GoogleFonts.montserrat(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static TextStyle headingSmall = GoogleFonts.montserrat(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static TextStyle bodyLarge = GoogleFonts.montserrat(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  
  static TextStyle bodyMedium = GoogleFonts.montserrat(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  
  static TextStyle bodySmall = GoogleFonts.montserrat(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textHint,
  );
  
  static TextStyle buttonText = GoogleFonts.montserrat(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnMain,
  );
  
  // Card Styles
  static const BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.backgroundCard,
    borderRadius: BorderRadius.all(Radius.circular(16)),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadowLight,
        blurRadius: 8,
        offset: Offset(0, 4),
      ),
    ],
  );
  
  static const BoxDecoration elevatedCardDecoration = BoxDecoration(
    color: AppColors.backgroundCard,
    borderRadius: BorderRadius.all(Radius.circular(16)),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadowMedium,
        blurRadius: 12,
        offset: Offset(0, 6),
      ),
    ],
  );
  
  // Button Styles
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.mainColor,
    foregroundColor: AppColors.textOnMain,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    textStyle: GoogleFonts.montserrat(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 4,
  );
  
  static final ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.backgroundSecondary,
    foregroundColor: AppColors.mainColor,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    textStyle: GoogleFonts.montserrat(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: AppColors.mainColor),
    ),
    elevation: 2,
  );
  
  // Input Styles
  static const InputDecoration inputDecoration = InputDecoration(
    filled: true,
    fillColor: AppColors.backgroundSecondary,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: AppColors.borderLight),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: AppColors.borderLight),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: AppColors.mainColor, width: 2),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );
  
  // AppBar Style
  static AppBarTheme appBarTheme = AppBarTheme(
    backgroundColor: AppColors.mainColor,
    foregroundColor: AppColors.textOnMain,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: GoogleFonts.montserrat(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.textOnMain,
    ),
  );
  
  // Spacing
  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 16;
  static const double spacingL = 24;
  static const double spacingXL = 32;
  
  // Border Radius
  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 16;
  static const double radiusXL = 24;
} 