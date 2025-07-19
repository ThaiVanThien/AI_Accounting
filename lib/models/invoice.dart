import 'tax_category.dart' hide VATRate;
import 'business_user.dart';
import '../constants/tax_rates.dart';

enum InvoiceType {
  sale,        // Bán hàng
  purchase,    // Mua hàng
  service,     // Dịch vụ
  other,       // Khác
}

enum PaymentMethod {
  cash,           // Tiền mặt
  bankTransfer,   // Chuyển khoản ngân hàng
  card,           // Thẻ
  eWallet,        // Ví điện tử
  other,          // Khác
}

enum InvoiceStatus {
  draft,      // Nháp
  issued,     // Đã xuất
  paid,       // Đã thanh toán
  cancelled,  // Đã hủy
}

class Invoice {
  final String id;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final InvoiceType type;
  final String customerName;
  final String? customerTaxCode;
  final String customerAddress;
  final String description;
  final double amount;           // Số tiền chưa bao gồm thuế
  final double vatAmount;        // Thuế VAT
  final double totalAmount;      // Tổng tiền sau thuế
  final VATRate vatRate;
  final PaymentMethod paymentMethod;
  final InvoiceStatus status;
  final bool isElectronic;       // Hóa đơn điện tử
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.type,
    required this.customerName,
    this.customerTaxCode,
    required this.customerAddress,
    required this.description,
    required this.amount,
    required this.vatAmount,
    required this.totalAmount,
    required this.vatRate,
    required this.paymentMethod,
    required this.status,
    this.isElectronic = false,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Kiểm tra có cần chuyển khoản không (từ 1/7/2025: >= 5 triệu)
  bool get requiresNonCashPayment => TaxRates.requiresNonCashPayment(totalAmount);

  // Kiểm tra thanh toán có hợp lệ không
  bool get isPaymentMethodValid {
    if (!requiresNonCashPayment) return true;
    return paymentMethod != PaymentMethod.cash;
  }

  // Tạo hóa đơn từ thông tin cơ bản
  factory Invoice.create({
    required String invoiceNumber,
    required InvoiceType type,
    required String customerName,
    String? customerTaxCode,
    required String customerAddress,
    required String description,
    required double amount,
    required VATRate vatRate,
    required PaymentMethod paymentMethod,
    bool isElectronic = false,
    String? notes,
  }) {
    final now = DateTime.now();
    final vatAmount = _calculateVAT(amount, vatRate);
    final totalAmount = amount + vatAmount;

    return Invoice(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      invoiceNumber: invoiceNumber,
      invoiceDate: now,
      type: type,
      customerName: customerName,
      customerTaxCode: customerTaxCode,
      customerAddress: customerAddress,
      description: description,
      amount: amount,
      vatAmount: vatAmount,
      totalAmount: totalAmount,
      vatRate: vatRate,
      paymentMethod: paymentMethod,
      status: InvoiceStatus.issued,
      isElectronic: isElectronic,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Tính VAT
  static double _calculateVAT(double amount, VATRate rate) {
    double percentage;
    switch (rate) {
      case VATRate.exempt:
      case VATRate.zero:
        percentage = 0;
        break;
      case VATRate.five:
        percentage = 5;
        break;
      case VATRate.eight:
        percentage = 8;
        break;
      case VATRate.ten:
        percentage = 10;
        break;
    }
    return amount * percentage / 100;
  }

  // Chuyển đổi từ Map
  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] ?? '',
      invoiceNumber: map['invoiceNumber'] ?? '',
      invoiceDate: DateTime.parse(map['invoiceDate']),
      type: InvoiceType.values[map['type'] ?? 0],
      customerName: map['customerName'] ?? '',
      customerTaxCode: map['customerTaxCode'],
      customerAddress: map['customerAddress'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      vatAmount: (map['vatAmount'] ?? 0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      vatRate: VATRate.values[map['vatRate'] ?? 0],
      paymentMethod: PaymentMethod.values[map['paymentMethod'] ?? 0],
      status: InvoiceStatus.values[map['status'] ?? 0],
      isElectronic: map['isElectronic'] ?? false,
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // Chuyển đổi thành Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'invoiceDate': invoiceDate.toIso8601String(),
      'type': type.index,
      'customerName': customerName,
      'customerTaxCode': customerTaxCode,
      'customerAddress': customerAddress,
      'description': description,
      'amount': amount,
      'vatAmount': vatAmount,
      'totalAmount': totalAmount,
      'vatRate': vatRate.index,
      'paymentMethod': paymentMethod.index,
      'status': status.index,
      'isElectronic': isElectronic,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Copy với thay đổi
  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    DateTime? invoiceDate,
    InvoiceType? type,
    String? customerName,
    String? customerTaxCode,
    String? customerAddress,
    String? description,
    double? amount,
    double? vatAmount,
    double? totalAmount,
    VATRate? vatRate,
    PaymentMethod? paymentMethod,
    InvoiceStatus? status,
    bool? isElectronic,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      type: type ?? this.type,
      customerName: customerName ?? this.customerName,
      customerTaxCode: customerTaxCode ?? this.customerTaxCode,
      customerAddress: customerAddress ?? this.customerAddress,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      vatAmount: vatAmount ?? this.vatAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      vatRate: vatRate ?? this.vatRate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      isElectronic: isElectronic ?? this.isElectronic,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Invoice(id: $id, number: $invoiceNumber, amount: $totalAmount triệu, '
           'customer: $customerName, date: ${invoiceDate.toString().substring(0, 10)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Invoice && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Extension cho InvoiceType
extension InvoiceTypeExtension on InvoiceType {
  String get displayName {
    switch (this) {
      case InvoiceType.sale:
        return 'Bán hàng';
      case InvoiceType.purchase:
        return 'Mua hàng';
      case InvoiceType.service:
        return 'Dịch vụ';
      case InvoiceType.other:
        return 'Khác';
    }
  }
}

// Extension cho PaymentMethod
extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Tiền mặt';
      case PaymentMethod.bankTransfer:
        return 'Chuyển khoản';
      case PaymentMethod.card:
        return 'Thẻ';
      case PaymentMethod.eWallet:
        return 'Ví điện tử';
      case PaymentMethod.other:
        return 'Khác';
    }
  }

  bool get isNonCash {
    return this != PaymentMethod.cash;
  }
}

// Extension cho InvoiceStatus
extension InvoiceStatusExtension on InvoiceStatus {
  String get displayName {
    switch (this) {
      case InvoiceStatus.draft:
        return 'Nháp';
      case InvoiceStatus.issued:
        return 'Đã xuất';
      case InvoiceStatus.paid:
        return 'Đã thanh toán';
      case InvoiceStatus.cancelled:
        return 'Đã hủy';
    }
  }
} 