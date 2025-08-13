import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../models/product.dart';
import 'product_service.dart';

class OrderService {
  static const String _ordersKey = 'orders';
  static const String _nextOrderIdKey = 'next_order_id';
  static const String _orderSequenceKey = 'order_sequence';

  // Singleton pattern
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  SharedPreferences? _prefs;
  List<Order> _orders = [];
  int _nextId = 1;
  int _orderSequence = 1;
  bool _isInitialized = false;
  final ProductService _productService = ProductService();

  // Initialize
  Future<bool> init() async {
    if (_isInitialized && _prefs != null) return true;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadOrders();
      _nextId = _prefs?.getInt(_nextOrderIdKey) ?? 1;
      _orderSequence = _prefs?.getInt(_orderSequenceKey) ?? 1;
      _isInitialized = true;
      return true;
    } catch (e) {
      print('Error initializing OrderService: $e');
      _isInitialized = false;
      return false;
    }
  }

  // Load orders from storage
  Future<void> _loadOrders() async {
    try {
      final String? ordersJson = _prefs?.getString(_ordersKey);
      if (ordersJson == null || ordersJson.isEmpty) {
        _orders = [];
        // Chỉ tạo dữ liệu mẫu khi thực sự cần
        return;
      }

      final List<dynamic> ordersList = jsonDecode(ordersJson);
      _orders = ordersList.map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      print('Error loading orders: $e');
      _orders = [];
    }
  }

  // Save orders to storage
  Future<bool> _saveOrders() async {
    if (!await init()) return false;
    
    try {
      final String ordersJson = jsonEncode(_orders.map((o) => o.toJson()).toList());
      return await _prefs?.setString(_ordersKey, ordersJson) ?? false;
    } catch (e) {
      print('Error saving orders: $e');
      return false;
    }
  }

  // Get all orders
  Future<List<Order>> getOrders() async {
    if (!await init()) return [];
    
    // Tạo dữ liệu mẫu nếu danh sách trống (chỉ khi có sản phẩm)
    if (_orders.isEmpty) {
      final products = await _productService.getProducts();
      if (products.isNotEmpty) {
        await _createSampleOrders();
      }
    }
    
    return List.from(_orders);
  }

  // Get orders by status
  Future<List<Order>> getOrdersByStatus(OrderStatus status) async {
    final orders = await getOrders();
    return orders.where((o) => o.status == status).toList();
  }

  // Get orders by date range
  Future<List<Order>> getOrdersByDateRange(DateTime startDate, DateTime endDate) async {
    final orders = await getOrders();
    return orders.where((order) {
      final orderDate = DateTime(order.orderDate.year, order.orderDate.month, order.orderDate.day);
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);
      return orderDate.isAfter(start.subtract(const Duration(days: 1))) && 
             orderDate.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  // Get orders by date
  Future<List<Order>> getOrdersByDate(DateTime date) async {
    return await getOrdersByDateRange(date, date);
  }

  // Get order by ID
  Future<Order?> getOrderById(String id) async {
    final orders = await getOrders();
    try {
      return orders.firstWhere((o) => o.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get order by order number
  Future<Order?> getOrderByNumber(String orderNumber) async {
    final orders = await getOrders();
    try {
      return orders.firstWhere((o) => o.orderNumber == orderNumber);
    } catch (e) {
      return null;
    }
  }

  // Search orders
  Future<List<Order>> searchOrders(String query) async {
    if (query.isEmpty) return await getOrders();
    
    final orders = await getOrders();
    final searchQuery = query.toLowerCase();
    
    return orders.where((order) {
      return order.orderNumber.toLowerCase().contains(searchQuery) ||
             order.customerName.toLowerCase().contains(searchQuery) ||
             order.customerPhone.contains(searchQuery) ||
             order.note.toLowerCase().contains(searchQuery) ||
             order.items.any((item) => 
               item.productName.toLowerCase().contains(searchQuery) ||
               item.productCode.toLowerCase().contains(searchQuery)
             );
    }).toList();
  }

  // Add order
  Future<bool> addOrder(Order order) async {
    if (!await init()) return false;
    
    try {
      // Tạo ID và số đơn hàng mới
      final orderNumber = order.orderNumber.isEmpty 
          ? Order.generateOrderNumber(order.orderDate, _orderSequence)
          : order.orderNumber;
          
      final newOrder = order.copyWith(
        id: _nextId.toString(),
        orderNumber: orderNumber,
      );
      
      _orders.add(newOrder);
      _nextId++;
      _orderSequence++;
      
      final success = await _saveOrders();
      if (success) {
        await _prefs?.setInt(_nextOrderIdKey, _nextId);
        await _prefs?.setInt(_orderSequenceKey, _orderSequence);
        
        // Cập nhật tồn kho nếu đơn hàng đã thanh toán
        if (newOrder.status == OrderStatus.paid) {
          await _updateStockForOrder(newOrder, false); // reduce stock
        }
        
        return true;
      } else {
        // Rollback
        _orders.removeLast();
        _nextId--;
        _orderSequence--;
        return false;
      }
    } catch (e) {
      print('Error adding order: $e');
      return false;
    }
  }

  // Update order
  Future<bool> updateOrder(Order order) async {
    if (!await init()) return false;
    
    try {
      final index = _orders.indexWhere((o) => o.id == order.id);
      if (index == -1) return false;
      
      final oldOrder = _orders[index];
      final updatedOrder = order.copyWith(updatedAt: DateTime.now());
      _orders[index] = updatedOrder;
      
      final success = await _saveOrders();
      if (!success) {
        // Rollback
        _orders[index] = oldOrder;
        return false;
      }
      
      // Cập nhật tồn kho khi thay đổi trạng thái
      await _handleStockUpdateOnStatusChange(oldOrder, updatedOrder);
      
      return true;
    } catch (e) {
      print('Error updating order: $e');
      return false;
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final order = await getOrderById(orderId);
    if (order == null) return false;
    
    final updatedOrder = order.copyWith(status: newStatus);
    return await updateOrder(updatedOrder);
  }

  // Delete order
  Future<bool> deleteOrder(String id) async {
    if (!await init()) return false;
    
    try {
      final index = _orders.indexWhere((o) => o.id == id);
      if (index == -1) return false;
      
      final deletedOrder = _orders[index];
      _orders.removeAt(index);
      
      final success = await _saveOrders();
      if (!success) {
        // Rollback
        _orders.insert(index, deletedOrder);
        return false;
      }
      
      // Hoàn trả tồn kho nếu đơn đã thanh toán
      if (deletedOrder.status == OrderStatus.paid) {
        await _updateStockForOrder(deletedOrder, true); // increase stock
      }
      
      return true;
    } catch (e) {
      print('Error deleting order: $e');
      return false;
    }
  }

  // Handle stock update when order status changes
  Future<void> _handleStockUpdateOnStatusChange(Order oldOrder, Order newOrder) async {
    // Nếu chuyển từ chưa thanh toán sang đã thanh toán -> giảm tồn kho
    if (oldOrder.status != OrderStatus.paid && newOrder.status == OrderStatus.paid) {
      await _updateStockForOrder(newOrder, false); // reduce stock
    }
    // Nếu chuyển từ đã thanh toán sang chưa thanh toán -> tăng tồn kho
    else if (oldOrder.status == OrderStatus.paid && newOrder.status != OrderStatus.paid) {
      await _updateStockForOrder(oldOrder, true); // increase stock
    }
  }

  // Update stock for order items
  Future<void> _updateStockForOrder(Order order, bool increase) async {
    for (final item in order.items) {
      if (increase) {
        await _productService.increaseStock(item.productId, item.quantity);
      } else {
        await _productService.reduceStock(item.productId, item.quantity);
      }
    }
  }

  // Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final orders = await getOrders();
    
    final draftOrders = orders.where((o) => o.status == OrderStatus.draft).length;
    final confirmedOrders = orders.where((o) => o.status == OrderStatus.confirmed).length;
    final paidOrders = orders.where((o) => o.status == OrderStatus.paid).length;
    final cancelledOrders = orders.where((o) => o.status == OrderStatus.cancelled).length;
    
    double totalRevenue = 0;
    double totalProfit = 0;
    int totalItems = 0;
    
    for (final order in orders) {
      if (order.status == OrderStatus.paid) {
        totalRevenue += order.total;
        totalProfit += order.profit;
        totalItems += order.totalQuantity;
      }
    }
    
    return {
      'totalOrders': orders.length,
      'draftOrders': draftOrders,
      'confirmedOrders': confirmedOrders,
      'paidOrders': paidOrders,
      'cancelledOrders': cancelledOrders,
      'totalRevenue': totalRevenue,
      'totalProfit': totalProfit,
      'totalItems': totalItems,
      'averageOrderValue': paidOrders > 0 ? totalRevenue / paidOrders : 0,
    };
  }

  // Get revenue by date range
  Future<Map<String, dynamic>> getRevenueByDateRange(DateTime startDate, DateTime endDate) async {
    final orders = await getOrdersByDateRange(startDate, endDate);
    final paidOrders = orders.where((o) => o.status == OrderStatus.paid).toList();
    
    double totalRevenue = 0;
    double totalCost = 0;
    double totalProfit = 0;
    int totalItems = 0;
    
    for (final order in paidOrders) {
      totalRevenue += order.total;
      totalCost += order.totalCost;
      totalProfit += order.profit;
      totalItems += order.totalQuantity;
    }
    
    return {
      'orders': paidOrders.length,
      'revenue': totalRevenue,
      'cost': totalCost,
      'profit': totalProfit,
      'items': totalItems,
      'averageOrderValue': paidOrders.isNotEmpty ? totalRevenue / paidOrders.length : 0,
      'profitMargin': totalRevenue > 0 ? (totalProfit / totalRevenue * 100) : 0,
    };
  }

  // Get top selling products
  Future<List<Map<String, dynamic>>> getTopSellingProducts({int limit = 10}) async {
    final orders = await getOrders();
    final paidOrders = orders.where((o) => o.status == OrderStatus.paid).toList();
    
    final Map<String, Map<String, dynamic>> productSales = {};
    
    for (final order in paidOrders) {
      for (final item in order.items) {
        if (productSales.containsKey(item.productId)) {
          productSales[item.productId]!['quantity'] += item.quantity;
          productSales[item.productId]!['revenue'] += item.lineTotal;
        } else {
          productSales[item.productId] = {
            'productId': item.productId,
            'productName': item.productName,
            'productCode': item.productCode,
            'quantity': item.quantity,
            'revenue': item.lineTotal,
          };
        }
      }
    }
    
    final sortedProducts = productSales.values.toList()
      ..sort((a, b) => b['quantity'].compareTo(a['quantity']));
    
    return sortedProducts.take(limit).toList();
  }

  // Clear all orders
  Future<bool> clearAllOrders() async {
    if (!await init()) return false;
    
    try {
      _orders.clear();
      _nextId = 1;
      _orderSequence = 1;
      await _prefs?.remove(_ordersKey);
      await _prefs?.remove(_nextOrderIdKey);
      await _prefs?.remove(_orderSequenceKey);
      return true;
    } catch (e) {
      print('Error clearing orders: $e');
      return false;
    }
  }

  // Export orders to JSON
  Future<List<Map<String, dynamic>>> exportOrders() async {
    final orders = await getOrders();
    return orders.map((o) => o.toJson()).toList();
  }

  // Get next order number
  Future<String> getNextOrderNumber({DateTime? date}) async {
    if (!await init()) return Order.generateOrderNumber(DateTime.now(), 1);
    return Order.generateOrderNumber(date ?? DateTime.now(), _orderSequence);
  }

  // Create sample orders - minimal data
  Future<void> _createSampleOrders() async {
    try {
      await _productService.init();
      final products = await _productService.getProducts();
      
      if (products.isEmpty) return;
      
      // Chỉ tạo 1 đơn hàng mẫu để tiết kiệm memory
      _orders = [
        Order(
          id: '1',
          orderNumber: Order.generateOrderNumber(DateTime.now(), 1),
          orderDate: DateTime.now(),
          status: OrderStatus.draft,
          customerName: 'Khách hàng mẫu',
          customerPhone: '',
          items: [
            OrderItem.fromProduct(products[0], 1),
          ],
          note: 'Đơn hàng demo',
        ),
      ];

      _nextId = 2;
      _orderSequence = 2;
      await _saveOrders();
      await _prefs?.setInt(_nextOrderIdKey, _nextId);
      await _prefs?.setInt(_orderSequenceKey, _orderSequence);
    } catch (e) {
      print('Error creating sample orders: $e');
      _orders = [];
      _nextId = 1;
      _orderSequence = 1;
    }
  }

  // Validate order before saving
  bool validateOrder(Order order) {
    if (order.items.isEmpty) return false;
    if (order.orderDate.isAfter(DateTime.now().add(const Duration(days: 1)))) return false;
    
    for (final item in order.items) {
      if (item.quantity <= 0) return false;
      if (item.unitPrice < 0) return false;
    }
    
    return true;
  }

  // Calculate order totals (helper method)
  Order calculateOrderTotals(Order order) {
    // Totals are calculated automatically in the Order model
    return order;
  }
}
