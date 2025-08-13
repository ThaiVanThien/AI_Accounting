import 'package:flutter/material.dart';
import '../services/shop_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import 'shop_setup_screen.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ShopService _shopService = ShopService();
  
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await _shopService.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      setState(() => _isLoading = false);

      if (success) {
        if (mounted) {
          // Check if shop setup is complete
          final isSetupComplete = await _shopService.isSetupComplete();
          
          if (isSetupComplete) {
            // Go directly to main screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const MainScreen(),
              ),
            );
          } else {
            // Go to shop setup screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const ShopSetupScreen(),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tên đăng nhập hoặc mật khẩu không đúng'),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đăng nhập: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(AppStyles.spacingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppStyles.radiusXL),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Title
            Text(
              'Đăng nhập',
              style: AppStyles.headingLarge.copyWith(
                color: AppColors.mainColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppStyles.spacingS),
            Text(
              'Chào mừng bạn quay trở lại!',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppStyles.spacingXL),
            
            // Username field
            TextFormField(
              controller: _usernameController,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Tên đăng nhập',
                hintText: 'Nhập tên đăng nhập',
                prefixIcon: Container(
                  margin: const EdgeInsets.all(AppStyles.spacingS),
                  padding: const EdgeInsets.all(AppStyles.spacingS),
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppStyles.radiusS),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.mainColor,
                    size: 20,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppStyles.radiusL),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppStyles.radiusL),
                  borderSide: const BorderSide(color: AppColors.mainColor, width: 2),
                ),
                filled: true,
                fillColor: AppColors.backgroundLight,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên đăng nhập';
                }
                return null;
              },
            ),
            const SizedBox(height: AppStyles.spacingL),
            
            // Password field
            TextFormField(
              controller: _passwordController,
              enabled: !_isLoading,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                hintText: 'Nhập mật khẩu',
                prefixIcon: Container(
                  margin: const EdgeInsets.all(AppStyles.spacingS),
                  padding: const EdgeInsets.all(AppStyles.spacingS),
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppStyles.radiusS),
                  ),
                  child: const Icon(
                    Icons.lock,
                    color: AppColors.mainColor,
                    size: 20,
                  ),
                ),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: AppColors.textSecondary,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppStyles.radiusL),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppStyles.radiusL),
                  borderSide: const BorderSide(color: AppColors.mainColor, width: 2),
                ),
                filled: true,
                fillColor: AppColors.backgroundLight,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập mật khẩu';
                }
                return null;
              },
            ),
            const SizedBox(height: AppStyles.spacingXL),
            
            // Login button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.mainGradient,
                borderRadius: BorderRadius.circular(AppStyles.radiusL),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.mainColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppStyles.radiusL),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnMain),
                        ),
                      )
                    : Text(
                        'Đăng nhập',
                        style: AppStyles.buttonText.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AppStyles.spacingL),
            
            // Demo credentials info
            Container(
              padding: const EdgeInsets.all(AppStyles.spacingM),
              decoration: BoxDecoration(
                color: AppColors.infoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppStyles.radiusM),
                border: Border.all(
                  color: AppColors.infoColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.infoColor,
                        size: 20,
                      ),
                      const SizedBox(width: AppStyles.spacingS),
                      Text(
                        'Thông tin đăng nhập demo',
                        style: AppStyles.bodyMedium.copyWith(
                          color: AppColors.infoColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppStyles.spacingS),
                  Text(
                    'Tài khoản: huetechcoop\nMật khẩu: dev',
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            stops: [0.0, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppStyles.spacingL),
            child: Column(
              children: [
                const SizedBox(height: AppStyles.spacingXL),
                
                // Logo/Brand section
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: AppColors.mainGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.mainColor.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          size: 60,
                          color: AppColors.textOnMain,
                        ),
                      ),
                      const SizedBox(height: AppStyles.spacingL),
                      Text(
                        'AI Accounting',
                        style: AppStyles.headingLarge.copyWith(
                          color: AppColors.textOnMain,
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                        ),
                      ),
                      const SizedBox(height: AppStyles.spacingS),
                      Text(
                        'Ứng dụng kế toán thông minh cho tiểu thương',
                        style: AppStyles.bodyMedium.copyWith(
                          color: AppColors.textOnMain.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppStyles.spacingXL * 2),
                
                // Login form
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildLoginForm(),
                  ),
                ),
                
                const SizedBox(height: AppStyles.spacingXL),
                
                // Features preview
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(AppStyles.spacingL),
                    decoration: BoxDecoration(
                      color: AppColors.textOnMain.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppStyles.radiusL),
                      border: Border.all(
                        color: AppColors.textOnMain.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Tính năng nổi bật',
                          style: AppStyles.headingSmall.copyWith(
                            color: AppColors.textOnMain,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppStyles.spacingM),
                        Row(
                          children: [
                            Expanded(
                              child: _buildFeatureItem(
                                Icons.smart_toy,
                                'AI Chat',
                                'Nhập liệu bằng giọng nói tự nhiên',
                              ),
                            ),
                            const SizedBox(width: AppStyles.spacingM),
                            Expanded(
                              child: _buildFeatureItem(
                                Icons.inventory,
                                'Quản lý kho',
                                'Theo dõi sản phẩm và tồn kho',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppStyles.spacingM),
                        Row(
                          children: [
                            Expanded(
                              child: _buildFeatureItem(
                                Icons.receipt_long,
                                'Đơn hàng',
                                'Tạo và quản lý đơn hàng dễ dàng',
                              ),
                            ),
                            const SizedBox(width: AppStyles.spacingM),
                            Expanded(
                              child: _buildFeatureItem(
                                Icons.analytics,
                                'Báo cáo',
                                'Thống kê doanh thu chi tiết',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppStyles.spacingM),
          decoration: BoxDecoration(
            color: AppColors.textOnMain.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppStyles.radiusM),
          ),
          child: Icon(
            icon,
            color: AppColors.textOnMain,
            size: 24,
          ),
        ),
        const SizedBox(height: AppStyles.spacingS),
        Text(
          title,
          style: AppStyles.bodyMedium.copyWith(
            color: AppColors.textOnMain,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppStyles.spacingXS),
        Text(
          description,
          style: AppStyles.bodySmall.copyWith(
            color: AppColors.textOnMain.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
