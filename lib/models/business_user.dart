import 'tax_category.dart';
import '../constants/tax_rates.dart';

class BusinessUser {
  final String id;
  final String name;
  final String businessName;
  final String identityNumber; // Số định danh cá nhân
  final String? taxCode; // Mã số thuế (có thể null với số định danh)
  final String address;
  final String phoneNumber;
  final BusinessSector businessSector;
  final BusinessType businessType;
  final double annualRevenue; // Doanh thu hàng năm (triệu đồng) - tính từ dữ liệu thực tế
  final DateTime registrationDate;
  final bool isEcommerceTrading; // Có kinh doanh TMĐT không
  final bool hasElectronicInvoice; // Có sử dụng hóa đơn điện tử không
  final DateTime createdAt;
  final DateTime updatedAt;

  BusinessUser({
    required this.id,
    required this.name,
    required this.businessName,
    required this.identityNumber,
    this.taxCode,
    required this.address,
    required this.phoneNumber,
    required this.businessSector,
    required this.businessType,
    this.annualRevenue = 0.0, // Default 0, sẽ tính từ dữ liệu thực tế
    required this.registrationDate,
    this.isEcommerceTrading = false,
    this.hasElectronicInvoice = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // Kiểm tra có miễn thuế VAT không
  bool get isVATExempt => TaxRates.isVATExempt(annualRevenue);

  // Kiểm tra có phải nộp thuế môn bài không
  bool get isBusinessLicenseTaxRequired => annualRevenue >= 100000000;

  // Lấy mức thuế môn bài
  double get businessLicenseTaxAmount => TaxRates.calculateBusinessLicenseTax(annualRevenue);

    // Kiểm tra có bắt buộc dùng hóa đơn điện tử không
  bool get requiresElectronicInvoice => TaxRates.requiresElectronicInvoice(annualRevenue);

  // Chuyển đổi từ Map
  factory BusinessUser.fromMap(Map<String, dynamic> map) {
    return BusinessUser(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      businessName: map['businessName'] ?? '',
      identityNumber: map['identityNumber'] ?? '',
      taxCode: map['taxCode'],
      address: map['address'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      businessSector: BusinessSector.values[map['businessSector'] ?? 0],
      businessType: BusinessType.values[map['businessType'] ?? 0],
      annualRevenue: (map['annualRevenue'] ?? 0).toDouble(),
      registrationDate: DateTime.parse(map['registrationDate']),
      isEcommerceTrading: map['isEcommerceTrading'] ?? false,
      hasElectronicInvoice: map['hasElectronicInvoice'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // Chuyển đổi thành Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'businessName': businessName,
      'identityNumber': identityNumber,
      'taxCode': taxCode,
      'address': address,
      'phoneNumber': phoneNumber,
      'businessSector': businessSector.index,
      'businessType': businessType.index,
      'annualRevenue': annualRevenue,
      'registrationDate': registrationDate.toIso8601String(),
      'isEcommerceTrading': isEcommerceTrading,
      'hasElectronicInvoice': hasElectronicInvoice,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Copy với thay đổi
  BusinessUser copyWith({
    String? id,
    String? name,
    String? businessName,
    String? identityNumber,
    String? taxCode,
    String? address,
    String? phoneNumber,
    BusinessSector? businessSector,
    BusinessType? businessType,
    double? annualRevenue,
    DateTime? registrationDate,
    bool? isEcommerceTrading,
    bool? hasElectronicInvoice,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessUser(
      id: id ?? this.id,
      name: name ?? this.name,
      businessName: businessName ?? this.businessName,
      identityNumber: identityNumber ?? this.identityNumber,
      taxCode: taxCode ?? this.taxCode,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      businessSector: businessSector ?? this.businessSector,
      businessType: businessType ?? this.businessType,
      annualRevenue: annualRevenue ?? this.annualRevenue,
      registrationDate: registrationDate ?? this.registrationDate,
      isEcommerceTrading: isEcommerceTrading ?? this.isEcommerceTrading,
      hasElectronicInvoice: hasElectronicInvoice ?? this.hasElectronicInvoice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'BusinessUser(id: $id, name: $name, businessName: $businessName, '
           'sector: ${businessSector.displayName}, revenue: $annualRevenue triệu)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BusinessUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 