import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../models/shop_info.dart';
import '../services/shop_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

class ShopSetupScreen extends StatefulWidget {
  const ShopSetupScreen({super.key});

  @override
  State<ShopSetupScreen> createState() => _ShopSetupScreenState();
}

class _ShopSetupScreenState extends State<ShopSetupScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ShopService _shopService = ShopService();
  
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _ownerNameController;
  late TextEditingController _taxCodeController;
  
  String _selectedBusinessType = '';
  bool _isLoading = false;
  int _currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _ownerNameController = TextEditingController();
    _taxCodeController = TextEditingController();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _ownerNameController.dispose();
    _taxCodeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _saveShopInfo() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBusinessType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn loại hình kinh doanh'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final shopInfo = ShopInfo(
        id: '1',
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        businessType: _selectedBusinessType,
        ownerName: _ownerNameController.text.trim(),
        taxCode: _taxCodeController.text.trim(),
      );

      final success = await _shopService.setShopInfo(shopInfo);
      await _shopService.markSetupComplete();

      setState(() => _isLoading = false);

      if (success) {
        if (mounted) {
          // Show success animation
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => _SuccessDialog(),
          );
          
          // Navigate to main screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainScreen(),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể lưu thông tin cửa hàng'),
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
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thông tin cửa hàng',
          style: AppStyles.headingMedium.copyWith(
            color: AppColors.mainColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppStyles.spacingS),
        Text(
          'Vui lòng nhập thông tin cơ bản về cửa hàng của bạn',
          style: AppStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppStyles.spacingXL),
        
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Tên cửa hàng *',
            hintText: 'VD: Cửa hàng tạp hóa Minh Anh',
            prefixIcon: Container(
              margin: const EdgeInsets.all(AppStyles.spacingS),
              padding: const EdgeInsets.all(AppStyles.spacingS),
              decoration: BoxDecoration(
                color: AppColors.mainColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppStyles.radiusS),
              ),
              child: const Icon(
                Icons.store,
                color: AppColors.mainColor,
                size: 20,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusM),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusM),
              borderSide: const BorderSide(color: AppColors.mainColor, width: 2),
            ),
            filled: true,
            fillColor: AppColors.backgroundCard,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập tên cửa hàng';
            }
            return null;
          },
        ),
        const SizedBox(height: AppStyles.spacingL),
        
        TextFormField(
          controller: _addressController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Địa chỉ *',
            hintText: 'VD: 123 Đường ABC, Phường XYZ, Quận 1, TP.HCM',
            prefixIcon: Container(
              margin: const EdgeInsets.all(AppStyles.spacingS),
              padding: const EdgeInsets.all(AppStyles.spacingS),
              decoration: BoxDecoration(
                color: AppColors.mainColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppStyles.radiusS),
              ),
              child: const Icon(
                Icons.location_on,
                color: AppColors.mainColor,
                size: 20,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusM),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusM),
              borderSide: const BorderSide(color: AppColors.mainColor, width: 2),
            ),
            filled: true,
            fillColor: AppColors.backgroundCard,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập địa chỉ cửa hàng';
            }
            return null;
          },
        ),
        const SizedBox(height: AppStyles.spacingL),
        
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          decoration: InputDecoration(
            labelText: 'Số điện thoại *',
            hintText: 'VD: 0901234567',
            prefixIcon: Container(
              margin: const EdgeInsets.all(AppStyles.spacingS),
              padding: const EdgeInsets.all(AppStyles.spacingS),
              decoration: BoxDecoration(
                color: AppColors.mainColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppStyles.radiusS),
              ),
              child: const Icon(
                Icons.phone,
                color: AppColors.mainColor,
                size: 20,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusM),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusM),
              borderSide: const BorderSide(color: AppColors.mainColor, width: 2),
            ),
            filled: true,
            fillColor: AppColors.backgroundCard,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập số điện thoại';
            }
            if (value.length < 10) {
              return 'Số điện thoại không hợp lệ';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thông tin liên hệ',
          style: AppStyles.headingMedium.copyWith(
            color: AppColors.mainColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppStyles.spacingS),
        Text(
          'Thông tin liên hệ và loại hình kinh doanh',
          style: AppStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppStyles.spacingXL),
        
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'VD: cuahang@email.com',
            prefixIcon: Container(
              margin: const EdgeInsets.all(AppStyles.spacingS),
              padding: const EdgeInsets.all(AppStyles.spacingS),
              decoration: BoxDecoration(
                color: AppColors.mainColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppStyles.radiusS),
              ),
              child: const Icon(
                Icons.email,
                color: AppColors.mainColor,
                size: 20,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusM),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusM),
              borderSide: const BorderSide(color: AppColors.mainColor, width: 2),
            ),
            filled: true,
            fillColor: AppColors.backgroundCard,
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Email không hợp lệ';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: AppStyles.spacingL),
        
        DropdownButtonFormField<String>(
          value: _selectedBusinessType.isEmpty ? null : _selectedBusinessType,
          onChanged: (value) {
            setState(() {
              _selectedBusinessType = value ?? '';
            });
          },
          decoration: InputDecoration(
            labelText: 'Loại hình kinh doanh *',
            prefixIcon: Container(
              margin: const EdgeInsets.all(AppStyles.spacingS),
              padding: const EdgeInsets.all(AppStyles.spacingS),
              decoration: BoxDecoration(
                color: AppColors.mainColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppStyles.radiusS),
              ),
              child: const Icon(
                Icons.business,
                color: AppColors.mainColor,
                size: 20,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusM),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusM),
              borderSide: const BorderSide(color: AppColors.mainColor, width: 2),
            ),
            filled: true,
            fillColor: AppColors.backgroundCard,
          ),
          items: ShopInfo.defaultBusinessTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(type),
            );
          }).toList(),
        ),
        const SizedBox(height: AppStyles.spacingL),
        
        TextFormField(
          controller: _ownerNameController,
          decoration: InputDecoration(
            labelText: 'Tên chủ cửa hàng',
            hintText: 'VD: Nguyễn Văn A',
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
              borderRadius: BorderRadius.circular(AppStyles.radiusM),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusM),
              borderSide: const BorderSide(color: AppColors.mainColor, width: 2),
            ),
            filled: true,
            fillColor: AppColors.backgroundCard,
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thông tin bổ sung',
          style: AppStyles.headingMedium.copyWith(
            color: AppColors.mainColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppStyles.spacingS),
        Text(
          'Thông tin thuế và xác nhận cuối cùng',
          style: AppStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppStyles.spacingXL),
        
        TextFormField(
          controller: _taxCodeController,
          decoration: InputDecoration(
            labelText: 'Mã số thuế',
            hintText: 'VD: 0123456789',
            prefixIcon: Container(
              margin: const EdgeInsets.all(AppStyles.spacingS),
              padding: const EdgeInsets.all(AppStyles.spacingS),
              decoration: BoxDecoration(
                color: AppColors.mainColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppStyles.radiusS),
              ),
              child: const Icon(
                Icons.receipt_long,
                color: AppColors.mainColor,
                size: 20,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusM),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusM),
              borderSide: const BorderSide(color: AppColors.mainColor, width: 2),
            ),
            filled: true,
            fillColor: AppColors.backgroundCard,
          ),
        ),
        const SizedBox(height: AppStyles.spacingXL),
        
        // Summary card
        Container(
          padding: const EdgeInsets.all(AppStyles.spacingL),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(AppStyles.radiusL),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.preview, color: AppColors.infoColor, size: 20),
                  const SizedBox(width: AppStyles.spacingS),
                  Text(
                    'Xem lại thông tin',
                    style: AppStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.infoColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppStyles.spacingM),
              _buildSummaryRow('Tên cửa hàng:', _nameController.text),
              _buildSummaryRow('Địa chỉ:', _addressController.text),
              _buildSummaryRow('Số điện thoại:', _phoneController.text),
              if (_emailController.text.isNotEmpty)
                _buildSummaryRow('Email:', _emailController.text),
              _buildSummaryRow('Loại hình KD:', _selectedBusinessType),
              if (_ownerNameController.text.isNotEmpty)
                _buildSummaryRow('Chủ cửa hàng:', _ownerNameController.text),
              if (_taxCodeController.text.isNotEmpty)
                _buildSummaryRow('Mã số thuế:', _taxCodeController.text),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(3, (index) {
        final isActive = index <= _currentStep;
        final isCurrent = index == _currentStep;
        
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: index < 2 ? AppStyles.spacingS : 0,
            ),
            child: Column(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.mainColor : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppStyles.spacingS),
                Text(
                  _getStepTitle(index),
                  style: AppStyles.bodySmall.copyWith(
                    color: isCurrent ? AppColors.mainColor : AppColors.textSecondary,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Thông tin cửa hàng';
      case 1:
        return 'Liên hệ & Loại hình';
      case 2:
        return 'Xác nhận';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppStyles.spacingL),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppStyles.spacingM),
                          decoration: BoxDecoration(
                            gradient: AppColors.mainGradient,
                            borderRadius: BorderRadius.circular(AppStyles.radiusM),
                          ),
                          child: const Icon(
                            Icons.store_mall_directory,
                            color: AppColors.textOnMain,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppStyles.spacingM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Thiết lập cửa hàng',
                                style: AppStyles.headingMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Bước ${_currentStep + 1} / 3',
                                style: AppStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppStyles.spacingL),
                    _buildStepIndicator(),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppStyles.spacingL),
                  child: Form(
                    key: _formKey,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
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
                        child: _currentStep == 0
                            ? _buildStep1()
                            : _currentStep == 1
                                ? _buildStep2()
                                : _buildStep3(),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Navigation buttons
              Container(
                padding: const EdgeInsets.all(AppStyles.spacingL),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _previousStep,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: AppStyles.spacingM),
                            side: const BorderSide(color: AppColors.mainColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppStyles.radiusM),
                            ),
                          ),
                          child: Text(
                            'Quay lại',
                            style: AppStyles.buttonText.copyWith(
                              color: AppColors.mainColor,
                            ),
                          ),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: AppStyles.spacingM),
                    Expanded(
                      flex: _currentStep == 0 ? 1 : 2,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: AppColors.mainGradient,
                          borderRadius: BorderRadius.circular(AppStyles.radiusM),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.mainColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading 
                              ? null 
                              : _currentStep < 2 
                                  ? _nextStep 
                                  : _saveShopInfo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppStyles.radiusM),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnMain),
                                  ),
                                )
                              : Text(
                                  _currentStep < 2 ? 'Tiếp tục' : 'Hoàn thành',
                                  style: AppStyles.buttonText.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessDialog extends StatefulWidget {
  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // Auto close after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(AppStyles.spacingXL),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(AppStyles.radiusXL),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.successColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppColors.textOnMain,
                    size: 40,
                  ),
                ),
                const SizedBox(height: AppStyles.spacingL),
                Text(
                  'Thiết lập thành công!',
                  style: AppStyles.headingMedium.copyWith(
                    color: AppColors.successColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppStyles.spacingS),
                Text(
                  'Chào mừng bạn đến với AI Accounting',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
