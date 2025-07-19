import 'dart:math';
import 'models.dart' hide VATRate;
import '../constants/tax_rates.dart';

class TaxHelper {
  // Phân loại hộ kinh doanh dựa trên doanh thu
  static BusinessType classifyBusinessType(double annualRevenue) {
    // Hiện tại còn áp dụng thuế khoán đến 31/12/2025
    final now = DateTime.now();
    if (now.isBefore(DateTime(2026, 1, 1))) {
      // Có thể chọn thuế khoán hoặc kê khai
      return BusinessType.taxQuota; // Mặc định khoán
    }
    // Từ 2026 trở đi, tất cả chuyển sang kê khai
    return BusinessType.declaration;
  }

  // Kiểm tra có cần chuyển từ khoán sang kê khai không
  static bool shouldSwitchToDeclaration(BusinessUser user) {
    // Hộ có doanh thu >= 1 tỷ bắt buộc chuyển sang kê khai từ 1/6/2025
    final now = DateTime.now();
    if (now.isAfter(DateTime(2025, 6, 1)) && user.annualRevenue >= 1000000000) {
      return true;
    }
    return false;
  }

  // Lấy danh sách ngành nghề phổ biến
  static List<BusinessSector> getPopularBusinessSectors() {
    return [
      BusinessSector.trading,      // Mua bán hàng hóa
      BusinessSector.restaurant,   // Ăn uống
      BusinessSector.manufacturing, // Sản xuất
      BusinessSector.transport,    // Vận tải
      BusinessSector.agriculture,  // Nông nghiệp
      BusinessSector.agency,       // Đại lý
      BusinessSector.accommodation, // Lưu trú
      BusinessSector.other,        // Khác
    ];
  }

  // Lấy thuế suất TNCN theo ngành nghề (trả về %)
  static double getPersonalIncomeTaxRate(BusinessSector sector) {
    return sector.personalIncomeTaxRate;
  }

  // Kiểm tra có miễn thuế VAT không
  static bool isVATExempt(double annualRevenue) {
    return TaxRates.isVATExempt(annualRevenue);
  }

  // Tính thuế môn bài theo doanh thu (đơn vị: đồng)
  static double calculateBusinessLicenseTax(double annualRevenue) {
    return TaxRates.calculateBusinessLicenseTax(annualRevenue);
  }

  // Lấy thuế suất VAT hiện tại (có tính đến giảm thuế)
  static VATRate getCurrentVATRate(BusinessSector sector) {
    // Nông sản luôn là 5%
    if (sector == BusinessSector.agriculture || 
        sector == BusinessSector.aquaculture || 
        sector == BusinessSector.forestry) {
      return VATRate.five;
    }
    
    // Sử dụng thuế suất mặc định từ TaxRates (8% cho đến 31/12/2026)
    final defaultRate = TaxRates.getCurrentVATRate();
    if (defaultRate == TaxRates.VAT_RATE_EIGHT) {
      return VATRate.eight;
    }
    return VATRate.ten;
  }

  // Tính phần trăm thuế VAT
  static double getVATPercentage(VATRate rate) {
    switch (rate) {
      case VATRate.exempt:
      case VATRate.zero:
        return 0;
      case VATRate.five:
        return 5;
      case VATRate.eight:
        return 8;
      case VATRate.ten:
        return 10;
    }
  }

  // Kiểm tra có bắt buộc dùng hóa đơn điện tử không
  static bool requiresElectronicInvoice(BusinessUser user) {
    return user.requiresElectronicInvoice;
  }

  // Tạo số hóa đơn tự động
  static String generateInvoiceNumber({
    required String prefix,
    required int sequence,
    int length = 6,
  }) {
    final sequenceStr = sequence.toString().padLeft(length, '0');
    final year = DateTime.now().year;
    return '$prefix$year$sequenceStr';
  }

  // Lấy kỳ báo cáo hiện tại
  static Map<String, int> getCurrentReportPeriod() {
    final now = DateTime.now();
    return {
      'year': now.year,
      'month': now.month,
      'quarter': ((now.month - 1) ~/ 3) + 1,
    };
  }

  // Kiểm tra có vượt ngưỡng chuyển khoản không
  static bool requiresNonCashPayment(double amount) {
    return TaxRates.requiresNonCashPayment(amount);
  }

