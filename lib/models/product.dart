class Product {
  final String id;
  final String code;
  final String name;
  final double sellingPrice;
  final double costPrice;
  final String unit; // Cái, Hộp, Kg, Lít, Thùng
  final String description;
  final bool isActive; // đang bán / ngừng bán
  final int stockQuantity;
  final int minStockLevel; // số lượng tối thiểu cảnh báo
  final String category; // nhóm hàng
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.code,
    required this.name,
    required this.sellingPrice,
    required this.costPrice,
    required this.unit,
    this.description = '',
    this.isActive = true,
    this.stockQuantity = 0,
    this.minStockLevel = 0,
    this.category = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Tính lợi nhuận trên 1 đơn vị
  double get profitPerUnit => sellingPrice - costPrice;

  // Tính tỷ lệ lợi nhuận (%)
  double get profitMargin => costPrice > 0 ? (profitPerUnit / costPrice * 100) : 0;

  // Kiểm tra cảnh báo tồn kho thấp
  bool get isLowStock => stockQuantity <= minStockLevel;

  // Tính giá trị tồn kho
  double get stockValue => stockQuantity * costPrice;

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'sellingPrice': sellingPrice,
      'costPrice': costPrice,
      'unit': unit,
      'description': description,
      'isActive': isActive,
      'stockQuantity': stockQuantity,
      'minStockLevel': minStockLevel,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      sellingPrice: (json['sellingPrice'] ?? 0).toDouble(),
      costPrice: (json['costPrice'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'Cái',
      description: json['description'] ?? '',
      isActive: json['isActive'] ?? true,
      stockQuantity: json['stockQuantity'] ?? 0,
      minStockLevel: json['minStockLevel'] ?? 0,
      category: json['category'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Copy with method
  Product copyWith({
    String? id,
    String? code,
    String? name,
    double? sellingPrice,
    double? costPrice,
    String? unit,
    String? description,
    bool? isActive,
    int? stockQuantity,
    int? minStockLevel,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      costPrice: costPrice ?? this.costPrice,
      unit: unit ?? this.unit,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Product(id: $id, code: $code, name: $name, sellingPrice: $sellingPrice, costPrice: $costPrice, unit: $unit, isActive: $isActive, stockQuantity: $stockQuantity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product &&
        other.id == id &&
        other.code == code &&
        other.name == name &&
        other.sellingPrice == sellingPrice &&
        other.costPrice == costPrice &&
        other.unit == unit &&
        other.description == description &&
        other.isActive == isActive &&
        other.stockQuantity == stockQuantity &&
        other.minStockLevel == minStockLevel &&
        other.category == category;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        code.hashCode ^
        name.hashCode ^
        sellingPrice.hashCode ^
        costPrice.hashCode ^
        unit.hashCode ^
        description.hashCode ^
        isActive.hashCode ^
        stockQuantity.hashCode ^
        minStockLevel.hashCode ^
        category.hashCode;
  }

  // Tạo mã sản phẩm tự động
  static String generateProductCode(String prefix, int sequence) {
    return '$prefix${sequence.toString().padLeft(6, '0')}';
  }

  // Danh sách đơn vị tính mặc định
  static const List<String> defaultUnits = [
    'Cái',
    'Hộp',
    'Kg',
    'Thùng',
    'Lạng',
    'Chai',
  ];

  // Danh sách nhóm hàng mặc định
  static const List<String> defaultCategories = [
    'Thực phẩm',
    'Đồ uống',
    'Gia dụng',
    'Điện tử',
    'Thời trang',
    'Sức khỏe',
    'Văn phòng phẩm',
    'Khác'
  ];
}
