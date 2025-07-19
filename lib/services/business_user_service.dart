import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../constants/tax_rates.dart';

class BusinessUserService {
  static const String _businessUserKey = 'business_user';
  static const String _setupCompletedKey = 'setup_completed';

  // Lưu thông tin business user
  static Future<void> saveBusinessUser(BusinessUser user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = json.encode(user.toMap());
    await prefs.setString(_businessUserKey, userJson);
    await prefs.setBool(_setupCompletedKey, true);
  }

  // Lấy thông tin business user
  static Future<BusinessUser?> getBusinessUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_businessUserKey);
    
    if (userJson == null) {
      return null;
    }

    try {
      final userMap = json.decode(userJson) as Map<String, dynamic>;
      return BusinessUser.fromMap(userMap);
    } catch (e) {
      print('Error loading business user: $e');
      return null;
    }
  }

  // Kiểm tra đã setup chưa
  static Future<bool> isSetupCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_setupCompletedKey) ?? false;
  }

  // Cập nhật thông tin business user
  static Future<void> updateBusinessUser(BusinessUser user) async {
    final updatedUser = user.copyWith(updatedAt: DateTime.now());
    await saveBusinessUser(updatedUser);
  }

  // Xóa thông tin business user (reset app)
  static Future<void> clearBusinessUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_businessUserKey);
    await prefs.remove(_setupCompletedKey);
  }

  // Tính toán thuế cho business user
  static TaxCalculationResult calculateTaxForUser(
    BusinessUser user, 
    double monthlyRevenue
  ) {
    return TaxHelper.calculateTax(
      businessSector: user.businessSector,
      businessType: user.businessType,
      monthlyRevenue: monthlyRevenue,
      isEcommerceTrading: user.isEcommerceTrading,
    );
  }

  // Lấy thông tin thuế mặc định cho user
  static TaxCalculationResult getDefaultTaxCalculation(BusinessUser user, double actualTotalIncome) {
    final monthlyRevenue = actualTotalIncome / 12;
    return calculateTaxForUser(user, monthlyRevenue);
  }

  // Kiểm tra xem user có cần chuyển từ khoán sang kê khai không
  static bool shouldSwitchToDeclaration(BusinessUser user) {
    return TaxHelper.shouldSwitchToDeclaration(user);
  }

  // Lấy các gợi ý về thuế cho user
  static List<String> getTaxRecommendations(BusinessUser user, double actualTotalIncome) {
    final recommendations = <String>[];
    
    // Kiểm tra ngưỡng miễn thuế VAT
    if (TaxRates.isVATExempt(actualTotalIncome)) {
      final thresholdFormatted = TaxHelper.formatCurrency(TaxRates.VAT_EXEMPTION_THRESHOLD);
      recommendations.add('Bạn được miễn thuế VAT do tổng thu nhập < $thresholdFormatted/năm');
    }

    // Kiểm tra hóa đơn điện tử
    if (TaxRates.requiresElectronicInvoice(actualTotalIncome) && !user.hasElectronicInvoice) {
      final thresholdFormatted = TaxHelper.formatCurrency(TaxRates.ELECTRONIC_INVOICE_THRESHOLD);
      recommendations.add('Tổng thu nhập ≥ $thresholdFormatted cần sử dụng hóa đơn điện tử');
    }

    // Kiểm tra chuyển đổi thuế khoán - cần cập nhật logic dựa trên tổng thu nhập thực tế
    if (actualTotalIncome > 0) {
      // Tạo BusinessUser tạm với tổng thu nhập thực tế để kiểm tra
      final tempUser = user.copyWith(annualRevenue: actualTotalIncome);
      if (shouldSwitchToDeclaration(tempUser)) {
        recommendations.add('Nên chuyển sang kê khai do tổng thu nhập cao');
      }
    }

    // Kiểm tra TMĐT
    if (user.isEcommerceTrading) {
      recommendations.add('Kinh doanh TMĐT: Kiểm tra chính sách khấu trừ thuế của sàn');
    }

    return recommendations;
  }

  // Lấy thông tin thuế theo ngành nghề
  static Map<String, dynamic> getSectorTaxInfo(BusinessSector sector) {
    return {
      'name': sector.displayName,
      'personalIncomeTaxRate': sector.personalIncomeTaxRate,
      'defaultVATRate': TaxRates.getCurrentVATRate(),
    };
  }
}  