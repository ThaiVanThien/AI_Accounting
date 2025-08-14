class Customer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email = '',
    this.address = '',
    this.note = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = true,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // JSON serialization
  Map<String, dynamic> toJson() { 
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory Customer.fromJson(Map<String, dynamic> json) { 
    try {
      return Customer(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '', 
        phone: json['phone']?.toString() ?? '', 
        email: json['email']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        note: json['note']?.toString() ?? '', 
        createdAt: json['createdAt'] != null 
            ? DateTime.parse(json['createdAt'].toString())
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null 
            ? DateTime.parse(json['updatedAt'].toString())
            : DateTime.now(),
        isActive: json['isActive'] ?? true,
      );
    } catch (e) {
      print('Error parsing Customer from JSON: $e');
      // Trả về customer mặc định nếu có lỗi
      return Customer(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Khách hàng',
        phone: json['phone']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        note: json['note']?.toString() ?? '',
        isActive: json['isActive'] ?? true,
      );
    }
  }

  // Copy with method
  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isActive: isActive ?? this.isActive,
    );
  }

  // Tạo khách hàng lẻ (khách vãng lai)
  factory Customer.walkIn() {
    return Customer(
      id: 'walk_in',
      name: 'Khách lẻ',
      phone: '',
      email: '',
      address: '',
      note: 'Khách hàng vãng lai',
      isActive: true,
    );
  }

  // Kiểm tra có phải khách lẻ không
  bool get isWalkIn => id == 'walk_in';

  // Hiển thị tên khách hàng
  String get displayName {
    if (isWalkIn) return 'Khách lẻ';
    return name.isNotEmpty ? name : 'Khách hàng';
  }

  // Hiển thị thông tin liên hệ
  String get contactInfo {
    if (isWalkIn) return 'Khách vãng lai';
    final parts = <String>[];
    if (phone.isNotEmpty) parts.add(phone);
    if (email.isNotEmpty) parts.add(email);
    if (address.isNotEmpty) parts.add(address);
    return parts.isEmpty ? 'Không có thông tin liên hệ' : parts.join(' • ');
  }

  // Kiểm tra customer có hợp lệ không
  bool get isValid {
    if (isWalkIn) return true;
    return name.trim().isNotEmpty && phone.trim().isNotEmpty;
  }

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, phone: $phone)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
