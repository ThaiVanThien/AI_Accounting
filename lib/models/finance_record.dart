class FinanceRecord {
  final int id;
  final double doanhThu;
  final double chiPhi;
  final String ghiChu;
  final DateTime ngayTao;

  FinanceRecord({
    required this.id,
    required this.doanhThu,
    required this.chiPhi,
    required this.ghiChu,
    required this.ngayTao,
  });

  double get loiNhuan => doanhThu - chiPhi;

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doanhThu': doanhThu,
      'chiPhi': chiPhi,
      'ghiChu': ghiChu,
      'ngayTao': ngayTao.toIso8601String(),
    };
  }

  factory FinanceRecord.fromJson(Map<String, dynamic> json) {
    return FinanceRecord(
      id: json['id'] ?? 0,
      doanhThu: (json['doanhThu'] ?? 0).toDouble(),
      chiPhi: (json['chiPhi'] ?? 0).toDouble(),
      ghiChu: json['ghiChu'] ?? '',
      ngayTao: DateTime.parse(json['ngayTao']),
    );
  }

  // Copy with method
  FinanceRecord copyWith({
    int? id,
    double? doanhThu,
    double? chiPhi,
    String? ghiChu,
    DateTime? ngayTao,
  }) {
    return FinanceRecord(
      id: id ?? this.id,
      doanhThu: doanhThu ?? this.doanhThu,
      chiPhi: chiPhi ?? this.chiPhi,
      ghiChu: ghiChu ?? this.ghiChu,
      ngayTao: ngayTao ?? this.ngayTao,
    );
  }

  @override
  String toString() {
    return 'FinanceRecord(id: $id, doanhThu: $doanhThu, chiPhi: $chiPhi, ghiChu: $ghiChu, ngayTao: $ngayTao)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FinanceRecord &&
        other.id == id &&
        other.doanhThu == doanhThu &&
        other.chiPhi == chiPhi &&
        other.ghiChu == ghiChu &&
        other.ngayTao == ngayTao;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        doanhThu.hashCode ^
        chiPhi.hashCode ^
        ghiChu.hashCode ^
        ngayTao.hashCode;
  }
} 