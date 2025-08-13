import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'screens/shop_setup_screen.dart';
import 'services/shop_service.dart';
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
  try {
    // Minimal initialization to reduce memory usage
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Remove splash screen when initialization is complete
    FlutterNativeSplash.remove();
  } catch (e) {
    print('Error during app initialization: $e');
    FlutterNativeSplash.remove();
  }
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
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  final ShopService _shopService = ShopService();
  bool _isLoading = true;
  Widget? _nextScreen;

  @override
  void initState() {
    super.initState();
    _determineInitialScreen();
  }

  Future<void> _determineInitialScreen() async {
    try {
      // Minimal delay to prevent memory issues
      await Future.delayed(const Duration(milliseconds: 100));
      
      final appStatus = await _shopService.getAppStatus();
      
      if (!appStatus['isLoggedIn']) {
        // User not logged in -> go to login screen
        _nextScreen = const LoginScreen();
      } else if (!appStatus['isSetupComplete']) {
        // User logged in but setup not complete -> go to setup screen
        _nextScreen = const ShopSetupScreen();
      } else {
        // User logged in and setup complete -> go to main screen
        _nextScreen = const MainScreen();
      }
    } catch (e) {
      print('Error determining initial screen: $e');
      // Default to login screen on error
      _nextScreen = const LoginScreen();
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.backgroundPrimary,
                AppColors.backgroundSecondary,
                AppColors.mainColor,
              ],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnMain),
                ),
                SizedBox(height: AppStyles.spacingL),
                Text(
                  'Đang khởi tạo ứng dụng...',
                  style: TextStyle(
                    color: AppColors.textOnMain,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _nextScreen ?? const LoginScreen();
  }
}
