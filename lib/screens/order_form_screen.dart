import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../utils/format_utils.dart';

class OrderFormScreen extends StatefulWidget {
  final Order? order;

  const OrderFormScreen({super.key, this.order});

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final OrderService _orderService = OrderService();
  final ProductService _productService = ProductService();
  
  late TextEditingController _orderNumberController;
  late TextEditingController _customerNameController;
  late TextEditingController _customerPhoneController;
  late TextEditingController _noteController;
  late TextEditingController _discountController;
  late TextEditingController _taxController;
  
  DateTime _orderDate = DateTime.now();
  OrderStatus _status = OrderStatus.draft;
  List<OrderItem> _items = [];
  List<Product> _availableProducts = [];
  bool _isLoading = false;
  bool _isEditMode = false;
  bool _isLoadingProducts = true;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.order != null;
    
    _orderNumberController = TextEditingController(text: widget.order?.orderNumber ?? '');
    _customerNameController = TextEditingController(text: widget.order?.customerName ?? '');
    _customerPhoneController = TextEditingController(text: widget.order?.customerPhone ?? '');
    _noteController = TextEditingController(text: widget.order?.note ?? '');
    _discountController = TextEditingController(
      text: widget.order?.discount.toString() ?? '0'
    );
    _taxController = TextEditingController(
      text: widget.order?.tax.toString() ?? '0'
    );
    
    if (widget.order != null) {
      _orderDate = widget.order!.orderDate;
      _status = widget.order!.status;
      _items = List.from(widget.order!.items);
    } else {
      _generateOrderNumber();
    }
    
