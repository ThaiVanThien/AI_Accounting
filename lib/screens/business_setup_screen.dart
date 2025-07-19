import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../services/storage_service.dart';


class BusinessSetupScreen extends StatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _identityNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  BusinessSector _selectedSector = BusinessSector.trading;
  BusinessType _selectedBusinessType = BusinessType.taxQuota;
  bool _isEcommerceTrading = false;
  bool _hasElectronicInvoice = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _businessNameController.dispose();
    _identityNumberController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
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
              AppColors.primaryBlue,
              AppColors.backgroundWhite,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppStyles.spacingL),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppStyles.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.backgroundWhite,
                  borderRadius: BorderRadius.circular(AppStyles.radiusM),
                ),
                child: const Icon(
                  Icons.business,
                  color: AppColors.primaryBlue,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppStyles.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thiết Lập Thông Tin',
                      style: AppStyles.headingLarge.copyWith(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppStyles.spacingXS),
                    Text(
                      'Cung cấp thông tin để tính thuế chính xác',
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppColors.textOnPrimary.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppStyles.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSection(
              'Thông tin cá nhân',
              Icons.person,
              [
                _buildTextFormField(
                  controller: _nameController,
                  label: 'Họ và tên',
                  hint: 'Nhập họ và tên đầy đủ',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Vui lòng nhập họ và tên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppStyles.spacingM),
                _buildTextFormField(
                  controller: _identityNumberController,
                  label: 'Số định danh cá nhân',
                  hint: '123456789012',
                  icon: Icons.credit_card,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(12),
                  ],
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Vui lòng nhập số định danh';
                    }
                    if (value!.length != 12) {
                      return 'Số định danh phải có 12 chữ số';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppStyles.spacingM),
                _buildTextFormField(
                  controller: _phoneController,
                  label: 'Số điện thoại',
                  hint: '0901234567',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Vui lòng nhập số điện thoại';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppStyles.spacingM),
                _buildTextFormField(
                  controller: _addressController,
                  label: 'Địa chỉ',
                  hint: 'Nhập địa chỉ kinh doanh',
                  icon: Icons.location_on,
                  maxLines: 2,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Vui lòng nhập địa chỉ';
                    }
                    return null;
                  },
                ),
              ],
            ),

            const SizedBox(height: AppStyles.spacingL),

            _buildSection(
              'Thông tin kinh doanh',
              Icons.business_center,
              [
                _buildTextFormField(
                  controller: _businessNameController,
                  label: 'Tên cửa hàng/Tên giao dịch',
                  hint: 'Cửa hàng tạp hóa ABC',
                  icon: Icons.store,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Vui lòng nhập tên cửa hàng';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppStyles.spacingM),
                _buildSectorDropdown(),
                const SizedBox(height: AppStyles.spacingM),
                _buildBusinessTypeSelector(),
              ],
            ),

            const SizedBox(height: AppStyles.spacingL),

            _buildSection(
              'Tùy chọn bổ sung',
              Icons.settings,
              [
                _buildSwitchTile(
                  'Kinh doanh trên sàn thương mại điện tử',
                  'Shopee, Lazada, Tiki, Facebook, Zalo...',
                  _isEcommerceTrading,
                  (value) => setState(() => _isEcommerceTrading = value),
                  Icons.shopping_cart,
                ),
                const SizedBox(height: AppStyles.spacingS),
                _buildSwitchTile(
                  'Sử dụng hóa đơn điện tử',
                  'Hóa đơn điện tử có mã của cơ quan thuế',
                  _hasElectronicInvoice,
                  (value) => setState(() => _hasElectronicInvoice = value),
                  Icons.receipt_long,
                ),
              ],
            ),

            const SizedBox(height: AppStyles.spacingXL),

            _buildSubmitButton(),

            const SizedBox(height: AppStyles.spacingL),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: AppStyles.cardDecoration,
      padding: const EdgeInsets.all(AppStyles.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppStyles.spacingS),
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radiusS),
                ),
                child: Icon(icon, color: AppColors.mainColor, size: 20),
              ),
              const SizedBox(width: AppStyles.spacingS),
              Text(title, style: AppStyles.headingSmall),
            ],
          ),
          const SizedBox(height: AppStyles.spacingL),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.mainColor),
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
        filled: true,
        fillColor: AppColors.backgroundWhite,
      ),
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
    );
  }

  Widget _buildSectorDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppStyles.radiusM),
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppStyles.spacingM),
      child: DropdownButtonFormField<BusinessSector>(
        value: _selectedSector,
        decoration: const InputDecoration(
          labelText: 'Ngành nghề kinh doanh',
          prefixIcon: Icon(Icons.work, color: AppColors.mainColor),
          border: InputBorder.none,
        ),
        onChanged: (value) {
          setState(() {
            _selectedSector = value!;
          });
        },
        validator: (value) {
          if (value == null) {
            return 'Vui lòng chọn ngành nghề';
          }
          return null;
        },
        items: BusinessSector.values.map((sector) {
          return DropdownMenuItem(
            value: sector,
            child: Text(_getSectorDisplayName(sector)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBusinessTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hình thức nộp thuế',
          style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppStyles.spacingS),
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppStyles.radiusM),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              RadioListTile<BusinessType>(
                title: const Text('Thuế khoán'),
                subtitle: const Text('Thuế cố định theo ấn định của cơ quan thuế'),
                value: BusinessType.taxQuota,
                groupValue: _selectedBusinessType,
                onChanged: (value) {
                  setState(() {
                    _selectedBusinessType = value!;
                  });
                },
              ),
              const Divider(height: 1),
              RadioListTile<BusinessType>(
                title: const Text('Kê khai'),
                subtitle: const Text('Tự kê khai theo doanh thu thực tế'),
                value: BusinessType.declaration,
                groupValue: _selectedBusinessType,
                onChanged: (value) {
                  setState(() {
                    _selectedBusinessType = value!;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppStyles.radiusM),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon, color: AppColors.mainColor),
      ),
    );
  }



  Widget _buildSubmitButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mainColor,
          foregroundColor: AppColors.textOnPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusL),
          ),
          elevation: 4,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: AppColors.textOnPrimary,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save, size: 24),
                  const SizedBox(width: AppStyles.spacingS),
                  Text(
                    'Lưu Thông Tin & Bắt Đầu',
                    style: AppStyles.headingSmall.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _getSectorDisplayName(BusinessSector sector) {
    switch (sector) {
      case BusinessSector.agriculture:
        return 'Nông nghiệp - Trồng trọt, chăn nuôi';
      case BusinessSector.aquaculture:
        return 'Thủy sản - Nuôi trồng thủy sản';
      case BusinessSector.forestry:
        return 'Lâm nghiệp - Rừng trồng';
      case BusinessSector.manufacturing:
        return 'Sản xuất - Chế biến';
      case BusinessSector.construction:
        return 'Xây dựng';
      case BusinessSector.trading:
        return 'Thương mại - Mua bán hàng hóa';
      case BusinessSector.agency:
        return 'Đại lý - Môi giới';
      case BusinessSector.transport:
        return 'Vận tải';
      case BusinessSector.restaurant:
        return 'Dịch vụ ăn uống';
      case BusinessSector.accommodation:
        return 'Lưu trú - Khách sạn, nhà nghỉ';
      case BusinessSector.entertainment:
        return 'Giải trí - Karaoke, massage';
      case BusinessSector.rental:
        return 'Cho thuê tài sản';
      case BusinessSector.other:
        return 'Ngành nghề khác';
    }
  }



  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final businessUser = BusinessUser(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        businessName: _businessNameController.text.trim(),
        identityNumber: _identityNumberController.text.trim(),
        address: _addressController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        businessSector: _selectedSector,
        businessType: _selectedBusinessType,
        registrationDate: DateTime.now(),
        isEcommerceTrading: _isEcommerceTrading,
        hasElectronicInvoice: _hasElectronicInvoice,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await StorageService.saveBusinessUser(businessUser);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lưu thông tin: $e'),
            backgroundColor: AppColors.error,
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
} 