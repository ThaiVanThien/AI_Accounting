import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/main_screen.dart';
import 'constants/app_colors.dart';
import 'constants/app_styles.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize locale data
  try {
    await initializeDateFormatting('vi_VN', null);
  } catch (e) {
    print('Failed to initialize Vietnamese locale: $e');
    // Fallback to default locale
    try {
      await initializeDateFormatting();
    } catch (e) {
      print('Failed to initialize default locale: $e');
    }
  }
  
  runApp(const KeToAnApp());
}

class KeToAnApp extends StatelessWidget {
  const KeToAnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kế Toán AI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: AppColors.mainColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.mainColor,
          primary: AppColors.mainColor,
          secondary: AppColors.mainColorLight,
          surface: AppColors.backgroundSecondary,
        ),
        appBarTheme: AppStyles.appBarTheme,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: AppStyles.primaryButtonStyle,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.backgroundSecondary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusM),
            borderSide: const BorderSide(color: AppColors.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusM),
            borderSide: const BorderSide(color: AppColors.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusM),
            borderSide: const BorderSide(color: AppColors.mainColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppStyles.spacingM,
            vertical: AppStyles.spacingS,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusL),
          ),
          color: AppColors.backgroundCard,
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}
