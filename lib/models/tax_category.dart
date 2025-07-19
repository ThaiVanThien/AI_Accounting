// Enum cho các loại thuế
enum TaxType {
  vat,        // Thuế GTGT
  personalIncome, // Thuế TNCN  
  businessLicense, // Thuế môn bài
}

// Enum cho loại hộ kinh doanh
enum BusinessType {
  taxQuota,    // Hộ thuế khoán
  declaration, // Hộ kê khai
}

// Enum cho ngành nghề
enum BusinessSector {
  // Nông nghiệp
  agriculture,     // Trồng trọt, chăn nuôi
  aquaculture,     // Thủy sản nuôi trồng
  forestry,        // Rừng trồng
  
  // Sản xuất
  manufacturing,   // Sản xuất, chế biến
  construction,    // Xây dựng
  
  // Thương mại
  trading,         // Mua bán hàng hóa
  agency,          // Đại lý, môi giới
  
  // Dịch vụ
  transport,       // Vận tải
  restaurant,      // Ăn uống
  accommodation,   // Lưu trú
  entertainment,   // Karaoke, massage
  rental,          // Cho thuê tài sản
  other,           // Khác
}

// Mở rộng BusinessSector với thông tin chi tiết
extension BusinessSectorExtension on BusinessSector {
  String get displayName {
    switch (this) {
      case BusinessSector.agriculture:
        return 'Trồng trọt, chăn nuôi';
      case BusinessSector.aquaculture:
        return 'Thủy sản nuôi trồng';
      case BusinessSector.forestry:
        return 'Rừng trồng';
      case BusinessSector.manufacturing:
        return 'Sản xuất, chế biến';
      case BusinessSector.construction:
        return 'Xây dựng';
      case BusinessSector.trading:
        return 'Mua bán hàng hóa';
      case BusinessSector.agency:
        return 'Đại lý, môi giới';
      case BusinessSector.transport:
        return 'Vận tải';
      case BusinessSector.restaurant:
        return 'Ăn uống';
      case BusinessSector.accommodation:
        return 'Lưu trú';
      case BusinessSector.entertainment:
        return 'Karaoke, massage';
      case BusinessSector.rental:
        return 'Cho thuê tài sản';
      case BusinessSector.other:
        return 'Khác';
    }
  }

  // Thuế suất TNCN theo % doanh thu
  double get personalIncomeTaxRate {
    switch (this) {
      case BusinessSector.agriculture:
      case BusinessSector.aquaculture:
      case BusinessSector.forestry:
        return 0.5;
      case BusinessSector.manufacturing:
      case BusinessSector.transport:
      case BusinessSector.restaurant:
        return 1.5;
      case BusinessSector.construction:
      case BusinessSector.accommodation:
        return 2.0;
      case BusinessSector.trading:
        return 0.5;
      case BusinessSector.agency:
        return 1.0;
      case BusinessSector.entertainment:
        return 4.0;
      case BusinessSector.rental:
        return 5.0;
      case BusinessSector.other:
        return 1.5;
    }
  }

  // Thuế suất VAT mặc định

} 