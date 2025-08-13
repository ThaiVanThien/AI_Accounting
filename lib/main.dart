import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'screens/login_screen.dart';
import 'screens/shop_setup_screen.dart';
import 'screens/product_list_screen.dart';
import 'screens/order_form_screen.dart';
import 'screens/ai_input_screen.dart';
import 'screens/report_screen.dart';
import 'screens/order_list_screen.dart';
import 'services/shop_service.dart';
import 'services/storage_manager.dart';
import 'models/finance_record.dart';
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

// Mixin for common functionality
mixin CommonScreenMixin<T extends StatefulWidget> on State<T> {
  final ShopService _shopService = ShopService();

  void showShopInfo() async {
    final shopInfo = await _shopService.getShopInfo();
    if (shopInfo != null && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.store, color: AppColors.mainColor),
              SizedBox(width: AppStyles.spacingS),
              Text('Thông tin cửa hàng'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Tên cửa hàng:', shopInfo.name),
                _buildInfoRow('Địa chỉ:', shopInfo.address),
                _buildInfoRow('Số điện thoại:', shopInfo.phone),
                if (shopInfo.email.isNotEmpty)
                  _buildInfoRow('Email:', shopInfo.email),
                _buildInfoRow('Loại hình KD:', shopInfo.businessType),
                if (shopInfo.ownerName.isNotEmpty)
                  _buildInfoRow('Chủ cửa hàng:', shopInfo.ownerName),
                if (shopInfo.taxCode.isNotEmpty)
                  _buildInfoRow('Mã số thuế:', shopInfo.taxCode),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi ứng dụng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorColor,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _shopService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}

// MainScreen class merged from main_screen.dart
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with CommonScreenMixin {
  int _currentIndex = 0;
  List<FinanceRecord> _records = [];
  int _nextId = 1;
  bool _isLoading = true;
  
  final StorageManager _storageManager = StorageManager();
  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load dữ liệu từ storage
      final records = await _storageManager.getFinanceRecords();
      final nextId = await _storageManager.getNextId();
      final storageInfo = await _storageManager.getStorageInfo();
      
      setState(() {
        _records = records;
        _nextId = nextId;
        _isLoading = false;
      });
      
      // Hiển thị thông báo về loại storage
      if (mounted && !storageInfo['isPersistentStorageAvailable']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('⚠️ Chỉ sử dụng bộ nhớ tạm thời. Dữ liệu sẽ mất khi thoát app.'),
            backgroundColor: AppColors.warningColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      
      // Khởi tạo screens sau khi load data
      _initializeScreens();
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() {
        _isLoading = false;
      }); 
      _initializeScreens();
    }
  }

  void _initializeScreens() {
    _screens.clear();
    _screens.addAll([
      OrderFormScreen(), // Thay đổi từ OrderListScreen thành OrderFormScreen
      AIInputScreen(
        onAddRecord: _addRecord,
        records: _records,
      ),
      ReportScreen(), // Không cần truyền records nữa
      ProductListScreen(),
    ]);
  }

  Future<void> _addRecord(FinanceRecord record) async {
    try {
      // Tạo record với ID mới
      final newRecord = record.copyWith(id: _nextId);
      
      // Thêm vào danh sách local
      setState(() {
        _records.add(newRecord);
        _nextId++;
      });
      
      // Lưu vào storage
      final success = await _storageManager.addFinanceRecord(newRecord);
      if (success) {
        await _storageManager.setNextId(_nextId);
      } else {
        // Rollback nếu không lưu được
        setState(() {
          _records.removeLast();
          _nextId--;
        });
        throw Exception('Không thể lưu dữ liệu');
      }
      
      // Cập nhật lại screens
      _initializeScreens();
      
    } catch (e) {
      debugPrint('Error adding record: $e');
      // Rollback nếu có lỗi
      setState(() {
        if (_records.isNotEmpty) _records.removeLast();
        _nextId--;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu dữ liệu: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _deleteRecord(int id) async {
    try {
      // Tìm record cần xóa
      final recordIndex = _records.indexWhere((record) => record.id == id);
      if (recordIndex == -1) return;
      
      final deletedRecord = _records[recordIndex];
      
      // Xóa khỏi danh sách local
      setState(() {
        _records.removeAt(recordIndex);
      });
      
      // Xóa khỏi storage
      final success = await _storageManager.deleteFinanceRecord(id);
      if (!success) {
        // Rollback nếu không xóa được
        setState(() {
          _records.insert(recordIndex, deletedRecord);
        });
        throw Exception('Không thể xóa dữ liệu');
      }
      
      // Cập nhật lại screens
      _initializeScreens();
      
      // Hiển thị thông báo thành công
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã xóa giao dịch thành công'),
            backgroundColor: AppColors.successColor,
            action: SnackBarAction(
              label: 'Hoàn tác',
              onPressed: () => _addRecord(deletedRecord),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting record: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa dữ liệu: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _updateRecord(FinanceRecord updatedRecord) async {
    try {
      // Tìm và cập nhật record
      final recordIndex = _records.indexWhere((record) => record.id == updatedRecord.id);
      if (recordIndex == -1) return;
      
      final oldRecord = _records[recordIndex];
      
      setState(() {
        _records[recordIndex] = updatedRecord;
      });
      
      // Lưu lại toàn bộ danh sách
      final success = await _storageManager.saveFinanceRecords(_records);
      if (!success) {
        // Rollback nếu không lưu được
        setState(() {
          _records[recordIndex] = oldRecord;
        });
        throw Exception('Không thể cập nhật dữ liệu');
      }
      
      // Cập nhật lại screens
      _initializeScreens();
      
    } catch (e) {
      debugPrint('Error updating record: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi cập nhật dữ liệu: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.backgroundPrimary,
                AppColors.backgroundSecondary,
              ],
            ),
          ),
          child: Center( 
            child: Column( 
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.mainColor) ,
                ),
                const SizedBox(height: AppStyles.spacingL),
                Text(
                  'Đang tải dữ liệu...', 
                  style: AppStyles.bodyLarge,
                ),
              ],
            ),
          ), 
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
             end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundPrimary,
              AppColors.backgroundSecondary,
            ],
          ),
        ),
        child: _screens.isNotEmpty 
          ? _screens[_currentIndex] 
          : const SizedBox(),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.mainGradient,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppStyles.radiusL),
            topRight: Radius.circular(AppStyles.radiusL),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: 12,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppStyles.radiusL),
            topRight: Radius.circular(AppStyles.radiusL),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: AppColors.textOnMain,
            unselectedItemColor: AppColors.textOnMain.withOpacity(0.6),
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 12,
            ),
            items: [
              BottomNavigationBarItem(
                icon: const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.receipt_long_outlined, size: 26),
                ),
                activeIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.receipt_long, size: 26),
                ),
                label: 'Tạo hóa đơn',
              ),
              const BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.smart_toy_outlined, size: 26),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.smart_toy, size: 26),
                ),
                label: 'AI Chat',
              ),
              const BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.bar_chart_outlined, size: 26),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.bar_chart, size: 26),
                ),
                label: 'Báo cáo',
              ),
              const BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.inventory_outlined, size: 26),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.inventory, size: 26),
                ),
                label: 'Sản phẩm',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
