class ShopInfo {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final String businessType;
  final String ownerName;
  final String taxCode;
  final String logo; // đường dẫn ảnh logo
  final DateTime createdAt;
  final DateTime updatedAt;

  ShopInfo({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.businessType,
    this.ownerName = '',
    this.taxCode = '',
    this.logo = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'businessType': businessType,
      'ownerName': ownerName,
      'taxCode': taxCode,
      'logo': logo,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ShopInfo.fromJson(Map<String, dynamic> json) {
    return ShopInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      businessType: json['businessType'] ?? '',
      ownerName: json['ownerName'] ?? '',
      taxCode: json['taxCode'] ?? '',
      logo: json['logo'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Copy with method
  ShopInfo copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? businessType,
    String? ownerName,
    String? taxCode,
    String? logo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShopInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      businessType: businessType ?? this.businessType,
      ownerName: ownerName ?? this.ownerName,
      taxCode: taxCode ?? this.taxCode,
      logo: logo ?? this.logo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'ShopInfo(id: $id, name: $name, address: $address, phone: $phone, businessType: $businessType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShopInfo &&
        other.id == id &&
        other.name == name &&
        other.address == address &&
        other.phone == phone &&
        other.email == email &&
        other.businessType == businessType;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        address.hashCode ^
        phone.hashCode ^
        email.hashCode ^
        businessType.hashCode;
  }

  // Danh sách loại hình kinh doanh mặc định
  static const List<String> defaultBusinessTypes = [
    'Bán lẻ',
    'Bán buôn',
    'Dịch vụ',
    'Nhà hàng - Quán ăn',
    'Cafe - Trà sữa',
    'Thời trang',
    'Điện tử - Công nghệ',
    'Sức khỏe - Làm đẹp',
    'Giáo dục',
    'Khác'
  ];
}
