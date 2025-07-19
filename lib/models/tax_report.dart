import '../constants/tax_rates.dart';
import 'business_user.dart';
import 'tax_calculation.dart';
import 'invoice.dart';
import 'tax_category.dart';

enum ReportPeriod {
  monthly,    // Tháng
  quarterly,  // Quý
  yearly,     // Năm
}

class TaxReport {
  final String id;
  final String businessUserId;
  final ReportPeriod period;
  final int year;
  final int periodNumber; // Tháng (1-12) hoặc Quý (1-4)
  final DateTime fromDate;
  final DateTime toDate;
  final List<Invoice> invoices;
  final TaxCalculationResult taxCalculation;
  final TaxReportSummary summary;
  final DateTime createdAt;

  TaxReport({
    required this.id,
    required this.businessUserId,
    required this.period,
    required this.year,
    required this.periodNumber,
    required this.fromDate,
    required this.toDate,
    required this.invoices,
    required this.taxCalculation,
    required this.summary,
    required this.createdAt,
  });

  // Tạo báo cáo từ dữ liệu
  factory TaxReport.generate({
    required BusinessUser user,
    required ReportPeriod period,
    required int year,
    required int periodNumber,
    required List<Invoice> invoices,
  }) {
    final dateRange = _getDateRange(period, year, periodNumber);
    final filteredInvoices = invoices.where((invoice) {
      return invoice.invoiceDate.isAfter(dateRange.start.subtract(Duration(days: 1))) &&
             invoice.invoiceDate.isBefore(dateRange.end.add(Duration(days: 1)));
    }).toList();

    final summary = TaxReportSummary.fromInvoices(filteredInvoices);
    final taxCalculation = TaxCalculator.calculateTax(
      user: user,
      revenue: summary.totalRevenue,
      isMonthly: period == ReportPeriod.monthly,
    );

    return TaxReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      businessUserId: user.id,
      period: period,
      year: year,
      periodNumber: periodNumber,
      fromDate: dateRange.start,
      toDate: dateRange.end,
      invoices: filteredInvoices,
      taxCalculation: taxCalculation,
      summary: summary,
      createdAt: DateTime.now(),
    );
  }

  // Lấy khoảng thời gian báo cáo
  static DateTimeRange _getDateRange(ReportPeriod period, int year, int periodNumber) {
    switch (period) {
      case ReportPeriod.monthly:
        final start = DateTime(year, periodNumber, 1);
        final end = DateTime(year, periodNumber + 1, 1).subtract(Duration(days: 1));
        return DateTimeRange(start: start, end: end);
      
      case ReportPeriod.quarterly:
        final startMonth = (periodNumber - 1) * 3 + 1;
        final start = DateTime(year, startMonth, 1);
        final end = DateTime(year, startMonth + 3, 1).subtract(Duration(days: 1));
        return DateTimeRange(start: start, end: end);
      
      case ReportPeriod.yearly:
        final start = DateTime(year, 1, 1);
        final end = DateTime(year, 12, 31);
        return DateTimeRange(start: start, end: end);
    }
  }

  // Chuyển đổi từ Map
  factory TaxReport.fromMap(Map<String, dynamic> map) {
    return TaxReport(
      id: map['id'] ?? '',
      businessUserId: map['businessUserId'] ?? '',
      period: ReportPeriod.values[map['period'] ?? 0],
      year: map['year'] ?? DateTime.now().year,
      periodNumber: map['periodNumber'] ?? 1,
      fromDate: DateTime.parse(map['fromDate']),
      toDate: DateTime.parse(map['toDate']),
      invoices: (map['invoices'] as List<dynamic>?)
          ?.map((e) => Invoice.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      taxCalculation: TaxCalculationResult.fromMap(map['taxCalculation'] ?? {}),
      summary: TaxReportSummary.fromMap(map['summary'] ?? {}),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  // Chuyển đổi thành Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessUserId': businessUserId,
      'period': period.index,
      'year': year,
      'periodNumber': periodNumber,
      'fromDate': fromDate.toIso8601String(),
      'toDate': toDate.toIso8601String(),
      'invoices': invoices.map((e) => e.toMap()).toList(),
      'taxCalculation': taxCalculation.toMap(),
      'summary': summary.toMap(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get periodDisplayName {
    switch (period) {
      case ReportPeriod.monthly:
        return 'Tháng $periodNumber/$year';
      case ReportPeriod.quarterly:
        return 'Quý $periodNumber/$year';
      case ReportPeriod.yearly:
        return 'Năm $year';
    }
  }

  @override
  String toString() {
    return 'TaxReport(period: $periodDisplayName, revenue: ${summary.totalRevenue} triệu, '
           'tax: ${taxCalculation.totalTaxAmount} triệu)';
  }
}

class TaxReportSummary {
  final double totalRevenue;        // Tổng doanh thu
  final double totalSalesAmount;    // Tổng tiền bán hàng
  final double totalVATAmount;      // Tổng thuế VAT
  final int totalInvoices;          // Tổng số hóa đơn
  final int electronicInvoices;     // Số hóa đơn điện tử
  final int cashPayments;           // Số giao dịch thanh toán tiền mặt
  final int nonCashPayments;        // Số giao dịch thanh toán không dùng tiền mặt
  final Map<VATRate, double> vatByRate; // VAT theo từng mức thuế suất

  TaxReportSummary({
    required this.totalRevenue,
    required this.totalSalesAmount,
    required this.totalVATAmount,
    required this.totalInvoices,
    required this.electronicInvoices,
    required this.cashPayments,
    required this.nonCashPayments,
    required this.vatByRate,
  });

  // Tạo summary từ danh sách hóa đơn
  factory TaxReportSummary.fromInvoices(List<Invoice> invoices) {
    double totalRevenue = 0;
    double totalSalesAmount = 0;
    double totalVATAmount = 0;
    int electronicInvoices = 0;
    int cashPayments = 0;
    int nonCashPayments = 0;
    Map<VATRate, double> vatByRate = {};

    for (final invoice in invoices) {
      if (invoice.type == InvoiceType.sale) {
        totalRevenue += invoice.amount;
        totalSalesAmount += invoice.totalAmount;
        totalVATAmount += invoice.vatAmount;

        // Thống kê VAT theo thuế suất
        vatByRate[invoice.vatRate] = (vatByRate[invoice.vatRate] ?? 0) + invoice.vatAmount;
      }

      if (invoice.isElectronic) {
        electronicInvoices++;
      }

      if (invoice.paymentMethod == PaymentMethod.cash) {
        cashPayments++;
      } else {
        nonCashPayments++;
      }
    }

    return TaxReportSummary(
      totalRevenue: totalRevenue,
      totalSalesAmount: totalSalesAmount,
      totalVATAmount: totalVATAmount,
      totalInvoices: invoices.length,
      electronicInvoices: electronicInvoices,
      cashPayments: cashPayments,
      nonCashPayments: nonCashPayments,
      vatByRate: vatByRate,
    );
  }

  // Tỷ lệ sử dụng hóa đơn điện tử
  double get electronicInvoiceRate {
    if (totalInvoices == 0) return 0;
    return (electronicInvoices / totalInvoices) * 100;
  }

  // Tỷ lệ thanh toán không dùng tiền mặt
  double get nonCashPaymentRate {
    if (totalInvoices == 0) return 0;
    return (nonCashPayments / totalInvoices) * 100;
  }

  // Chuyển đổi từ Map
  factory TaxReportSummary.fromMap(Map<String, dynamic> map) {
    Map<VATRate, double> vatByRate = {};
    if (map['vatByRate'] != null) {
      (map['vatByRate'] as Map<String, dynamic>).forEach((key, value) {
        vatByRate[VATRate.values[int.parse(key)]] = (value as num).toDouble();
      });
    }

    return TaxReportSummary(
      totalRevenue: (map['totalRevenue'] ?? 0).toDouble(),
      totalSalesAmount: (map['totalSalesAmount'] ?? 0).toDouble(),
      totalVATAmount: (map['totalVATAmount'] ?? 0).toDouble(),
      totalInvoices: map['totalInvoices'] ?? 0,
      electronicInvoices: map['electronicInvoices'] ?? 0,
      cashPayments: map['cashPayments'] ?? 0,
      nonCashPayments: map['nonCashPayments'] ?? 0,
      vatByRate: vatByRate,
    );
  }

  // Chuyển đổi thành Map
  Map<String, dynamic> toMap() {
    Map<String, dynamic> vatByRateMap = {};
    vatByRate.forEach((key, value) {
      vatByRateMap[key!.index.toString()] = value;
    });

    return {
      'totalRevenue': totalRevenue,
      'totalSalesAmount': totalSalesAmount,
      'totalVATAmount': totalVATAmount,
      'totalInvoices': totalInvoices,
      'electronicInvoices': electronicInvoices,
      'cashPayments': cashPayments,
      'nonCashPayments': nonCashPayments,
      'vatByRate': vatByRateMap,
    };
  }
}

// Helper class cho khoảng thời gian
class DateTimeRange {
  final DateTime start;
  final DateTime end;

  DateTimeRange({required this.start, required this.end});
}

// Extension cho ReportPeriod
extension ReportPeriodExtension on ReportPeriod {
  String get displayName {
    switch (this) {
      case ReportPeriod.monthly:
        return 'Tháng';
      case ReportPeriod.quarterly:
        return 'Quý';
      case ReportPeriod.yearly:
        return 'Năm';
    }
  }
} 