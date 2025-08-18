import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';
import '../services/customer_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../utils/format_utils.dart';
import '../screens/order_list_screen.dart';
import '../screens/customer_form_screen.dart';
import '../main.dart';

class OrderFormScreen extends StatefulWidget {
  final Order? order;
  final bool returnToHome;
  final bool hideFloatingButton;

  const OrderFormScreen({
    super.key, 
    this.order, 
    this.returnToHome = false,  
    this.hideFloatingButton = false,
  });

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final OrderService _orderService = OrderService();
  final ProductService _productService = ProductService();
  final CustomerService _customerService = CustomerService();
  
  late TextEditingController _orderNumberController;
  late TextEditingController _noteController;
  late TextEditingController _discountController;
  late TextEditingController _taxController;
  
  DateTime _orderDate = DateTime.now();
  OrderStatus _status = OrderStatus.paid;
  List<OrderItem> _items = [];
  List<Product> _availableProducts = [];
  List<Customer> _availableCustomers = [];
  Customer? _selectedCustomer;
  bool _isLoading = false;
  bool _isEditMode = false;
  bool _isLoadingProducts = true;
  bool _isLoadingCustomers = true;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.order != null;
    
    _orderNumberController = TextEditingController(text: widget.order?.orderNumber ?? '');
    _noteController = TextEditingController(text: widget.order?.note ?? '');
    _discountController = TextEditingController(
      text: widget.order != null ? FormatUtils.formatCurrency(widget.order!.discount) : ''
    );
    _taxController = TextEditingController(
      text: widget.order != null ? FormatUtils.formatCurrency(widget.order!.tax) : ''
    );
    
    if (widget.order != null) {
      _orderDate = widget.order!.orderDate;
      _status = widget.order!.status;
      _items = List.from(widget.order!.items);
      _selectedCustomer = widget.order!.customer;
    } else {
      _generateOrderNumber();
      _selectedCustomer = Customer.walkIn();
    }
    
    // Đảm bảo _selectedCustomer không null
    if (_selectedCustomer == null) {
      _selectedCustomer = Customer.walkIn();
    }
    