  // Format tiền tệ Việt Nam
  static String formatCurrency(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)} tỷ';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)} triệu';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)} nghìn';
    } else {
      return '${amount.toStringAsFixed(0)} đồng';
    }
  }

  // Tính dự báo thuế năm
  static TaxCalculationResult forecastYearlyTax({
    required BusinessUser user,
    required double currentMonthlyRevenue,
    required int monthsCompleted,
  }) {
    return TaxCalculator.forecastAnnualTax(
      user: user,
      currentRevenue: currentMonthlyRevenue * monthsCompleted,
      periodsCompleted: monthsCompleted,
      isMonthly: true,
    );
  }

  // Lấy deadline nộp thuế
  static DateTime getTaxDeadline({
    required bool isMonthly,
    required int year,
    required int period,
  }) {
    if (isMonthly) {
      // Nộp thuế tháng trước ngày 20 tháng sau
      if (period == 12) {
        return DateTime(year + 1, 1, 20);
      } else {
        return DateTime(year, period + 1, 20);
      }
    } else {
      // Nộp thuế quý trước ngày cuối tháng đầu quý sau
      final nextQuarterFirstMonth = period * 3 + 1;
      if (nextQuarterFirstMonth > 12) {
        return DateTime(year + 1, 1, 31);
      } else {
        return DateTime(year, nextQuarterFirstMonth, 31);
      }
    }
  }

  // Kiểm tra có quá hạn nộp thuế không
  static bool isOverdue(DateTime deadline) {
    return DateTime.now().isAfter(deadline);
  }

  // Tính số ngày còn lại đến deadline
  static int daysUntilDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now).inDays;
    return max(0, difference);
  }

  // Lấy thông báo tuân thủ
  static List<String> getComplianceReminders(BusinessUser user) {
    final reminders = <String>[];
    final now = DateTime.now();

    // Kiểm tra hóa đơn điện tử
    if (user.requiresElectronicInvoice && !user.hasElectronicInvoice) {
      reminders.add('Cần sử dụng hóa đơn điện tử theo quy định');
    }

    // Kiểm tra chuyển đổi từ khoán sang kê khai
    if (shouldSwitchToDeclaration(user) && user.businessType == BusinessType.taxQuota) {
      reminders.add('Cần chuyển từ thuế khoán sang kê khai');
    }

    // Kiểm tra TMĐT  
    if (user.isEcommerceTrading) {
      reminders.add('Tuân thủ quy định thuế thương mại điện tử từ 1/7/2025');
    }

    // Chuẩn bị cho 2026
    if (now.isAfter(DateTime(2025, 10, 1))) {
      reminders.add('Chuẩn bị cho việc bỏ thuế khoán từ 1/1/2026');
    }

    return reminders;
  }

  // MAIN METHOD: Tính tổng thuế cho hộ kinh doanh
  static TaxCalculationResult calculateTax({
    required BusinessSector businessSector,
    required BusinessType businessType,
    required double monthlyRevenue,
    required bool isEcommerceTrading,
  }) {
    // Tính doanh thu năm từ doanh thu tháng
    final annualRevenue = monthlyRevenue * 12;
    
    // Kiểm tra miễn thuế VAT
    final isVATExempt = TaxHelper.isVATExempt(annualRevenue);
    
    // Tính thuế VAT
    double vatAmount = 0.0;
    VATRate vatRate = VATRate.exempt;
    
    if (!isVATExempt) {
      vatRate = getCurrentVATRate(businessSector);
      final vatPercentage = getVATPercentage(vatRate);
      vatAmount = monthlyRevenue * vatPercentage / 100;
    }

    // Tính thuế TNCN
    final personalIncomeTaxRate = businessSector.personalIncomeTaxRate / 100; // Chuyển % thành decimal
    final personalIncomeTaxAmount = monthlyRevenue * personalIncomeTaxRate;

    // Tính thuế môn bài (chia đều cho 12 tháng)
    final businessLicenseTaxAmount = calculateBusinessLicenseTax(annualRevenue) / 12;

    // Tổng thuế
    final totalTaxAmount = vatAmount + personalIncomeTaxAmount + businessLicenseTaxAmount;

    // Tạo ghi chú
    String notes = '';
    if (isVATExempt) {
      final thresholdFormatted = TaxHelper.formatCurrency(TaxRates.VAT_EXEMPTION_THRESHOLD);
      notes = 'Miễn thuế VAT do doanh thu < $thresholdFormatted/năm. ';
    }
    if (isEcommerceTrading) {
      notes += 'Kinh doanh TMĐT: Kiểm tra chính sách khấu trừ thuế của sàn. ';
    }
    if (annualRevenue >= 1000000000) {
      notes += 'Doanh thu ≥ 1 tỷ: Bắt buộc sử dụng hóa đơn điện tử từ 1/6/2025. ';
    }

    return TaxCalculationResult(
      vatAmount: vatAmount,
      personalIncomeTaxAmount: personalIncomeTaxAmount,
      businessLicenseTaxAmount: businessLicenseTaxAmount,
      totalTaxAmount: totalTaxAmount,
      vatRate: vatRate,
      personalIncomeTaxRate: personalIncomeTaxRate,
      isVATExempt: isVATExempt,
      notes: notes.trim(),
    );
  }
} 