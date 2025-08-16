import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../models/customer.dart';
import '../services/order_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../utils/format_utils.dart';
import 'order_form_screen.dart';
import '../main.dart'; // Import để sử dụng CommonScreenMixin

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> with CommonScreenMixin {
  final OrderService _orderService = OrderService();
  final TextEditingController _searchController = TextEditingController();
   
  List<Order> _orders = [];
  List<Order> _filteredOrders = [];
  bool _isLoading = true;
  OrderStatus? _selectedStatus;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  } 

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    
    try {
      final orders = await _orderService.getOrders();
      
      orders.sort((a, b) {
        final timeA = a.createdAt ?? a.orderDate;
        final timeB = b.createdAt ?? b.orderDate;
        return timeB.compareTo(timeA); // Mới nhất lên đầu
      });
      
      setState(() {
        _orders = orders;
        _filteredOrders = orders;
        _isLoading = false;
      }); 
    } catch (e) {
      print('Error loading orders: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<Order> filtered = List.from(_orders);
    
    // Filter by search query
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((order) {
        return order.orderNumber.toLowerCase().contains(query) ||
               order.customer.name.toLowerCase().contains(query) ||
               order.customer.phone.contains(query) ||
               order.note.toLowerCase().contains(query);
      }).toList();
    }
    
    // Filter by status
    if (_selectedStatus != null) {
      filtered = filtered.where((o) => o.status == _selectedStatus).toList();
    }
    
    // Filter by date
    if (_selectedDate != null) {
      filtered = filtered.where((order) {
        final orderDate = DateTime(order.orderDate.year, order.orderDate.month, order.orderDate.day);
        final selectedDate = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
        return orderDate.isAtSameMomentAs(selectedDate);
      }).toList();
    }
    
    setState(() {
      _filteredOrders = filtered;
    });
  }

  Future<void> _deleteOrder(Order order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa đơn hàng "${order.orderNumber}"?'),
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
      final success = await _orderService.deleteOrder(order.id);
      if (success) {
        await _loadOrders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã xóa đơn hàng "${order.orderNumber}"'),
              backgroundColor: AppColors.successColor,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Không thể xóa đơn hàng'),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _updateOrderStatus(Order order, OrderStatus newStatus) async {
    final success = await _orderService.updateOrderStatus(order.id, newStatus);
    if (success) {
      await _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật trạng thái đơn hàng'),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Không thể cập nhật trạng thái'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  void _showOrderDetails(Order order) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                      'Chi tiết đơn hàng',
                      style: AppStyles.headingMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Số đơn hàng:', order.orderNumber),
                      _buildDetailRow('Ngày tạo:', FormatUtils.formatDateTime(order.orderDate)),
                      _buildDetailRow('Trạng thái:', order.statusDisplayName),
                            if (order.customer.name.isNotEmpty)
        _buildDetailRow('Khách hàng:', order.customer.displayName),
      if (order.customer.phone.isNotEmpty)
        _buildDetailRow('Số điện thoại:', order.customer.phone),
                      if (order.note.isNotEmpty)
                        _buildDetailRow('Ghi chú:', order.note),
                      
                      const SizedBox(height: AppStyles.spacingM),  
                      Text( 
                        'Sản phẩm trong đơn:',  
                        style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppStyles.spacingM),
                       
                      if (order.items.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(AppStyles.spacingL), 
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(AppStyles.radiusM),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: AppStyles.spacingS),
                              Text(
                                'Chưa có sản phẩm nào',
                                style: AppStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...order.items.map((item) => Container(
                          margin: const EdgeInsets.only(bottom: AppStyles.spacingS),
                          padding: const EdgeInsets.all(AppStyles.spacingM),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(AppStyles.radiusM),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.productName,
                                      style: AppStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    FormatUtils.formatCurrency(item.lineTotal),
                                    style: AppStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.successColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppStyles.spacingXS),
                              Row(
                                children: [
                                  Text('${item.quantity} ${item.unit}'),
                                  const Text(' × '),
                                  Text('${FormatUtils.formatCurrency(item.unitPrice)} VNĐ'),
                                ],
                              ),
                            ],
                          ),
                        )).toList(),
                      
                      const SizedBox(height: AppStyles.spacingM),
                      const Divider(),
                      
                      if (order.items.isNotEmpty) ...[
                        _buildSummaryRow('Tổng tiền hàng:', order.subtotal),
                        if (order.discount > 0)
                          _buildSummaryRow('Giảm giá:', -order.discount),
                        if (order.tax > 0)
                          _buildSummaryRow('Thuế:', order.tax),
                        const Divider(),    
                        _buildSummaryRow('Tổng cộng:', order.total, isTotal: true),
                        if (order.status == OrderStatus.paid)
                          _buildSummaryRow('Lợi nhuận:', order.profit, 
                            color: order.profit >= 0 ? AppColors.successColor : AppColors.errorColor),
                      ] else ...[
                        _buildSummaryRow('Tổng tiền hàng:', 0),
                        _buildSummaryRow('Giảm giá:', 0),
                        _buildSummaryRow('Thuế:', 0),
                        const Divider(),
                        _buildSummaryRow('Tổng cộng:', 0, isTotal: true),
                        Container(
                          padding: const EdgeInsets.all(AppStyles.spacingM),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(AppStyles.radiusM),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppColors.warningColor,
                                size: 20,
                              ),
                              const SizedBox(width: AppStyles.spacingS),
                              Expanded(
                                child: Text(
                                  'Đơn hàng chưa có sản phẩm. Vui lòng thêm sản phẩm để tính toán.',
                                  style: AppStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
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
              const SizedBox(height: AppStyles.spacingM),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đóng'),
                  ),
                  const SizedBox(width: AppStyles.spacingS),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _editOrder(order);
                    },
                    child: const Text('Sửa'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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

  Widget _buildSummaryRow(String label, double value, {bool isTotal = false, Color? color}) {
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
            '${FormatUtils.formatCurrency(value)} VNĐ',
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

  void _editOrder(Order order) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderFormScreen(order: order),
      ),
    );
  }

  void _addOrder() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OrderFormScreen(),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppStyles.spacingM),
      child: Column(
        children: [
          // Status filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Tất cả'),
                  selected: _selectedStatus == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedStatus = null;
                    });
                    _applyFilters();
                  },
                  backgroundColor: AppColors.backgroundCard,
                  selectedColor: AppColors.mainColor.withOpacity(0.2),
                ),
                const SizedBox(width: AppStyles.spacingS),
                ...OrderStatus.values.map((status) {
                  final isSelected = _selectedStatus == status;
                  return Container(
                    margin: const EdgeInsets.only(right: AppStyles.spacingS),
                    child: FilterChip(
                      label: Text(_getStatusDisplayName(status)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedStatus = selected ? status : null;
                        });
                        _applyFilters();
                      },
                      backgroundColor: AppColors.backgroundCard,
                      selectedColor: _getStatusColor(status).withOpacity(0.2),
                      checkmarkColor: _getStatusColor(status),
                      labelStyle: TextStyle(
                        color: isSelected ? _getStatusColor(status) : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          const SizedBox(height: AppStyles.spacingS),
          // Date filter
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                      });
                      _applyFilters();
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _selectedDate != null 
                        ? 'Ngày: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}'
                        : 'Chọn ngày'
                  ),
                ),
              ),
              if (_selectedDate != null) ...[
                const SizedBox(width: AppStyles.spacingS),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedDate = null;
                    });
                    _applyFilters();
                  },
                  icon: const Icon(Icons.clear),
                ),
              ],
            ],
          ),
        ],
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

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.draft:
        return AppColors.warningColor;
      case OrderStatus.confirmed:
        return AppColors.infoColor;
      case OrderStatus.paid:
        return AppColors.successColor;
      case OrderStatus.cancelled:
        return AppColors.errorColor;
    }
  }

  Widget _buildOrderCard(Order order) {
    final statusColor = _getStatusColor(order.status);
    
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppStyles.spacingM,
        vertical: AppStyles.spacingS,
      ),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppStyles.radiusL),
          onTap: () => _showOrderDetails(order),
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
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppStyles.radiusS),
                      ),
                      child: Icon(
                        _getStatusIcon(order.status),
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppStyles.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.orderNumber,
                            style: AppStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppStyles.spacingXS),
                          Text(
                            FormatUtils.formatDateTime(order.orderDate),
                            style: AppStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppStyles.spacingS,
                        vertical: AppStyles.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(AppStyles.radiusS),
                      ),
                      child: Text(
                        order.statusDisplayName,
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.textOnMain,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _editOrder(order);
                            break;
                          case 'delete':
                            _deleteOrder(order);
                            break;
                          case 'status_draft':
                            _updateOrderStatus(order, OrderStatus.draft);
                            break;
                          case 'status_confirmed':
                            _updateOrderStatus(order, OrderStatus.confirmed);
                            break;
                          case 'status_paid':
                            _updateOrderStatus(order, OrderStatus.paid);
                            break;
                          case 'status_cancelled':
                            _updateOrderStatus(order, OrderStatus.cancelled);
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
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'status_draft',
                          child: Row(
                            children: [
                              Icon(Icons.drafts, size: 18, color: AppColors.warningColor),
                              SizedBox(width: AppStyles.spacingS),
                              Text('Mới tạo'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'status_confirmed',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, size: 18, color: AppColors.infoColor),
                              SizedBox(width: AppStyles.spacingS),
                              Text('Đã xác nhận'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'status_paid',
                          child: Row(
                            children: [
                              Icon(Icons.payment, size: 18, color: AppColors.successColor),
                              SizedBox(width: AppStyles.spacingS),
                              Text('Đã thanh toán'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'status_cancelled',
                          child: Row(
                            children: [
                              Icon(Icons.cancel, size: 18, color: AppColors.errorColor),
                              SizedBox(width: AppStyles.spacingS),
                              Text('Đã hủy'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
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
                
                // Customer info
                if (order.customer.name.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: AppStyles.spacingXS),
                      Expanded(
                        child: Text(
                          order.customer.displayName,
                          style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (order.customer.phone.isNotEmpty)
                        Text(
                          order.customer.phone,
                          style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppStyles.spacingS),
                ],
                
                // Order summary
                if (order.items.isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildOrderInfoItem(
                          'Sản phẩm',
                          '${order.totalItems} loại',
                          AppColors.infoColor,
                          Icons.inventory,
                        ),
                      ),
                      const SizedBox(width: AppStyles.spacingM),
                      Expanded(
                        child: _buildOrderInfoItem(
                          'Số lượng',
                          '${order.totalQuantity}',
                          AppColors.warningColor,
                          Icons.shopping_cart,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppStyles.spacingM),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(AppStyles.spacingS),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(AppStyles.radiusS),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.warningColor,
                          size: 16,
                        ),
                        const SizedBox(width: AppStyles.spacingS),
                        Text(
                          'Đơn hàng chưa có sản phẩm',
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppStyles.spacingM),
                ],
                
                // Total and profit
                if (order.items.isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildOrderInfoItem(
                          'Tổng tiền',
                          '${FormatUtils.formatCurrency(order.total)} VNĐ',
                          AppColors.successColor,
                          Icons.attach_money,
                        ),
                      ),
                      if (order.status == OrderStatus.paid) ...[
                        const SizedBox(width: AppStyles.spacingM),
                        Expanded(
                          child: _buildOrderInfoItem(
                            'Lợi nhuận',
                            '${FormatUtils.formatCurrency(order.profit)} VNĐ',
                            order.profit >= 0 ? AppColors.successColor : AppColors.errorColor,
                            order.profit >= 0 ? Icons.trending_up : Icons.trending_down,
                          ),
                        ),
                      ],
                    ],
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(AppStyles.spacingS),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(AppStyles.radiusS),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.attach_money,
                          color: AppColors.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: AppStyles.spacingS),
                        Text(
                          'Tổng tiền: 0 VNĐ',
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Note
                if (order.note.isNotEmpty) ...[
                  const SizedBox(height: AppStyles.spacingM),
                  Container(
                    padding: const EdgeInsets.all(AppStyles.spacingS),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(AppStyles.radiusS),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.note, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: AppStyles.spacingS),
                        Expanded(
                          child: Text(
                            order.note,
                            style: AppStyles.bodySmall.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.draft:
        return Icons.drafts;
      case OrderStatus.confirmed:
        return Icons.check_circle;
      case OrderStatus.paid:
        return Icons.payment;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  Widget _buildOrderInfoItem(String title, String value, Color color, IconData icon) {
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
              Icons.receipt_long,
              size: 64,
              color: AppColors.infoColor,
            ),
          ),
          const SizedBox(height: AppStyles.spacingL),
          Text(
            'Chưa có đơn hàng nào',
            style: AppStyles.headingMedium,
          ),
          const SizedBox(height: AppStyles.spacingM),
          Text(
            'Tạo đơn hàng đầu tiên để bắt đầu bán hàng',
            style: AppStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppStyles.spacingL),
          ElevatedButton.icon(
            onPressed: _addOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainColor,
              foregroundColor: AppColors.textOnMain,
              padding: const EdgeInsets.symmetric(
                horizontal: AppStyles.spacingL,
                vertical: AppStyles.spacingM,
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Tạo đơn hàng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách đơn hàng'),
        backgroundColor: AppColors.mainColor,
        foregroundColor: AppColors.textOnMain,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert,color: Colors.white,),
            onSelected: (value) {
              switch (value) {
                case 'refresh':
                  _loadOrders();
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

              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: AppStyles.spacingS),
                    Text('Làm mới'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'shop_info',
                child: Row(
                  children: [
                    Icon(Icons.store),
                    SizedBox(width: AppStyles.spacingS),
                    Text('Thông tin cửa hàng'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppColors.errorColor),
                    SizedBox(width: AppStyles.spacingS),
                    Text('Đăng xuất', style: TextStyle(color: AppColors.errorColor)),
                  ],
                ),
              ),
            ],
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
        child: Column(
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.all(AppStyles.spacingM),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => _applyFilters(),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm đơn hàng...',
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
            
            // Order list
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.mainColor),
                      ),
                    )
                  : _filteredOrders.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          itemCount: _filteredOrders.length,
                          itemBuilder: (context, index) {
                            return _buildOrderCard(_filteredOrders[index]);
                          },
                        ),
            ),
          ], 
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _addOrder,
      //   backgroundColor: AppColors.mainColor,
      //   foregroundColor: AppColors.textOnMain,
      //   child: const Icon(Icons.add),
      //   tooltip: 'Tạo đơn hàng mới',
      // ),
    );
  }
}