         _loadProducts();
    _loadCustomers();
  }

  @override
  void dispose() {
    _orderNumberController.dispose();
    _noteController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    super.dispose();
  } 

  Future<void> _loadProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final products = await _productService.getActiveProducts();
      setState(() {
        _availableProducts = products;
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() => _isLoadingProducts = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải sản phẩm: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoadingCustomers = true);
    try {
      final customers = await _customerService.getActiveCustomers();
      
      setState(() {
        _availableCustomers = customers;
        _isLoadingCustomers = false;
        
        // Kiểm tra và cập nhật _selectedCustomer nếu cần thiết
        if (_selectedCustomer != null) {
          // Nếu _selectedCustomer là walk-in, giữ nguyên
          if (_selectedCustomer!.id == Customer.walkIn().id) { 
            // Không cần làm gì, giữ nguyên walk-in customer
          } else {
            // Kiểm tra xem customer hiện tại có còn trong danh sách không
            final customerExists = customers.any((c) => c.id == _selectedCustomer!.id);
            if (!customerExists) {
              // Nếu customer không còn tồn tại, reset về walk-in
              _selectedCustomer = Customer.walkIn();
            } else {
              // Cập nhật _selectedCustomer với đối tượng mới từ danh sách để tránh lỗi tham chiếu
              try {
                _selectedCustomer = customers.firstWhere((c) => c.id == _selectedCustomer!.id);
              } catch (e) {
                _selectedCustomer = Customer.walkIn();
              }
            }
          }
        } else {
          _selectedCustomer = Customer.walkIn();
        }
      });
    } catch (e) {
      setState(() => _isLoadingCustomers = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải danh sách khách hàng: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _generateOrderNumber() async {
    final nextOrderNumber = await _orderService.getNextOrderNumber(date: _orderDate);
    setState(() {
      _orderNumberController.text = nextOrderNumber;
    });
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.lineTotal);
  double get _discount => FormatUtils.parseCurrency(_discountController.text);
  double get _tax => FormatUtils.parseCurrency(_taxController.text);
  double get _total => _subtotal - _discount + _tax;
  double get _totalCost => _items.fold(0, (sum, item) => sum + item.lineCostTotal);
  double get _profit => _total - _totalCost;

  /// Format quantity hiển thị: decimal cho Kg, integer cho unit khác
  String _formatQuantity(double quantity, String unit) {
    if (unit.toLowerCase() == 'kg') {
      // Remove trailing zeros for decimal
      return quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toString();
    } else {
      // Show as integer for other units
      return quantity.toInt().toString();
    }
  }
 
  /// Trả về customer được chọn hợp lệ, đảm bảo luôn có trong danh sách items
  Customer _getValidSelectedCustomer() {
    // Nếu _selectedCustomer null hoặc _availableCustomers chưa được tải, trả về walk-in
    if (_selectedCustomer == null || _isLoadingCustomers) {
      return Customer.walkIn();
    }
    
    // Nếu là walk-in customer, luôn hợp lệ
    if (_selectedCustomer!.id == Customer.walkIn().id) {
      return _selectedCustomer!;
    }
    
    // Kiểm tra xem customer có trong danh sách không
    final customerExists = _availableCustomers.any((c) => c.id == _selectedCustomer!.id);
    if (customerExists) {
      return _selectedCustomer!;
    }
    
    // Nếu không tồn tại, reset về walk-in
    _selectedCustomer = Customer.walkIn();
    return _selectedCustomer!;
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Kiểm tra đơn hàng có sản phẩm không
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng thêm ít nhất một sản phẩm vào đơn hàng'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    if (_status != OrderStatus.draft) {
      for (final item in _items) {
        final product = _availableProducts.firstWhere(
          (p) => p.id == item.productId,
          orElse: () => Product(
            id: item.productId,
            code: item.productCode,
            name: item.productName,
            sellingPrice: item.unitPrice,
            costPrice: item.costPrice,
            unit: item.unit,
            stockQuantity: 0,
          ),
        );
        
        if (product.stockQuantity < item.quantity) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sản phẩm "${item.productName}" chỉ còn ${product.stockQuantity} ${product.unit} trong kho'),
              backgroundColor: AppColors.warningColor,
              action: SnackBarAction(
                label: 'Xem kho',
                textColor: AppColors.textOnMain,
                onPressed: () {
                  // Có thể thêm navigation đến màn hình quản lý kho
                },
              ),
            ),
          );
          return;
        }
      }
    }

    setState(() => _isLoading = true);
 
         try {
      
      final order = Order(
        id: widget.order?.id ?? '',
        orderNumber: _orderNumberController.text.trim(),
        orderDate: _orderDate,
        status: _status,
        items: _items,
        customer: _selectedCustomer ?? Customer.walkIn(),
        note: _noteController.text.trim(),
        discount: _discount,
        tax: _tax,
        createdAt: widget.order?.createdAt,
             );
      
      bool success;
      if (_isEditMode) {
        success = await _orderService.updateOrder(order);
      } else { 
        success = await _orderService.addOrder(order);
      }

      setState(() => _isLoading = false);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditMode 
                    ? 'Đã cập nhật đơn hàng thành công'
                    : 'Đã tạo đơn hàng thành công'
              ),
              backgroundColor: AppColors.successColor,
            ),
          );
          
          // Hiển thị thông báo về tồn kho nếu đơn hàng không phải draft
          if (_status != OrderStatus.draft) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã cập nhật tồn kho sản phẩm'),
                backgroundColor: AppColors.infoColor,
                duration: Duration(seconds: 2),
              ),
            );
          }
          
          // Handle post-creation navigation
          if (!_isEditMode) {
            if (widget.returnToHome) {
              // From OrderListScreen -> redirect to Home tab "Tạo đơn hàng"
              _navigateToCreateOrderTab();
            } else {
              // From HomeScreen -> show dialog with options
              _showSuccessDialog();
            }
          } else {
            _resetForm();
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditMode 
                    ? 'Không thể cập nhật đơn hàng'
                    : 'Không thể tạo đơn hàng'
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

  void _resetForm() {
    setState(() {
      _orderNumberController.clear();
      _noteController.clear();
      _discountController.clear();
      _taxController.clear();
      _items.clear();
      _orderDate = DateTime.now();
      _status = OrderStatus.paid; // Reset về draft để không cập nhật tồn kho
      _selectedCustomer = Customer.walkIn();
    });
    _generateOrderNumber();
  }

  void _navigateToCreateOrderTab() {
    // Clear all routes and navigate to MainScreen with tab "Tạo đơn hàng" (index 1)
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const MainScreenWithTab(initialTab: 1),
      ),
      (route) => false, // Remove all previous routes
    );
  } 
  
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusXL),
        ),
        title: Row( 
          children: [
            Container(
              padding: const EdgeInsets.all(AppStyles.spacingM),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.successColor,
                    AppColors.successColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppStyles.radiusL),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.successColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: AppStyles.spacingM),
            const Expanded(
              child: Text(
                'Đơn hàng đã tạo!',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: AppColors.successColor,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppStyles.spacingL),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.successColor.withOpacity(0.1),
                    AppColors.successColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppStyles.radiusL),
                border: Border.all(color: AppColors.successColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: AppStyles.spacingM),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thành công!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.successColor,
                          ),
                        ),
                        SizedBox(height: AppStyles.spacingXS),
                        Text(
                          'Đơn hàng đã được tạo và lưu vào hệ thống.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppStyles.spacingL),
            const Text(
              'Bạn muốn làm gì tiếp theo?',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _resetForm(); // Reset form for new order
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Tạo đơn mới'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.mainColor,
              padding: const EdgeInsets.symmetric(
                horizontal: AppStyles.spacingM,
                vertical: AppStyles.spacingS,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderListScreen(),
                ),
              ).then((_) {
                // Reload data when returning
                _loadCustomers();
                _loadProducts();
              });
            },
            icon: const Icon(Icons.list, size: 18),
            label: const Text('Xem danh sách'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.infoColor,
              padding: const EdgeInsets.symmetric(
                horizontal: AppStyles.spacingM,
                vertical: AppStyles.spacingS,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to previous screen
            },
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Quay lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppStyles.spacingL,
                vertical: AppStyles.spacingM,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.radiusM),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addProduct() {
    if (_availableProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không có sản phẩm nào để thêm'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _ProductSelectionDialog(
        products: _availableProducts,
                 onProductSelected: (product, quantity) {
           setState(() {
             final existingIndex = _items.indexWhere((item) => item.productId == product.id);
             if (existingIndex >= 0) {
               // Update existing item
               _items[existingIndex] = _items[existingIndex].copyWith(
                 quantity: _items[existingIndex].quantity + quantity,
               );
             } else {
               // Add new item
               final newItem = OrderItem.fromProduct(product, quantity);
               _items.add(newItem);
             }
           });
           
                      // Force rebuild để cập nhật UI ngay lập tức
           setState(() {});
         },
       ),
     );
   }


  void _removeOrderItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    // Force rebuild để cập nhật UI ngay lập tức
    setState(() {});
  }

  Widget _buildOrderItemCard(OrderItem item, int index) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppStyles.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppStyles.radiusL),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? AppStyles.spacingM : AppStyles.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.productName,
                    style: AppStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(AppStyles.spacingS),
                  decoration: BoxDecoration(
                    color: AppColors.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppStyles.radiusS),
                  ),
                  child: InkWell(
                    onTap: () => _removeOrderItem(index),
                    child: Icon(
                      Icons.delete_outline,
                      size: isSmallScreen ? 18 : 20,
                      color: AppColors.errorColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppStyles.spacingS),
            Text(
              'Mã: ${item.productCode}',
              style: AppStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: isSmallScreen ? 11 : 12,
              ),
            ),
            const SizedBox(height: AppStyles.spacingS),
            Container(
              padding: const EdgeInsets.all(AppStyles.spacingS),
              decoration: BoxDecoration(
                color: AppColors.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppStyles.radiusS),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'SL: ${_formatQuantity(item.quantity, item.unit)} ${item.unit}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Giá: ${FormatUtils.formatCurrency(item.unitPrice)}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 12,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppStyles.spacingXS),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: AppStyles.spacingXS),
                    decoration: BoxDecoration(
                      color: AppColors.successColor,
                      borderRadius: BorderRadius.circular(AppStyles.radiusS),
                    ),
                    child: Text(
                      'Thành tiền: ${FormatUtils.formatCurrency(item.lineTotal)} VNĐ',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Container(
      padding: EdgeInsets.all(
        isSmallScreen ? AppStyles.spacingM : AppStyles.spacingL,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppStyles.radiusXL),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 20,
            offset: Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row - responsive
          Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppStyles.spacingS),
                    decoration: BoxDecoration(
                      color: AppColors.infoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppStyles.radiusS),
                    ),
                    child: Icon(
                      Icons.receipt_long, 
                      color: AppColors.infoColor, 
                      size: isSmallScreen ? 20 : 24,
                    ),
                  ),
                  const SizedBox(width: AppStyles.spacingS),
                  Expanded(
                    child: Text(
                      'Tổng kết đơn hàng',
                      style: AppStyles.headingSmall.copyWith(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (_items.isNotEmpty) ...[
                const SizedBox(height: AppStyles.spacingS),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppStyles.spacingM,
                    vertical: AppStyles.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.infoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppStyles.radiusM),
                    border: Border.all(color: AppColors.infoColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${_items.length} sản phẩm',
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.infoColor,
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppStyles.spacingL),
          
          _buildSummaryRow('Tổng tiền hàng:', _subtotal),
          if (_discount > 0)
            _buildSummaryRow('Giảm giá:', -_discount),
          if (_tax > 0)
            _buildSummaryRow('Thuế:', _tax),
          const Divider(),
          _buildSummaryRow('Tổng cộng:', _total, isTotal: true),
          
          if (_status == OrderStatus.paid) ...[
            const SizedBox(height: AppStyles.spacingM),
            _buildSummaryRow(
              'Lợi nhuận:',
              _profit,
              color: _profit >= 0 ? AppColors.successColor : AppColors.errorColor,
            ),
            _buildSummaryRow(
              'Tỷ lệ lợi nhuận:',
              _total > 0 ? (_profit / _total * 100) : 0,
              suffix: '%',
              color: _profit >= 0 ? AppColors.successColor : AppColors.errorColor,
            ),
          ],
          
          // Hiển thị thông báo nếu không có sản phẩm
          if (_items.isEmpty) ...[
            SizedBox(height: isSmallScreen ? AppStyles.spacingS : AppStyles.spacingM),
            Container(
              padding: EdgeInsets.all(isSmallScreen ? AppStyles.spacingS : AppStyles.spacingM),
              decoration: BoxDecoration(
                color: AppColors.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppStyles.radiusM),
                border: Border.all(color: AppColors.warningColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.warningColor,
                    size: isSmallScreen ? 18 : 20,
                  ),
                  const SizedBox(width: AppStyles.spacingS),
                  Expanded(
                    child: Text(
                      'Chưa có sản phẩm nào. Tổng tiền: 0 VNĐ',
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppColors.warningColor,
                        fontStyle: FontStyle.italic,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isTotal = false, Color? color, String suffix = 'VNĐ'}) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 3 : 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                fontSize: isSmallScreen 
                    ? (isTotal ? 14 : 12)
                    : (isTotal ? 16 : 14),
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppStyles.spacingS),
          Expanded(
            flex: 2,
            child: Text(
              suffix == '%' 
                  ? '${value.toStringAsFixed(1)}$suffix'
                  : '${FormatUtils.formatCurrency(value)} $suffix',
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                fontSize: isSmallScreen 
                    ? (isTotal ? 14 : 12)
                    : (isTotal ? 16 : 14),
                color: color ?? (isTotal ? AppColors.mainColor : AppColors.successColor),
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Flexible(
              child: Text(
                _isEditMode ? 'Sửa đơn hàng' : 'Tạo đơn hàng',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
           color: AppColors.mainColor
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              isSmallScreen ? AppStyles.spacingS : AppStyles.spacingM,
            ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Order Information Card
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
                            'Thông tin đơn hàng',
                            style: AppStyles.headingSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppStyles.spacingL),

                      IgnorePointer(
                        child: TextFormField(
                          controller: _orderNumberController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Số đơn hàng *',
                            prefixIcon: Icon(Icons.receipt_long),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập số đơn hàng';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: AppStyles.spacingL),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                  setState(() {
                                    _orderDate = DateTime.now();
                                  });
                              },
                              child: IgnorePointer(
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                      labelText: 'Ngày đơn hàng *',
                                      prefixIcon: Icon(Icons.calendar_today),
                                      border: OutlineInputBorder(),
                                      enabled: false
                                  ),
                                  child: Text(
                                    DateFormat('dd/MM/yyyy').format(_orderDate),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppStyles.spacingL),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<OrderStatus>(
                              value: _status,
                              onChanged: (value) {
                                setState(() {
                                  _status = value ?? OrderStatus.confirmed;
                                });
                              },
                              decoration: const InputDecoration(
                                labelText: 'Trạng thái *',
                                prefixIcon: Icon(Icons.flag),
                                border: OutlineInputBorder(),
                              ),
                              items: OrderStatus.values.map((status) {
                                return DropdownMenuItem(
                                  value: status,
                                  child: Text(_getStatusDisplayName(status)),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppStyles.spacingL),

                // Customer Information Card
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
                          Icon(Icons.person, color: AppColors.successColor, size: 24),
                          const SizedBox(width: AppStyles.spacingS),
                          Text(
                            'Thông tin khách hàng',
                            style: AppStyles.headingSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppStyles.spacingL),
                      
                      // Customer Selection
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person, color: AppColors.mainColor, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Chọn khách hàng:',
                                  style: AppStyles.bodySmall.copyWith(fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // Customer Dropdown
                            if (_isLoadingCustomers)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else
                              DropdownButtonFormField<Customer>(
                                value: _getValidSelectedCustomer(),
                                decoration: const InputDecoration(
                                  labelText: 'Khách hàng',
                                  border: OutlineInputBorder(),
                                  hintText: 'Chọn khách hàng',
                                ),
                                isExpanded: true,
                                items: [
                                  // Khách lẻ option
                                  DropdownMenuItem<Customer>(
                                    value: Customer.walkIn(),
                                    child: Row(
                                      children: [
                                        Icon(Icons.person, color: Colors.orange),
                                        const SizedBox(width: 8),
                                        const Text('Khách lẻ'),
                                      ],
                                    ),
                                  ),
                                  // Danh sách khách hàng
                                  ..._availableCustomers.map((customer) => 
                                    DropdownMenuItem<Customer>(
                                      value: customer,
                                      child: Row(
                                        children: [
                                          Icon(Icons.person_outline, color: AppColors.mainColor),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  customer.name,
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                if (customer.phone.isNotEmpty)
                                                  Text(
                                                    customer.phone,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600], 
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (Customer? value) {
                                  setState(() {
                                    _selectedCustomer = value ?? Customer.walkIn();
                                  });
                                },
                                onTap: () {

                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Vui lòng chọn khách hàng'; 
                                  } 
                                  return null;
                                },
                              ), 

                            // Add new customer button
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _isLoadingCustomers ? null : () async {
                                try {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const CustomerFormScreen(),
                                    ),
                                  );
                                  if (result == true) {
                                    // Tải lại danh sách khách hàng và cập nhật UI
                                    await _loadCustomers();
                                    // Đảm bảo UI được rebuild sau khi cập nhật
                                    if (mounted) {
                                      setState(() {});
                                    }
                                  } 
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Lỗi khi thêm khách hàng: $e'),
                                        backgroundColor: AppColors.errorColor,
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Thêm khách hàng mới'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.mainColor,
                                side: BorderSide(color: AppColors.mainColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppStyles.spacingL),

                      TextFormField(
                        controller: _noteController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Ghi chú',
                          prefixIcon: Icon(Icons.note), 
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppStyles.spacingL), 

                // Order Items Card
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
                    children: [
                       Row(
                         children: [
                           Icon(Icons.shopping_cart, color: AppColors.warningColor, size: 24),
                           const SizedBox(width: AppStyles.spacingS),
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(
                                   'Sản phẩm trong đơn',
                                   style: AppStyles.headingSmall,
                                 ),
                                 // Hiển thị thông tin real-time
                                 if (_items.isNotEmpty)
                                   Text(
                                     '${_items.length} sản phẩm • ${_items.fold(0.0, (sum, item) => sum + item.quantity).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} đơn vị • ${FormatUtils.formatCurrency(_subtotal)} VNĐ',
                                     style: AppStyles.bodySmall.copyWith(
                                       color: AppColors.textSecondary,
                                     ),
                                   ),
                               ],
                             ),
                           ),
                           ElevatedButton.icon(
                             onPressed: _isLoadingProducts ? null : _addProduct,
                             icon: const Icon(Icons.add, size: 18),
                             label: const Text('Thêm'),
                             style: ElevatedButton.styleFrom(
                               backgroundColor: AppColors.mainColor,
                               foregroundColor: AppColors.textOnMain,
                               padding: const EdgeInsets.symmetric(
                                 horizontal: AppStyles.spacingM,
                                 vertical: AppStyles.spacingS,
                               ),
                             ),
                           ),
                         ],
                       ),
                      const SizedBox(height: AppStyles.spacingL),

                      if (_isLoadingProducts)
                        const Center(
                          child: CircularProgressIndicator(),
                        )
                      else if (_items.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(AppStyles.spacingXL),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(AppStyles.radiusM),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 48,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(height: AppStyles.spacingM),
                              Text(
                                'Chưa có sản phẩm nào',
                                style: AppStyles.bodyLarge.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppStyles.spacingS),
                              Text(
                                'Nhấn nút "Thêm" để thêm sản phẩm vào đơn hàng',
                                style: AppStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: [
                            // Hiển thị tổng quan sản phẩm
                            Container(
                              padding: const EdgeInsets.all(AppStyles.spacingM),
                              decoration: BoxDecoration(
                                color: AppColors.successColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppStyles.radiusM),
                                border: Border.all(color: AppColors.successColor.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: AppColors.successColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppStyles.spacingS),
                                  Expanded(
                                    child: Text(
                                      'Đã thêm ${_items.length} sản phẩm với tổng tiền ${FormatUtils.formatCurrency(_subtotal)} VNĐ',
                                      style: AppStyles.bodyMedium.copyWith(
                                        color: AppColors.successColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppStyles.spacingM),
                            // Danh sách sản phẩm
                            ..._items.asMap().entries.map((entry) {
                              return _buildOrderItemCard(entry.value, entry.key);
                            }).toList(),
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: AppStyles.spacingL),

                // Discount and Tax Card
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
                          Icon(Icons.calculate, color: AppColors.infoColor, size: 24),
                          const SizedBox(width: AppStyles.spacingS),
                          Text(
                            'Điều chỉnh giá',
                            style: AppStyles.headingSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppStyles.spacingL),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _discountController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [CurrencyInputFormatter()],
                              decoration: const InputDecoration(
                                labelText: 'Giảm giá',
                                prefixIcon: Icon(Icons.discount),
                                suffixText: 'VNĐ',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppStyles.spacingL),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _taxController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [CurrencyInputFormatter()],
                              decoration: const InputDecoration(
                                labelText: 'Thuế',
                                prefixIcon: Icon(Icons.receipt),
                                suffixText: 'VNĐ',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) => setState(() {}),
                            ),
                          ),
                        ],
                      ),

                    ],
                  ),
                ),

                const SizedBox(height: AppStyles.spacingL),

                // Order Summary
                _buildOrderSummary(),

                SizedBox(height: MediaQuery.of(context).size.height < 700 ? AppStyles.spacingL : AppStyles.spacingXL),

                // Save Button
                Container(
                  height: MediaQuery.of(context).size.height < 700 ? 48 : 56,
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
                    onPressed: _isLoading ? null : _saveOrder,
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
                                _isEditMode ? Icons.save : Icons.add_shopping_cart,
                                color: AppColors.textOnMain,
                                size: 24,
                              ),
                              const SizedBox(width: AppStyles.spacingS),
                              Text(
                                _isEditMode ? 'Lưu thay đổi' : 'Tạo đơn hàng',
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
      ),
             floatingActionButton: widget.hideFloatingButton ? null : FloatingActionButton.extended(
         onPressed: () {
           Navigator.push(
             context,
             MaterialPageRoute(
               builder: (context) => const OrderListScreen(),
             ),
           ).then((_) {
             // Refetch data when returning from OrderListScreen
             _loadCustomers();
             _loadProducts();
           });
         },
         backgroundColor: AppColors.infoColor,
         foregroundColor: Colors.white,
         icon: const Icon(Icons.list),
         label: const Text('Xem danh sách'),
         tooltip: 'Xem danh sách đơn hàng',
       ),
    );
  }

  String _getStatusDisplayName(OrderStatus status) {
    switch (status) {
      case OrderStatus.draft:
        return 'Mới tạo';
      case OrderStatus.confirmed:
        return 'Đã xác nhận';
      case OrderStatus.paid:
        return 'Đã thanh toán';
      case OrderStatus.cancelled:
        return 'Đã hủy';
    }
  }
}

// Product Selection Dialog
class _ProductSelectionDialog extends StatefulWidget {
  final List<Product> products;
  final Function(Product, double) onProductSelected;

  const _ProductSelectionDialog({
    required this.products,
    required this.onProductSelected,
  });

  @override
  State<_ProductSelectionDialog> createState() => _ProductSelectionDialogState();
}

class _ProductSelectionDialogState extends State<_ProductSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');
  List<Product> _filteredProducts = [];
  Product? _selectedProduct;

  @override
  void initState() {
    super.initState();
    _filteredProducts = widget.products;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = widget.products;
      } else {
        _filteredProducts = widget.products.where((product) {
          return product.name.toLowerCase().contains(query.toLowerCase()) ||
                 product.code.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _addProduct() {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn sản phẩm'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    final quantityText = _quantityController.text;
    final quantity = double.tryParse(quantityText);
    
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số lượng hợp lệ'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }
    
    // Validate: non-Kg units should not have decimal values
    if (_selectedProduct!.unit.toLowerCase() != 'kg' && quantity % 1 != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedProduct!.unit} không thể có số lẻ. Vui lòng nhập số nguyên.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    widget.onProductSelected(_selectedProduct!, quantity);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.radiusL),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.95,
        ),
        padding: EdgeInsets.all(
          MediaQuery.of(context).size.width < 600 ? AppStyles.spacingM : AppStyles.spacingL,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Chọn sản phẩm',
                    style: AppStyles.headingMedium,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  splashRadius: 20,
                  tooltip: 'Đóng',
                ),
              ],
            ),

            SizedBox(height: AppStyles.spacingS),

            // Search
            TextField(
              controller: _searchController,
              style: TextStyle(fontSize: (MediaQuery.of(context).size.width * 0.03),),
              onChanged: _filterProducts,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppStyles.radiusM),
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppStyles.radiusM),
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
              ),
            ),

            SizedBox(height: AppStyles.spacingM),

            Divider(height: 1, color: AppColors.borderLight),

            SizedBox(height: AppStyles.spacingM),

            // Product list
            // --- Product list (no avatar, clearer separation) ---
            Expanded(
              child: _filteredProducts.isEmpty
                  ? Center(child: Text('Không có sản phẩm', style: AppStyles.bodyMedium))
                  : ListView.separated(
                itemCount: _filteredProducts.length,
                separatorBuilder: (_, __) => SizedBox(height: AppStyles.spacingS),
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  final isSelected = _selectedProduct?.id == product.id;

                  return Card(
                    elevation: 1,
                    margin: EdgeInsets.zero, // spacing controlled by separator
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppStyles.radiusM),
                      side: BorderSide(
                        color: isSelected ? AppColors.mainColor : AppColors.borderLight,
                        width: isSelected ? 1.2 : 1.0,
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedProduct = product;
                        });
                      },
                      borderRadius: BorderRadius.circular(AppStyles.radiusM),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: AppStyles.spacingS + 2,
                          horizontal: AppStyles.spacingM,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title row: name + trailing check
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    product.name ?? '-',
                                    style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                if (isSelected)
                                  Padding(
                                    padding: EdgeInsets.only(left: AppStyles.spacingS),
                                    child: Icon(Icons.check_circle, color: AppColors.mainColor, size: 20),
                                  ),
                              ],
                            ),

                            SizedBox(height: AppStyles.spacingS),

                            // Info row: code + price chip
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Mã: ${product.code ?? "-"}',
                                    style: AppStyles.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: AppStyles.spacingS),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.successColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${FormatUtils.formatCurrency(product.sellingPrice)} VNĐ',
                                    style: AppStyles.bodySmall.copyWith(
                                      color: AppColors.successColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: AppStyles.spacingS),

                            // Stock line
                            Text(
                              'Tồn kho: ${product.stockQuantity ?? 0} ${product.unit ?? ""}',
                              style: AppStyles.bodySmall.copyWith(
                                color: (product.stockQuantity ?? 0) > 0 ? AppColors.textSecondary : AppColors.errorColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),


            SizedBox(height: AppStyles.spacingM),

            // Quantity row
            Row(
              children: [
                Text(
                  'Số lượng:',
                  style: AppStyles.bodyMedium.copyWith(
                    fontSize: (MediaQuery.of(context).size.width * 0.03),
                  ),
                ),
                SizedBox(width: AppStyles.spacingM),
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    style: TextStyle(fontSize: (MediaQuery.of(context).size.width * 0.03),),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppStyles.radiusS)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      suffixText: _selectedProduct?.unit,
                    ),
                    onChanged: (_) => setState(() {}), // cập nhật UI
                  ),
                ),
                SizedBox(width: AppStyles.spacingM),
                if (_selectedProduct != null)
                  Text(
                    '→ ${FormatUtils.formatCurrency((_selectedProduct!.sellingPrice) * (double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 0))} VNĐ',
                    style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w600,fontSize: (MediaQuery.of(context).size.width * 0.03),),
                  ),
              ],
            ),

            SizedBox(height: AppStyles.spacingL),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child:  Text('Hủy',style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.035),),
                ),
                SizedBox(width: AppStyles.spacingS),
                ElevatedButton(
                  onPressed: _addProduct,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.radiusM)),
                    elevation: 2,
                  ),
                  child:  Text('Thêm',style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.035),),
                ),
              ],
            ),
          ],
        ),
      ),
    );


  }
}

