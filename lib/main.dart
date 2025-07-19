import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'screens/app_router.dart';
import 'screens/business_setup_screen.dart';
import 'screens/main_screen.dart';
import 'constants/app_colors.dart';
import 'constants/app_styles.dart';

void main() async {
  // Preserve native splash screen during app initialization
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
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
  
  // Add any other initialization here (database, services, etc.)
  await _initializeApp();
  
  runApp(const KeToAnApp());
}

// App initialization function
Future<void> _initializeApp() async {
  // Simulate app initialization (replace with actual initialization)
  await Future.delayed(const Duration(seconds: 2));
  
  // You can add actual initialization here:
  // - Database setup
  // - API connections
  // - User preferences loading
  // - etc.
  
  // Remove splash screen when initialization is complete
  FlutterNativeSplash.remove();
}

class KeToAnApp extends StatelessWidget {
  const KeToAnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kế Toán AI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: AppColors.mainColor,
        fontFamily: GoogleFonts.montserrat().fontFamily,
        textTheme: GoogleFonts.montserratTextTheme(),
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
      home: const AppRouter(),
      routes: {
        '/setup': (context) => const BusinessSetupScreen(),
        '/main': (context) => const MainScreen(),
      },
    );
  }
}