    _loadProducts();
  }

  @override
  void dispose() {
    _orderNumberController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
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

  Future<void> _generateOrderNumber() async {
    final nextOrderNumber = await _orderService.getNextOrderNumber(date: _orderDate);
    setState(() {
      _orderNumberController.text = nextOrderNumber;
    });
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.lineTotal);
  double get _discount => double.tryParse(_discountController.text) ?? 0;
  double get _tax => double.tryParse(_taxController.text) ?? 0;
  double get _total => _subtotal - _discount + _tax;
  double get _totalCost => _items.fold(0, (sum, item) => sum + item.lineCostTotal);
  double get _profit => _total - _totalCost;

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng thêm ít nhất một sản phẩm'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final order = Order(
        id: widget.order?.id ?? '',
        orderNumber: _orderNumberController.text.trim(),
        orderDate: _orderDate,
        status: _status,
        items: _items,
        customerName: _customerNameController.text.trim(),
        customerPhone: _customerPhoneController.text.trim(),
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
          Navigator.pop(context, true);
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
              _items.add(OrderItem.fromProduct(product, quantity));
            }
          });
        },
      ),
    );
  }

  void _editOrderItem(int index) {
    final item = _items[index];
    final product = _availableProducts.firstWhere(
      (p) => p.id == item.productId,
      orElse: () => Product(
        id: item.productId,
        code: item.productCode,
        name: item.productName,
        sellingPrice: item.unitPrice,
        costPrice: item.costPrice,
        unit: item.unit,
      ),
    );

    showDialog(
      context: context,
      builder: (context) => _OrderItemEditDialog(
        item: item,
        product: product,
        onItemUpdated: (updatedItem) {
          setState(() {
            _items[index] = updatedItem;
          });
        },
      ),
    );
  }

  void _removeOrderItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Widget _buildOrderItemCard(OrderItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppStyles.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppStyles.radiusM),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppStyles.spacingM),
        title: Text(
          item.productName,
          style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppStyles.spacingXS),
            Text('Mã: ${item.productCode}'),
            const SizedBox(height: AppStyles.spacingXS),
            Row(
              children: [
                Text('${item.quantity} ${item.unit}'),
                const Text(' × '),
                Text('${FormatUtils.formatCurrency(item.unitPrice)} VNĐ'),
                const Text(' = '),
                Text(
                  '${FormatUtils.formatCurrency(item.lineTotal)} VNĐ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.successColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _editOrderItem(index),
              icon: const Icon(Icons.edit, size: 20),
              color: AppColors.infoColor,
            ),
            IconButton(
              onPressed: () => _removeOrderItem(index),
              icon: const Icon(Icons.delete, size: 20),
              color: AppColors.errorColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(AppStyles.spacingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt, color: AppColors.infoColor, size: 24),
              const SizedBox(width: AppStyles.spacingS),
              Text(
                'Tổng kết đơn hàng',
                style: AppStyles.headingSmall,
              ),
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
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isTotal = false, Color? color, String suffix = 'VNĐ'}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            suffix == '%' 
                ? '${value.toStringAsFixed(1)}$suffix'
                : '${FormatUtils.formatCurrency(value)} $suffix',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 16 : 14,
              color: color ?? (isTotal ? AppColors.textPrimary : AppColors.successColor),
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
        title: Text(_isEditMode ? 'Sửa đơn hàng' : 'Tạo đơn hàng'),
        backgroundColor: AppColors.mainColor,
        foregroundColor: AppColors.textOnMain,
        elevation: 0,
        actions: [
          if (!_isEditMode)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _generateOrderNumber,
              tooltip: 'Tạo số đơn mới',
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
                      
                      TextFormField(
                        controller: _orderNumberController,
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
                      const SizedBox(height: AppStyles.spacingL),
                      
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _orderDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setState(() {
                                    _orderDate = date;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Ngày đơn hàng *',
                                  prefixIcon: Icon(Icons.calendar_today),
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  DateFormat('dd/MM/yyyy').format(_orderDate),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppStyles.spacingM),
                          Expanded(
                            child: DropdownButtonFormField<OrderStatus>(
                              value: _status,
                              onChanged: (value) {
                                setState(() {
                                  _status = value ?? OrderStatus.draft;
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
                      
                      TextFormField(
                        controller: _customerNameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên khách hàng',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppStyles.spacingL),
                      
                      TextFormField(
                        controller: _customerPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shopping_cart, color: AppColors.warningColor, size: 24),
                          const SizedBox(width: AppStyles.spacingS),
                          Expanded(
                            child: Text(
                              'Sản phẩm trong đơn (${_items.length})',
                              style: AppStyles.headingSmall,
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
                                ),
                              ),
                              const SizedBox(height: AppStyles.spacingS),
                              Text(
                                'Nhấn nút "Thêm" để thêm sản phẩm',
                                style: AppStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: _items.asMap().entries.map((entry) {
                            return _buildOrderItemCard(entry.value, entry.key);
                          }).toList(),
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
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: const InputDecoration(
                                labelText: 'Giảm giá',
                                prefixIcon: Icon(Icons.discount),
                                suffixText: 'VNĐ',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: AppStyles.spacingM),
                          Expanded(
                            child: TextFormField(
                              controller: _taxController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
  final Function(Product, int) onProductSelected;

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

    final quantity = int.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số lượng hợp lệ'),
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
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(AppStyles.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                ),
              ],
            ),
            const SizedBox(height: AppStyles.spacingM),
            
            // Search
            TextField(
              controller: _searchController,
              onChanged: _filterProducts,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppStyles.radiusM),
                ),
              ),
            ),
            const SizedBox(height: AppStyles.spacingM),
            
            // Product list
            Expanded(
              child: ListView.builder(
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  final isSelected = _selectedProduct?.id == product.id;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppStyles.spacingS),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.mainColor.withOpacity(0.1) : null,
                      borderRadius: BorderRadius.circular(AppStyles.radiusM),
                      border: Border.all(
                        color: isSelected ? AppColors.mainColor : AppColors.borderLight,
                      ),
                    ),
                    child: ListTile(
                      title: Text(product.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mã: ${product.code}'),
                          Text('Giá: ${FormatUtils.formatCurrency(product.sellingPrice)} VNĐ'),
                          Text('Tồn kho: ${product.stockQuantity} ${product.unit}'),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          _selectedProduct = product;
                        });
                      },
                      trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.mainColor) : null,
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: AppStyles.spacingM),
            
            // Quantity input
            Row(
              children: [
                const Text('Số lượng:'),
                const SizedBox(width: AppStyles.spacingM),
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppStyles.spacingL),
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                const SizedBox(width: AppStyles.spacingS),
                ElevatedButton(
                  onPressed: _addProduct,
                  child: const Text('Thêm'),
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
    _quantityController = TextEditingController(text: widget.item.quantity.toString());
    _unitPriceController = TextEditingController(text: widget.item.unitPrice.toString());
    _noteController = TextEditingController(text: widget.item.note);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitPriceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final quantity = int.tryParse(_quantityController.text);
    final unitPrice = double.tryParse(_unitPriceController.text);

    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số lượng hợp lệ'),
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
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final unitPrice = double.tryParse(_unitPriceController.text) ?? 0;
    final lineTotal = quantity * unitPrice;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.radiusL),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppStyles.spacingL),
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
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
