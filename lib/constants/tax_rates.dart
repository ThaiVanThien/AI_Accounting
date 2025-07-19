/// File quản lý tất cả các mức thuế và ngưỡng thuế
/// Khi có thay đổi thuế, chỉ cần cập nhật file này
class TaxRates {
  // ========================================================================
  // THUẾ GIÁ TRỊ GIA TĂNG (VAT)
  // ========================================================================
  
  /// Ngưỡng miễn thuế VAT (đơn vị: VND)
  static const double VAT_EXEMPTION_THRESHOLD = 100000000; // 100 triệu VND
  
  /// Các mức thuế suất VAT (%)
  static const double VAT_RATE_ZERO = 0.0;
  static const double VAT_RATE_FIVE = 5.0;
  static const double VAT_RATE_EIGHT = 8.0;  // Tạm thời đến 31/12/2026
  static const double VAT_RATE_TEN = 10.0;   // Thuế suất thường
  
  /// Thuế suất VAT mặc định hiện tại
  static const double VAT_RATE_DEFAULT = VAT_RATE_EIGHT; // 8% cho đến 31/12/2026
  
  // ========================================================================
  // THUẾ THU NHẬP CÁ NHÂN (TNCN) - % TRÊN DOANH THU
  // ========================================================================
  
  /// Thuế suất TNCN theo ngành nghề (%)
  static const Map<String, double> PERSONAL_INCOME_TAX_RATES = {
    // NÔNG NGHIỆP
    'agriculture': 0.5,      // Trồng trọt, chăn nuôi
    'aquaculture': 0.5,      // Thủy sản nuôi trồng
    'forestry': 0.5,         // Lâm nghiệp, rừng trồng
    
    // SẢN XUẤT
    'manufacturing': 1.5,    // Sản xuất, chế biến
    'construction': 2.0,     // Xây dựng
    
    // THƯƠNG MẠI
    'trading': 0.5,          // Mua bán hàng hóa
    'agency': 1.0,           // Đại lý, môi giới
    
    // DỊCH VỤ
    'transport': 1.5,        // Vận tải
    'restaurant': 1.5,       // Ăn uống
    'accommodation': 2.0,    // Lưu trú (khách sạn, nhà nghỉ)
    'entertainment': 4.0,    // Karaoke, massage
    'rental': 5.0,           // Cho thuê tài sản
    'other': 1.5,            // Ngành nghề khác
  };
  
  // ========================================================================
  // THUẾ MÔN BÀI
  // ========================================================================
  
  /// Các mức thuế môn bài theo doanh thu (VND)
  static const List<TaxBracket> BUSINESS_LICENSE_TAX_BRACKETS = [
    TaxBracket(min: 0, max: 100000000, tax: 0),          // < 100 triệu: MIỄN
    TaxBracket(min: 100000000, max: 300000000, tax: 300000),  // 100-300 triệu: 300k
    TaxBracket(min: 300000000, max: 500000000, tax: 500000),  // 300-500 triệu: 500k
    TaxBracket(min: 500000000, max: double.infinity, tax: 1000000), // >500 triệu: 1 triệu
  ];
  
  // ========================================================================
  // HÓA ĐƠN ĐIỆN TỬ
  // ========================================================================
  
  /// Ngưỡng bắt buộc sử dụng hóa đơn điện tử (VND)
  static const double ELECTRONIC_INVOICE_THRESHOLD = 1000000000; // 1 tỷ VND
  
  // ========================================================================
  // THANH TOÁN KHÔNG DÙNG TIỀN MẶT
  // ========================================================================
  
  /// Ngưỡng bắt buộc thanh toán không dùng tiền mặt (VND)
  static const double NON_CASH_PAYMENT_THRESHOLD = 5000000; // 5 triệu VND
  
  // ========================================================================
  // THƯƠNG MẠI ĐIỆN TỬ
  // ========================================================================
  
  /// Thuế suất cho TMĐT (% trên doanh thu)
  static const double ECOMMERCE_TAX_RATE_MIN = 0.5;
  static const double ECOMMERCE_TAX_RATE_MAX = 5.0;
  
  // ========================================================================
  // HELPER METHODS
  // ========================================================================
  
  /// Lấy thuế suất TNCN theo ngành nghề
  static double getPersonalIncomeTaxRate(String businessSector) {
    return PERSONAL_INCOME_TAX_RATES[businessSector] ?? PERSONAL_INCOME_TAX_RATES['other']!;
  }
  
  /// Tính thuế môn bài theo doanh thu
  static double calculateBusinessLicenseTax(double annualRevenue) {
    for (final bracket in BUSINESS_LICENSE_TAX_BRACKETS) {
      if (annualRevenue >= bracket.min && annualRevenue < bracket.max) {
        return bracket.tax;
      }
    }
    return BUSINESS_LICENSE_TAX_BRACKETS.last.tax;
  }
  
  /// Kiểm tra có miễn thuế VAT không
  static bool isVATExempt(double annualRevenue) {
    return annualRevenue < VAT_EXEMPTION_THRESHOLD;
  }
  
  /// Lấy thuế suất VAT hiện tại
  static double getCurrentVATRate() {
    return VAT_RATE_DEFAULT; // 8% cho đến 31/12/2026
  }
  
  /// Kiểm tra có bắt buộc dùng hóa đơn điện tử không
  static bool requiresElectronicInvoice(double annualRevenue) {
    return annualRevenue >= ELECTRONIC_INVOICE_THRESHOLD;
  }
  
  /// Kiểm tra có bắt buộc thanh toán không dùng tiền mặt không
  static bool requiresNonCashPayment(double amount) {
    return amount >= NON_CASH_PAYMENT_THRESHOLD;
  }
}

/// Class để định nghĩa các khung thuế
class TaxBracket {
  final double min;
  final double max;
  final double tax;
  
  const TaxBracket({
    required this.min,
    required this.max,
    required this.tax,
  });
}

/// Enum cho các mức thuế suất VAT
enum VATRate {
  exempt(0.0),
  zero(0.0),
  five(5.0),
  eight(8.0),
  ten(10.0);
  
  const VATRate(this.percentage);
  final double percentage;
} 