// Order Item Edit Dialog
class _OrderItemEditDialog extends StatefulWidget {
  final OrderItem item;
  final Product product;
  final Function(OrderItem) onItemUpdated;

  const _OrderItemEditDialog({
    required this.item,
    required this.product,
    required this.onItemUpdated,
  });

  @override
  State<_OrderItemEditDialog> createState() => _OrderItemEditDialogState();
}

class _OrderItemEditDialogState extends State<_OrderItemEditDialog> {
  late TextEditingController _quantityController;
  late TextEditingController _unitPriceController;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: _formatQuantityForInput(widget.item.quantity, widget.item.unit));
    _unitPriceController = TextEditingController(text: FormatUtils.formatCurrency(widget.item.unitPrice));
    _noteController = TextEditingController(text: widget.item.note);
  }

  /// Format quantity for input field: decimal cho Kg, integer cho unit khác
  String _formatQuantityForInput(double quantity, String unit) {
    if (unit.toLowerCase() == 'kg') {
      // Keep decimal if needed
      return quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toString();
    } else {
      // Always show as integer for other units
      return quantity.toInt().toString();
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitPriceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final quantityText = _quantityController.text;
    final quantity = double.tryParse(quantityText);
    final unitPrice = FormatUtils.parseCurrency(_unitPriceController.text);

    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số lượng hợp lệ'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }
    
    // Validate: non-Kg units should not have decimal values
    if (widget.item.unit.toLowerCase() != 'kg' && quantity % 1 != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.item.unit} không thể có số lẻ. Vui lòng nhập số nguyên.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    if (unitPrice == null || unitPrice < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập giá hợp lệ'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    final updatedItem = widget.item.copyWith(
      quantity: quantity,
      unitPrice: unitPrice,
      note: _noteController.text.trim(),
    );

    widget.onItemUpdated(updatedItem);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final quantityText = _quantityController.text;
    final quantity = double.tryParse(quantityText) ?? 0;
    
    final unitPrice = FormatUtils.parseCurrency(_unitPriceController.text);
    final lineTotal = quantity * unitPrice;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.radiusL),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.95,
        ),
        padding: EdgeInsets.all(
          MediaQuery.of(context).size.width < 600 ? AppStyles.spacingM : AppStyles.spacingL,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sửa sản phẩm',
                    style: AppStyles.headingMedium,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: AppStyles.spacingM),

            Text(
              widget.item.productName,
              style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            Text('Mã: ${widget.item.productCode}'),
            const SizedBox(height: AppStyles.spacingL),

            TextFormField(
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              decoration: InputDecoration(
                labelText: 'Số lượng',
                suffixText: widget.item.unit,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: AppStyles.spacingM),

            TextFormField(
              controller: _unitPriceController,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Đơn giá',
                suffixText: 'VNĐ',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: AppStyles.spacingM),

            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppStyles.spacingL),

            Container(
              padding: const EdgeInsets.all(AppStyles.spacingM),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(AppStyles.radiusM),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Thành tiền:'),
                  Text(
                    '${FormatUtils.formatCurrency(lineTotal)} VNĐ',
                    style: AppStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.successColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppStyles.spacingL),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                const SizedBox(width: AppStyles.spacingS),
                ElevatedButton(
                  onPressed: _saveChanges,
                  child: const Text('Lưu'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
