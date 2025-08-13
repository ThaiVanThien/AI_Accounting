import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();
  
  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _costPriceController;
  late TextEditingController _descriptionController;
  late TextEditingController _stockQuantityController;
  late TextEditingController _minStockLevelController;
  
  String _selectedUnit = 'Cái';
  String _selectedCategory = '';
  bool _isActive = true;
  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.product != null;
    
    _codeController = TextEditingController(text: widget.product?.code ?? '');
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _sellingPriceController = TextEditingController(
      text: widget.product?.sellingPrice.toString() ?? ''
    );
    _costPriceController = TextEditingController(
      text: widget.product?.costPrice.toString() ?? ''
    );
    _descriptionController = TextEditingController(text: widget.product?.description ?? '');
    _stockQuantityController = TextEditingController(
      text: widget.product?.stockQuantity.toString() ?? '0'
    );
    _minStockLevelController = TextEditingController(
      text: widget.product?.minStockLevel.toString() ?? '0'
    );
    
    if (widget.product != null) {
      _selectedUnit = widget.product!.unit;
      _selectedCategory = widget.product!.category;
      _isActive = widget.product!.isActive;
    } else {
      _generateProductCode();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _sellingPriceController.dispose();
    _costPriceController.dispose();
    _descriptionController.dispose();
    _stockQuantityController.dispose();
    _minStockLevelController.dispose();
    super.dispose();
  }

  Future<void> _generateProductCode() async {
    final nextCode = await _productService.getNextProductCode();
    setState(() {
      _codeController.text = nextCode;
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final product = Product(
        id: widget.product?.id ?? '',
        code: _codeController.text.trim(),
        name: _nameController.text.trim(),
        sellingPrice: double.parse(_sellingPriceController.text),
        costPrice: double.parse(_costPriceController.text),
        unit: _selectedUnit,
        description: _descriptionController.text.trim(),
        isActive: _isActive,
        stockQuantity: int.parse(_stockQuantityController.text),
        minStockLevel: int.parse(_minStockLevelController.text),
        category: _selectedCategory,
        createdAt: widget.product?.createdAt,
      );

      bool success;
      if (_isEditMode) {
        success = await _productService.updateProduct(product);
      } else {
        success = await _productService.addProduct(product);
      }

      setState(() => _isLoading = false);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditMode 
                    ? 'Đã cập nhật sản phẩm thành công'
                    : 'Đã thêm sản phẩm thành công'
              ),
              backgroundColor: AppColors.successColor,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditMode 
                    ? 'Không thể cập nhật sản phẩm'
                    : 'Không thể thêm sản phẩm'
              ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
    String? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        prefixIcon: Container(
          margin: const EdgeInsets.all(AppStyles.spacingS),
          padding: const EdgeInsets.all(AppStyles.spacingS),
          decoration: BoxDecoration(
            color: AppColors.mainColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppStyles.radiusS),
          ),
          child: Icon(
            icon,
            color: AppColors.mainColor,
            size: 20,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusM),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusM),
          borderSide: const BorderSide(color: AppColors.mainColor, width: 2),
        ),
        filled: true,
        fillColor: AppColors.backgroundCard,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value.isEmpty ? null : value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Container(
          margin: const EdgeInsets.all(AppStyles.spacingS),
          padding: const EdgeInsets.all(AppStyles.spacingS),
          decoration: BoxDecoration(
            color: AppColors.mainColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppStyles.radiusS),
          ),
          child: Icon(
            icon,
            color: AppColors.mainColor,
            size: 20,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusM),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusM),
          borderSide: const BorderSide(color: AppColors.mainColor, width: 2),
        ),
        filled: true,
        fillColor: AppColors.backgroundCard,
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
    );
  }

  Widget _buildPriceCalculator() {
    double sellingPrice = double.tryParse(_sellingPriceController.text) ?? 0;
    double costPrice = double.tryParse(_costPriceController.text) ?? 0;
    double profit = sellingPrice - costPrice;
    double margin = costPrice > 0 ? (profit / costPrice * 100) : 0;

    return Container(
      padding: const EdgeInsets.all(AppStyles.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppStyles.radiusM),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate, color: AppColors.infoColor, size: 20),
              const SizedBox(width: AppStyles.spacingS),
              Text(
                'Tính toán lợi nhuận',
                style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildCalculatorItem(
                  'Lợi nhuận/sản phẩm',
                  '${profit.toStringAsFixed(0)} VNĐ',
                  profit >= 0 ? AppColors.successColor : AppColors.errorColor,
                ),
              ),
              const SizedBox(width: AppStyles.spacingM),
              Expanded(
                child: _buildCalculatorItem(
                  'Tỷ lệ lợi nhuận',
                  '${margin.toStringAsFixed(1)}%',
                  margin >= 0 ? AppColors.successColor : AppColors.errorColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorItem(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppStyles.spacingS),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppStyles.radiusS),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppStyles.spacingXS),
          Text(
            value,
            style: AppStyles.bodyLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Sửa sản phẩm' : 'Thêm sản phẩm'),
        backgroundColor: AppColors.mainColor,
        foregroundColor: AppColors.textOnMain,
        elevation: 0,
        actions: [
          if (!_isEditMode)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _generateProductCode,
              tooltip: 'Tạo mã mới',
            ),
        ],
      ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppStyles.spacingM),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Basic Information Card
                Container(
                  padding: const EdgeInsets.all(AppStyles.spacingL),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(AppStyles.radiusL),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowLight,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: AppColors.infoColor, size: 24),
                          const SizedBox(width: AppStyles.spacingS),
                          Text(
                            'Thông tin cơ bản',
                            style: AppStyles.headingSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppStyles.spacingL),
                      
                      _buildTextField(
                        controller: _codeController,
                        label: 'Mã sản phẩm *',
                        icon: Icons.qr_code,
                        hint: 'VD: SP000001',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập mã sản phẩm';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppStyles.spacingL),
                      
                      _buildTextField(
                        controller: _nameController,
                        label: 'Tên sản phẩm *',
                        icon: Icons.inventory,
                        hint: 'VD: Nước suối Lavie 500ml',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên sản phẩm';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppStyles.spacingL),
                      
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Mô tả',
                        icon: Icons.description,
                        hint: 'Mô tả chi tiết về sản phẩm',
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppStyles.spacingL),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              label: 'Đơn vị tính *',
                              value: _selectedUnit,
                              items: Product.defaultUnits,
                              icon: Icons.straighten,
                              onChanged: (value) {
                                setState(() {
                                  _selectedUnit = value ?? 'Cái';
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: AppStyles.spacingM),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Nhóm hàng',
                              value: _selectedCategory,
                              items: ['', ...Product.defaultCategories],
                              icon: Icons.category,
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value ?? '';
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppStyles.spacingL),

                // Pricing Information Card
                Container(
                  padding: const EdgeInsets.all(AppStyles.spacingL),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(AppStyles.radiusL),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowLight,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.attach_money, color: AppColors.successColor, size: 24),
                          const SizedBox(width: AppStyles.spacingS),
                          Text(
                            'Thông tin giá',
                            style: AppStyles.headingSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppStyles.spacingL),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _sellingPriceController,
                              label: 'Giá bán *',
                              icon: Icons.sell,
                              hint: '0',
                              suffix: 'VNĐ',
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập giá bán';
                                }
                                final price = double.tryParse(value);
                                if (price == null || price < 0) {
                                  return 'Giá bán không hợp lệ';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppStyles.spacingM),
                          Expanded(
                            child: _buildTextField(
                              controller: _costPriceController,
                              label: 'Giá vốn *',
                              icon: Icons.money,
                              hint: '0',
                              suffix: 'VNĐ',
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập giá vốn';
                                }
                                final price = double.tryParse(value);
                                if (price == null || price < 0) {
                                  return 'Giá vốn không hợp lệ';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppStyles.spacingL),
                      
                      _buildPriceCalculator(),
                    ],
                  ),
                ),

                const SizedBox(height: AppStyles.spacingL),

                // Stock Information Card
                Container(
                  padding: const EdgeInsets.all(AppStyles.spacingL),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(AppStyles.radiusL),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowLight,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.inventory_2, color: AppColors.warningColor, size: 24),
                          const SizedBox(width: AppStyles.spacingS),
                          Text(
                            'Quản lý tồn kho',
                            style: AppStyles.headingSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppStyles.spacingL),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _stockQuantityController,
                              label: 'Số lượng tồn kho',
                              icon: Icons.inventory,
                              hint: '0',
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập số lượng';
                                }
                                final quantity = int.tryParse(value);
                                if (quantity == null || quantity < 0) {
                                  return 'Số lượng không hợp lệ';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppStyles.spacingM),
                          Expanded(
                            child: _buildTextField(
                              controller: _minStockLevelController,
                              label: 'Tồn kho tối thiểu',
                              icon: Icons.warning,
                              hint: '0',
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập số lượng tối thiểu';
                                }
                                final quantity = int.tryParse(value);
                                if (quantity == null || quantity < 0) {
                                  return 'Số lượng không hợp lệ';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppStyles.spacingL),

                // Status Card
                Container(
                  padding: const EdgeInsets.all(AppStyles.spacingL),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(AppStyles.radiusL),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowLight,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.toggle_on, color: AppColors.successColor, size: 24),
                          const SizedBox(width: AppStyles.spacingS),
                          Text(
                            'Trạng thái sản phẩm',
                            style: AppStyles.headingSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppStyles.spacingM),
                      
                      SwitchListTile(
                        title: Text(
                          _isActive ? 'Đang bán' : 'Ngừng bán',
                          style: AppStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _isActive ? AppColors.successColor : AppColors.errorColor,
                          ),
                        ),
                        subtitle: Text(
                          _isActive 
                              ? 'Sản phẩm đang được bán'
                              : 'Sản phẩm tạm ngừng bán',
                          style: AppStyles.bodyMedium,
                        ),
                        value: _isActive,
                        onChanged: (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                        activeColor: AppColors.successColor,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppStyles.spacingXL),

                // Save Button
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.mainGradient,
                    borderRadius: BorderRadius.circular(AppStyles.radiusM),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowMedium,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppStyles.radiusM),
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
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isEditMode ? Icons.save : Icons.add_circle,
                                color: AppColors.textOnMain,
                                size: 24,
                              ),
                              const SizedBox(width: AppStyles.spacingS),
                              Text(
                                _isEditMode ? 'Lưu thay đổi' : 'Thêm sản phẩm',
                                style: AppStyles.buttonText.copyWith(fontSize: 18),
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
}
