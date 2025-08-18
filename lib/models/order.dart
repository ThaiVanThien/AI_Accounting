import 'product.dart';
import 'customer.dart';

enum OrderStatus {
  draft, // mới tạo
  confirmed, // đã xác nhận
  paid, // đã thanh toán
  cancelled, // đã hủy
}

class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final String productCode;
  final String unit;
  final double quantity;
  final double unitPrice; // giá bán
  final double costPrice; // giá vốn
  final String note;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.costPrice,
    this.note = '',
  });

  // Tính tổng tiền dòng
  double get lineTotal => quantity * unitPrice;

  // Tính tổng giá vốn dòng
  double get lineCostTotal => quantity * costPrice;

  // Tính lợi nhuận dòng
  double get lineProfit => lineTotal - lineCostTotal;

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'productCode': productCode,
      'unit': unit,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'costPrice': costPrice,
      'note': note,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? '',
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      productCode: json['productCode'] ?? '',
      unit: json['unit'] ?? 'Cái',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      costPrice: (json['costPrice'] ?? 0).toDouble(),
      note: json['note'] ?? '',
    );
  }

  // Copy with method
  OrderItem copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productCode,
    String? unit,
    double? quantity,
    double? unitPrice,
    double? costPrice,
    String? note,
  }) {
    return OrderItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      costPrice: costPrice ?? this.costPrice,
      note: note ?? this.note,
    );
  }

  // Tạo từ sản phẩm
  factory OrderItem.fromProduct(Product product, double quantity, {String? note}) {
    return OrderItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productId: product.id,
      productName: product.name,
      productCode: product.code,
      unit: product.unit,
      quantity: quantity,
      unitPrice: product.sellingPrice,
      costPrice: product.costPrice,
      note: note ?? '',
    );
  }
 
  @override
  String toString() {
    return 'OrderItem(id: $id, productName: $productName, quantity: $quantity, unitPrice: $unitPrice, lineTotal: $lineTotal)';
  } 

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderItem &&
        other.id == id &&
        other.productId == productId &&
        other.quantity == quantity &&
        other.unitPrice == unitPrice &&
        other.costPrice == costPrice;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        productId.hashCode ^
        quantity.hashCode ^
        unitPrice.hashCode ^
        costPrice.hashCode;
  }
}

class Order {
  final String id;
  final String orderNumber;
  final DateTime orderDate;
  final OrderStatus status;
  final List<OrderItem> items;
  final Customer customer;
  final String note;
  final double discount; // giảm giá
  final double tax; // thuế
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.orderNumber,
    required this.orderDate,
    this.status = OrderStatus.draft,
    this.items = const [],
    Customer? customer,
    this.note = '',
    this.discount = 0,
    this.tax = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : customer = customer ?? Customer.walkIn(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Tính tổng tiền hàng (trước giảm giá và thuế)
  double get subtotal => items.fold(0, (sum, item) => sum + item.lineTotal);

  // Tính tổng giá vốn
  double get totalCost => items.fold(0, (sum , item) => sum + item.lineCostTotal);

  // Tính tổng tiền sau giảm giá và thuế
  double get total => subtotal - discount + tax;

  // Tính lợi nhuận
  double get profit => total - totalCost;

  // Tính số lượng sản phẩm
  double get totalQuantity => items.fold(0.0, (sum, item) => sum + item.quantity);

  // Tính số loại sản phẩm
  int get totalItems => items.length;

  // Kiểm tra đơn hàng trống
  bool get isEmpty => items.isEmpty;

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'orderDate': orderDate.toIso8601String(),
      'status': status.name,
      'items': items.map((item) => item.toJson()).toList(),
      'customer': customer.toJson(),
      'note': note,
      'discount': discount,
      'tax': tax,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      orderDate: DateTime.parse(json['orderDate']),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.draft,
      ),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      customer: json['customer'] != null 
          ? Customer.fromJson(json['customer'])
          : Customer.walkIn(),
      note: json['note'] ?? '',
      discount: (json['discount'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Copy with method
  Order copyWith({
    String? id,
    String? orderNumber,
    DateTime? orderDate,
    OrderStatus? status,
    List<OrderItem>? items,
    Customer? customer,
    String? note,
    double? discount,
    double? tax,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      orderDate: orderDate ?? this.orderDate,
      status: status ?? this.status,
      items: items ?? this.items,
      customer: customer ?? this.customer,
      note: note ?? this.note,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Tạo số đơn hàng tự động
  static String generateOrderNumber(DateTime date, int sequence) {
    final dateStr = '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    return 'HD$dateStr${sequence.toString().padLeft(4, '0')}';
  }

  // Lấy tên trạng thái tiếng Việt
  String get statusDisplayName {
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

  // Lấy màu trạng thái
  String get statusColor {
    switch (status) {
      case OrderStatus.draft:
        return '#FFA726'; // orange
      case OrderStatus.confirmed:
        return '#42A5F5'; // blue
      case OrderStatus.paid:
        return '#66BB6A'; // green
      case OrderStatus.cancelled:
        return '#EF5350'; // red
    }
  }

  @override
  String toString() {
    return 'Order(id: $id, orderNumber: $orderNumber, status: $status, total: $total, items: ${items.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order &&
        other.id == id &&
        other.orderNumber == orderNumber &&
        other.orderDate == orderDate &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        orderNumber.hashCode ^
        orderDate.hashCode ^
        status.hashCode;
  }
}
