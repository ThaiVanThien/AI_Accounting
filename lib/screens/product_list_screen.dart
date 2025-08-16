import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../utils/format_utils.dart';
import 'product_form_screen.dart';
import '../main.dart'; // Import để sử dụng CommonScreenMixin

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> with CommonScreenMixin {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String _selectedCategory = 'Tất cả';
  bool _showActiveOnly = true;
  bool _showLowStockOnly = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    
    try {
      final products = await _productService.getProducts();
      setState(() {
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải dữ liệu: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    List<Product> filtered = List.from(_products);
    
    // Filter by search query
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((product) {
        return product.name.toLowerCase().contains(query) ||
               product.code.toLowerCase().contains(query) ||
               product.category.toLowerCase().contains(query);
      }).toList();
    }
    
    // Filter by category
    if (_selectedCategory != 'Tất cả') {
      filtered = filtered.where((p) => p.category == _selectedCategory).toList();
    }
    
    // Filter by active status
    if (_showActiveOnly) {
      filtered = filtered.where((p) => p.isActive).toList();
    }
    
    // Filter by low stock
    if (_showLowStockOnly) {
      filtered = filtered.where((p) => p.isLowStock).toList();
    }
    
    setState(() {
      _filteredProducts = filtered;
    });
  }

  Future<void> _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa sản phẩm "${product.name}"?'),
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
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _productService.deleteProduct(product.id);
      if (success) {
        await _loadProducts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã xóa sản phẩm "${product.name}"'),
              backgroundColor: AppColors.successColor,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Không thể xóa sản phẩm'),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
      }
    }
  }

  void _showProductDetails(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titlePadding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        contentPadding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        backgroundColor: Colors.white,
        title: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2, color: AppColors.mainColorDark, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, size: 20, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
          ],
        ),

        content: Container(
          width: 500,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(Icons.confirmation_number, 'Mã sản phẩm:', product.code),
                  _buildDetailRow(Icons.sell, 'Giá bán:', '${FormatUtils.formatCurrency(product.sellingPrice)} VNĐ'),
                  _buildDetailRow(Icons.attach_money, 'Giá vốn:', '${FormatUtils.formatCurrency(product.costPrice)} VNĐ'),
                  _buildDetailRow(Icons.trending_up, 'Lợi nhuận:',
                      '${FormatUtils.formatCurrency(product.profitPerUnit)} VNĐ (${product.profitMargin.toStringAsFixed(1)}%)'),
                  const Divider(),
                  _buildDetailRow(Icons.straighten, 'Đơn vị:', product.unit),
                  _buildDetailRow(Icons.category, 'Nhóm hàng:', product.category.isEmpty ? 'Chưa phân loại' : product.category),
                  const Divider(),
                  _buildDetailRow(Icons.inventory, 'Tồn kho:', '${product.stockQuantity} ${product.unit}'),
                  _buildDetailRow(Icons.warning_amber, 'Tồn kho tối thiểu:', '${product.minStockLevel} ${product.unit}'),
                  _buildDetailRow(Icons.account_balance_wallet, 'Giá trị tồn kho:', '${FormatUtils.formatCurrency(product.stockValue)} VNĐ'),
                  const Divider(),
                  _buildDetailRow(Icons.check_circle, 'Trạng thái:', product.isActive ? 'Đang bán' : 'Ngừng bán'),
                  if (product.description.isNotEmpty)
                    _buildDetailRow(Icons.notes, 'Mô tả:', product.description),
                  if (product.isLowStock)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 22),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Cảnh báo: Tồn kho thấp',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
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
        ),
        actions: [
          /*TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),*/
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _editProduct(product);
            },
            child: const Icon(Icons.edit),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 18),
          const SizedBox(width: 8),
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _editProduct(Product product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormScreen(product: product),
      ),
    );
    
    if (result == true) {
      await _loadProducts();
    }
  }

  void _addProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProductFormScreen(),
      ),
    );
    
    if (result == true) {
      await _loadProducts();
    }
  }

  Widget _buildFilterChips() {
    final categories = ['Tất cả', ...Product.defaultCategories];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppStyles.spacingM),
      child: Column(
        children: [
          // Category filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((category) {
                final isSelected = _selectedCategory == category;
                return Container(
                  margin: const EdgeInsets.only(right: AppStyles.spacingS),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                      _applyFilters();
                    },
                    backgroundColor: AppColors.backgroundCard,
                    selectedColor: AppColors.mainColor.withOpacity(0.2),
                    checkmarkColor: AppColors.mainColor,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.mainColor : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppStyles.spacingS),
          // Other filters
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Chỉ sản phẩm đang bán'),
                  value: _showActiveOnly,
                  onChanged: (value) {
                    setState(() {
                      _showActiveOnly = value ?? true;
                    });
                    _applyFilters();
                  },
                  dense: true,
                  activeColor: AppColors.mainColor,
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Tồn kho thấp'),
                  value: _showLowStockOnly,
                  onChanged: (value) {
                    setState(() {
                      _showLowStockOnly = value ?? false;
                    });
                    _applyFilters();
                  },
                  dense: true,
                  activeColor: AppColors.warningColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final isLowStock = product.isLowStock;
    
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppStyles.spacingM,
        vertical: AppStyles.spacingS,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppStyles.radiusL),
        border: Border.all(
          color: isLowStock ? AppColors.warningColor : AppColors.borderLight,
          width: isLowStock ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppStyles.radiusL),
          onTap: () => _showProductDetails(product),
          child: Padding(
            padding: const EdgeInsets.all(AppStyles.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppStyles.spacingS),
                      decoration: BoxDecoration(
                        color: product.isActive 
                            ? AppColors.successColor.withOpacity(0.1)
                            : AppColors.textSecondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppStyles.radiusS),
                      ),
                      child: Icon(
                        product.isActive ? Icons.inventory : Icons.inventory_2_outlined,
                        color: product.isActive ? AppColors.successColor : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppStyles.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: AppStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppStyles.spacingXS),
                          Text(
                            product.code,
                            style: AppStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _editProduct(product);
                            break;
                          case 'delete':
                            _deleteProduct(product);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: AppStyles.spacingS),
                              Text('Sửa'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: AppColors.errorColor),
                              SizedBox(width: AppStyles.spacingS),
                              Text('Xóa', style: TextStyle(color: AppColors.errorColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: AppStyles.spacingM),
                
                // Price and profit info
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Giá bán',
                        '${FormatUtils.formatCurrency(product.sellingPrice)} VNĐ',
                        AppColors.successColor,
                        Icons.sell,
                      ),
                    ),
                    const SizedBox(width: AppStyles.spacingM),
                    Expanded(
                      child: _buildInfoItem(
                        'Lợi nhuận',
                        '${FormatUtils.formatCurrency(product.profitPerUnit)} VNĐ',
                        product.profitPerUnit >= 0 ? AppColors.successColor : AppColors.errorColor,
                        Icons.trending_up,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppStyles.spacingM),
                
                // Stock and category info
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Tồn kho',
                        '${product.stockQuantity} ${product.unit}',
                        isLowStock ? AppColors.warningColor : AppColors.infoColor,
                        isLowStock ? Icons.warning : Icons.inventory_2,
                      ),
                    ),
                    const SizedBox(width: AppStyles.spacingM),
                    Expanded(
                      child: _buildInfoItem(
                        'Nhóm hàng',
                        product.category.isEmpty ? 'Chưa phân loại' : product.category,
                        AppColors.textSecondary,
                        Icons.category,
                      ),
                    ),
                  ],
                ),
                
                // Low stock warning
                if (isLowStock) ...[
                  const SizedBox(height: AppStyles.spacingM),
                  Container(
                    padding: const EdgeInsets.all(AppStyles.spacingS),
                    decoration: BoxDecoration(
                      color: AppColors.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppStyles.radiusS),
                      border: Border.all(color: AppColors.warningColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: AppColors.warningColor, size: 16),
                        const SizedBox(width: AppStyles.spacingS),
                        Text(
                          'Tồn kho thấp (tối thiểu: ${product.minStockLevel})',
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.warningColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String value, Color color, IconData icon) {
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
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: AppStyles.spacingXS),
              Text(
                title,
                style: AppStyles.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spacingXS),
          Text(
            value,
            style: AppStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppStyles.spacingXL),
            decoration: BoxDecoration(
              color: AppColors.infoColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory,
              size: 64,
              color: AppColors.infoColor,
            ),
          ),
          const SizedBox(height: AppStyles.spacingL),
          Text(
            'Chưa có sản phẩm nào',
            style: AppStyles.headingMedium,
          ),
          const SizedBox(height: AppStyles.spacingM),
          Text(
            'Thêm sản phẩm đầu tiên để bắt đầu quản lý kho hàng',
            style: AppStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppStyles.spacingL),
          ElevatedButton.icon(
            onPressed: _addProduct,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainColor,
              foregroundColor: AppColors.textOnMain,
              padding: const EdgeInsets.symmetric(
                horizontal: AppStyles.spacingL,
                vertical: AppStyles.spacingM,
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Thêm sản phẩm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý sản phẩm'),
        backgroundColor: AppColors.mainColor,
        foregroundColor: AppColors.textOnMain,
        elevation: 0,
        actions: [
          Theme(
            data: Theme.of(context).copyWith(
              popupMenuTheme: PopupMenuThemeData(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,color: Colors.white,),
              onSelected: (value) {
                switch (value) {
                  case 'refresh':
                    _loadProducts();
                    break;
                  case 'shop_info':
                    showShopInfo();
                    break;
                  case 'logout':
                    logout();
                    break;
                }
              },
              itemBuilder: (context) => [
                // Thông tin cửa hàng
                PopupMenuItem(
                  value: 'shop_info',
                  child: Row(
                    children: [
                      Icon(Icons.store, color: Colors.grey),
                      SizedBox(width: AppStyles.spacingS),
                      Flexible(
                        child: Text(
                          'Thông tin cửa hàng',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  enabled: false,
                  height: 0,
                  padding: EdgeInsets.zero,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    height: 1,
                    color: Colors.grey.shade300,
                  ),
                ),
                // Làm mới
                PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: Colors.grey),
                      SizedBox(width: AppStyles.spacingS),
                      Flexible(
                        child: Text(
                          'Làm mới',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),




                // Divider mảnh custom
                PopupMenuItem(
                  enabled: false,
                  height: 0,
                  padding: EdgeInsets.zero,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    height: 1,
                    color: Colors.grey.shade300,
                  ),
                ),

                // Đăng xuất
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: AppColors.errorColor),
                      SizedBox(width: AppStyles.spacingS),
                      Flexible(
                        child: Text(
                          'Đăng xuất',
                          style: TextStyle(
                            color: AppColors.errorColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )

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
        child: Column(
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.all(AppStyles.spacingM),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => _applyFilters(),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm sản phẩm...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppStyles.radiusL),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppStyles.radiusL),
                    borderSide: const BorderSide(color: AppColors.mainColor, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.backgroundCard,
                ),
              ),
            ),

            // Filters
            _buildFilterChips(),

            const SizedBox(height: AppStyles.spacingS),

            // Product list
            Expanded(
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.mainColor),
                ),
              )
                  : _filteredProducts.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(_filteredProducts[index]);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProduct,
        backgroundColor: AppColors.mainColor,
        foregroundColor: AppColors.textOnMain,
        child: const Icon(Icons.add),
      ),
    );
  }
}
