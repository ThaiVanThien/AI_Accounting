import '../constants/tax_rates.dart';
import 'business_user.dart';
import 'tax_category.dart';

class TaxCalculationResult {
  final double vatAmount;
  final double personalIncomeTaxAmount;
  final double businessLicenseTaxAmount;
  final double totalTaxAmount;
  final VATRate vatRate;
  final double personalIncomeTaxRate;
  final bool isVATExempt;
  final String notes;

  TaxCalculationResult({
    required this.vatAmount,
    required this.personalIncomeTaxAmount,
    required this.businessLicenseTaxAmount,
    required this.totalTaxAmount,
    required this.vatRate,
    required this.personalIncomeTaxRate,
    required this.isVATExempt,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'vatAmount': vatAmount,
      'personalIncomeTaxAmount': personalIncomeTaxAmount,
      'businessLicenseTaxAmount': businessLicenseTaxAmount,
      'totalTaxAmount': totalTaxAmount,
      'vatRate': vatRate.index,
      'personalIncomeTaxRate': personalIncomeTaxRate,
      'isVATExempt': isVATExempt,
      'notes': notes,
    };
  }

  factory TaxCalculationResult.fromMap(Map<String, dynamic> map) {
    return TaxCalculationResult(
      vatAmount: (map['vatAmount'] ?? 0).toDouble(),
      personalIncomeTaxAmount: (map['personalIncomeTaxAmount'] ?? 0).toDouble(),
      businessLicenseTaxAmount: (map['businessLicenseTaxAmount'] ?? 0).toDouble(),
      totalTaxAmount: (map['totalTaxAmount'] ?? 0).toDouble(),
      vatRate: VATRate.values[map['vatRate'] ?? 0],
      personalIncomeTaxRate: (map['personalIncomeTaxRate'] ?? 0).toDouble(),
      isVATExempt: map['isVATExempt'] ?? false,
      notes: map['notes'] ?? '',
    );
  }
}

class TaxCalculator {
  // Tính thuế cho một khoản doanh thu cụ thể
  static TaxCalculationResult calculateTax({
    required BusinessUser user,
    required double revenue, // Doanh thu trong kỳ (triệu đồng)
    bool isMonthly = true, // true: tháng, false: quý
  }) {
    final notes = <String>[];
    
    // 1. Tính thuế VAT
    double vatAmount = 0;
    VATRate vatRate = VATRate.exempt;
    bool isVATExempt = user.isVATExempt;
    
    if (!isVATExempt) {
      vatRate = _getVATRate(user.businessSector);
      vatAmount = _calculateVAT(revenue, vatRate);
      notes.add('Thuế VAT ${_getVATRatePercentage(vatRate)}%');
    } else {
      notes.add('Miễn thuế VAT (doanh thu < 200 triệu/năm)');
    }

    // 2. Tính thuế TNCN
    double personalIncomeTaxRate = user.businessSector.personalIncomeTaxRate;
    double personalIncomeTaxAmount = revenue * personalIncomeTaxRate / 100;
    notes.add('Thuế TNCN ${personalIncomeTaxRate}% trên doanh thu');

    // 3. Tính thuế môn bài (chỉ tính hàng năm)
    double businessLicenseTaxAmount = 0;
    if (!isMonthly) {
      businessLicenseTaxAmount = user.businessLicenseTaxAmount;
      if (businessLicenseTaxAmount > 0) {
        notes.add('Thuế môn bài: ${_formatMoney(businessLicenseTaxAmount)} triệu đồng/năm');
      } else {
        notes.add('Miễn thuế môn bài');
      }
    }

    // 4. Tổng thuế
    double totalTaxAmount = vatAmount + personalIncomeTaxAmount + businessLicenseTaxAmount;

    // 5. Ghi chú đặc biệt
    if (user.isEcommerceTrading) {
      notes.add('Kinh doanh TMĐT: Cần tuân thủ quy định từ 1/7/2025');
    }
    
    if (user.requiresElectronicInvoice && !user.hasElectronicInvoice) {
      notes.add('Cần sử dụng hóa đơn điện tử');
    }

    return TaxCalculationResult(
      vatAmount: vatAmount,
      personalIncomeTaxAmount: personalIncomeTaxAmount,
      businessLicenseTaxAmount: businessLicenseTaxAmount,
      totalTaxAmount: totalTaxAmount,
      vatRate: vatRate,
      personalIncomeTaxRate: personalIncomeTaxRate,
      isVATExempt: isVATExempt,
      notes: notes.join('; '),
    );
  }

  // Tính thuế hàng năm
  static TaxCalculationResult calculateAnnualTax({
    required BusinessUser user,
    required double annualRevenue,
  }) {
    return calculateTax(
      user: user,
      revenue: annualRevenue,
      isMonthly: false,
    );
  }

  // Lấy thuế suất VAT theo ngành nghề
  static VATRate _getVATRate(BusinessSector sector) {
    // Áp dụng thuế suất 8% (giảm từ 10%) đến 31/12/2026
    final now = DateTime.now();
    final isDiscountPeriod = now.isBefore(DateTime(2027, 1, 1));
    
    switch (sector) {
      case BusinessSector.agriculture:
      case BusinessSector.aquaculture:
      case BusinessSector.forestry:
        return VATRate.five; // 5% cho nông sản
      default:
        return isDiscountPeriod ? VATRate.eight : VATRate.ten;
    }
  }

  // Tính thuế VAT
  static double _calculateVAT(double revenue, VATRate rate) {
    double percentage = _getVATRatePercentage(rate);
    return revenue * percentage / 100;
  }

  // Lấy phần trăm thuế VAT
  static double _getVATRatePercentage(VATRate rate) {
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

  // Format tiền
  static String _formatMoney(double amount) {
    return amount.toStringAsFixed(1);
  }

  // Tính thuế theo kỳ (tháng/quý)
  static List<TaxCalculationResult> calculatePeriodTax({
    required BusinessUser user,
    required List<double> periodRevenues, // Doanh thu các kỳ
    bool isMonthly = true,
  }) {
    return periodRevenues.map((revenue) {
      return calculateTax(
        user: user,
        revenue: revenue,
        isMonthly: isMonthly,
      );
    }).toList();
  }

  // Dự báo thuế cả năm dựa trên doanh thu hiện tại
  static TaxCalculationResult forecastAnnualTax({
    required BusinessUser user,
    required double currentRevenue,
    required int periodsCompleted, // Số kỳ đã qua (tháng hoặc quý)
    bool isMonthly = true,
  }) {
    int totalPeriods = isMonthly ? 12 : 4;
    double projectedAnnualRevenue = (currentRevenue / periodsCompleted) * totalPeriods;
    
    return calculateAnnualTax(
      user: user,
      annualRevenue: projectedAnnualRevenue,
    );
  }
} 