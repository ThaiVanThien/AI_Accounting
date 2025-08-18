import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

class CustomerFormScreen extends StatefulWidget {
  final Customer? customer;

  const CustomerFormScreen({super.key, this.customer});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  
  final CustomerService _customerService = CustomerService();
  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.customer != null;
    if (_isEditMode) {
      _nameController.text = widget.customer!.name;
      _phoneController.text = widget.customer!.phone;
      _emailController.text = widget.customer!.email;
      _addressController.text = widget.customer!.address;
      _noteController.text = widget.customer!.note;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final customer = Customer(
        id: widget.customer?.id ?? '',
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        note: _noteController.text.trim(),
      );

      // Kiểm tra validation
      if (!customer.isValid) {
        throw Exception('Vui lòng nhập đầy đủ tên và số điện thoại');
      }

      bool success;
      if (_isEditMode) {
        success = await _customerService.updateCustomer(customer);
      } else {
        success = await _customerService.addCustomer(customer);
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditMode 
                ? 'Cập nhật khách hàng thành công' 
                : 'Thêm khách hàng thành công'),
              backgroundColor: AppColors.successColor,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Không thể lưu khách hàng. Có thể số điện thoại đã tồn tại.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: AppColors.mainColor,
            ),
            const SizedBox(width: AppStyles.spacingS),
            Text(
              label,
              style: AppStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(
                  color: AppColors.errorColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppStyles.spacingS),
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppStyles.radiusM),
            border: Border.all(
              color: AppColors.borderLight,
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            maxLines: maxLines,
            textInputAction: textInputAction,
            style: AppStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppStyles.spacingM,
                vertical: AppStyles.spacingM,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppStyles.spacingL),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Sửa khách hàng' : 'Thêm khách hàng',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.mainGradient,
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            Container(
              margin: const EdgeInsets.only(right: AppStyles.spacingM),
              child: TextButton.icon(
                onPressed: _saveCustomer,
                icon: const Icon(Icons.save, color: Colors.white, size: 20),
                label: const Text(
                  'Lưu',
                  style: TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppStyles.spacingM,
                    vertical: AppStyles.spacingS,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppStyles.radiusM),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppStyles.spacingXL),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppStyles.radiusL),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadowMedium,
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Column(
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.mainColor),
                          ),
                          SizedBox(height: AppStyles.spacingL),
                          Text(
                            'Đang xử lý...',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(
                    isSmallScreen ? AppStyles.spacingM : AppStyles.spacingL,
                  ),
              child: Container(
                padding: EdgeInsets.all(
                  isSmallScreen ? AppStyles.spacingL : AppStyles.spacingXL,
                ),
                margin: const EdgeInsets.only(top: AppStyles.spacingL),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppStyles.radiusXL),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowMedium,
                      blurRadius: 24,
                      offset: Offset(0, 8),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppStyles.spacingM),
                            decoration: BoxDecoration(
                              gradient: AppColors.mainGradient,
                              borderRadius: BorderRadius.circular(AppStyles.radiusL),
                            ),
                            child: Icon(
                              _isEditMode ? Icons.edit : Icons.person_add,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppStyles.spacingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Thông tin khách hàng',
                                  style: AppStyles.headingMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: AppStyles.spacingXS),
                                Text(
                                  _isEditMode 
                                    ? 'Cập nhật thông tin khách hàng'
                                    : 'Thêm khách hàng mới vào hệ thống',
                                  style: AppStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppStyles.spacingXL),

                      // Tên khách hàng
                      _buildTextField(
                        controller: _nameController,
                        label: 'Tên khách hàng',
                        hint: 'Nhập tên khách hàng',
                        icon: Icons.person_outline,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên khách hàng';
                          }
                          return null;
                        },
                      ),

                      // Số điện thoại
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Số điện thoại',
                        hint: 'Nhập số điện thoại',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập số điện thoại';
                          }
                          final phoneRegex = RegExp(r'^[0-9+\-\s()]+$');
                          if (!phoneRegex.hasMatch(value.trim())) {
                            return 'Số điện thoại không hợp lệ';
                          }
                          return null;
                        },
                      ),

                      // Email
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'Nhập email (không bắt buộc)',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(value.trim())) {
                              return 'Email không hợp lệ';
                            }
                          }
                          return null;
                        },
                      ),

                      // Địa chỉ
                      _buildTextField(
                        controller: _addressController,
                        label: 'Địa chỉ',
                        hint: 'Nhập địa chỉ (không bắt buộc)',
                        icon: Icons.location_on_outlined,
                        maxLines: 2,
                      ),

                      // Ghi chú
                      _buildTextField(
                        controller: _noteController,
                        label: 'Ghi chú',
                        hint: 'Nhập ghi chú (không bắt buộc)',
                        icon: Icons.note_outlined,
                        maxLines: 3,
                        textInputAction: TextInputAction.done,
                      ),

                      const SizedBox(height: AppStyles.spacingXL),

                      // Nút lưu
                      Container(
                        height: isSmallScreen ? 50 : 56,
                        decoration: BoxDecoration(
                          gradient: AppColors.mainGradient,
                          borderRadius: BorderRadius.circular(AppStyles.radiusL),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.mainColor.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppStyles.radiusL),
                            onTap: _isLoading ? null : _saveCustomer,
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _isEditMode ? Icons.update : Icons.add,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: AppStyles.spacingS),
                                        Text(
                                          _isEditMode ? 'Cập nhật' : 'Thêm mới',
                                          style: const TextStyle(
                                            fontSize: 16, 
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
                ),
        ),
      ),
    );
  }
}
