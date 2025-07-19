import 'package:flutter/material.dart';
import '../models/models.dart' hide VATRate;
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../constants/tax_rates.dart';
import '../utils/format_utils.dart';
import '../services/business_user_service.dart';
import '../services/storage_service.dart';

class ReportScreen extends StatefulWidget {
  final List<FinanceRecord> records;

  const ReportScreen({super.key, required this.records});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _selectedReportType = 'thang';
  int _selectedMonth = DateTime.now().month;
  int _selectedQuarter = ((DateTime.now().month - 1) ~/ 3) + 1;
  int _selectedYear = DateTime.now().year;
  
  BusinessUser? _businessUser;
  TaxCalculationResult? _taxCalculation;
  bool _showTaxCalculation = false; // Toggle để hiển thị/ẩn tính toán thuế

  @override
  void initState() {
    super.initState();
    _loadBusinessUser();
  }

  Future<void> _loadBusinessUser() async {
    try {
      final user = await StorageService.getBusinessUser();
      if (user != null) {
        setState(() {
          _businessUser = user;
        });
      }
    } catch (e) {
      print('Error loading business user: $e');
    }
  }

  void _updateTaxCalculation() {
    if (_businessUser == null || !_showTaxCalculation) return;

    final report = _generateReport();
    
    // Tính doanh thu trung bình tháng dựa trên loại báo cáo
    double monthlyRevenue;
    switch (_selectedReportType) {
      case 'thang':
        // Doanh thu tháng này
        monthlyRevenue = report.totalRevenue;
        break;
      case 'quy':
        // Doanh thu trung bình tháng trong quý
        monthlyRevenue = report.totalRevenue / 3;
        break;
      case 'nam':
        // Doanh thu trung bình tháng trong năm
        monthlyRevenue = report.totalRevenue / 12;
        break;
      default:
        monthlyRevenue = report.totalRevenue;
    }

    // Tính doanh thu năm thực tế từ tất cả records trong năm
    final actualAnnualRevenue = _calculateActualAnnualRevenue();

    final taxCalc = _calculateTaxWithActualAnnualRevenue(monthlyRevenue, actualAnnualRevenue);
    setState(() {
      _taxCalculation = taxCalc;
    });
  }

  double _calculateActualAnnualRevenue() {
    // Lấy tất cả records trong năm hiện tại
    final currentYear = _selectedYear;
    final yearRecords = widget.records.where((record) {
      return record.ngayTao.year == currentYear;
    }).toList();

    // Tính tổng doanh thu thực tế trong năm
    return yearRecords.fold(0.0, (sum, record) => sum + record.doanhThu);
  }

  TaxCalculationResult _calculateTaxWithActualAnnualRevenue(double monthlyRevenue, double actualAnnualRevenue) {
    // Kiểm tra miễn thuế VAT
    final isVATExempt = TaxHelper.isVATExempt(actualAnnualRevenue);
    
    // Tính thuế VAT dựa trên doanh thu tháng
    double vatAmount = 0.0;
    VATRate vatRate = VATRate.exempt;
    
    if (!isVATExempt) {
      vatRate = TaxHelper.getCurrentVATRate(_businessUser!.businessSector);
      final vatPercentage = TaxHelper.getVATPercentage(vatRate);
      vatAmount = monthlyRevenue * vatPercentage / 100;
    }

    // Tính thuế TNCN dựa trên doanh thu tháng
    final personalIncomeTaxRate = _businessUser!.businessSector.personalIncomeTaxRate / 100;
    final personalIncomeTaxAmount = monthlyRevenue * personalIncomeTaxRate;

    // Tính thuế môn bài dựa trên doanh thu năm thực tế
    double businessLicenseTaxAmount = 0.0;
    if (actualAnnualRevenue > 0) {
      final annualBusinessLicenseTax = TaxHelper.calculateBusinessLicenseTax(actualAnnualRevenue);
      
      // Chia thuế môn bài theo kỳ báo cáo
      switch (_selectedReportType) {
        case 'thang':
          businessLicenseTaxAmount = annualBusinessLicenseTax / 12; // Thuế môn bài 1 tháng
          break;
        case 'quy':
          businessLicenseTaxAmount = annualBusinessLicenseTax / 4; // Thuế môn bài 1 quý
          break;
        case 'nam':
          businessLicenseTaxAmount = annualBusinessLicenseTax; // Thuế môn bài cả năm
          break;
        default:
          businessLicenseTaxAmount = annualBusinessLicenseTax / 12;
      }
    }

    // Tổng thuế
    final totalTaxAmount = vatAmount + personalIncomeTaxAmount + businessLicenseTaxAmount;

    // Tạo ghi chú
    String notes = '';
    if (isVATExempt) {
      final thresholdFormatted = TaxHelper.formatCurrency(TaxRates.VAT_EXEMPTION_THRESHOLD);
      notes = 'Miễn thuế VAT do doanh thu năm ${TaxHelper.formatCurrency(actualAnnualRevenue)} < $thresholdFormatted. ';
    }
    if (_businessUser!.isEcommerceTrading) {
      notes += 'Kinh doanh TMĐT: Kiểm tra chính sách khấu trừ thuế của sàn. ';
    }
    if (actualAnnualRevenue >= 1000000000) {
      notes += 'Doanh thu ≥ 1 tỷ: Bắt buộc sử dụng hóa đơn điện tử từ 1/6/2025. ';
    }
    if (actualAnnualRevenue < 100000000) {
      notes += 'Miễn thuế môn bài do doanh thu năm < 100 triệu. ';
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

  Report _generateReport() {
    List<FinanceRecord> filteredRecords = [];

    switch (_selectedReportType) {
      case 'thang':
        filteredRecords = widget.records.where((record) {
          return record.ngayTao.month == _selectedMonth &&
              record.ngayTao.year == _selectedYear;
        }).toList();
        break;
      case 'quy':
        int startMonth = (_selectedQuarter - 1) * 3 + 1;
        int endMonth = _selectedQuarter * 3;
        filteredRecords = widget.records.where((record) {
          return record.ngayTao.month >= startMonth &&
              record.ngayTao.month <= endMonth &&
              record.ngayTao.year == _selectedYear;
        }).toList();
        break;
      case 'nam':
        filteredRecords = widget.records.where((record) {
          return record.ngayTao.year == _selectedYear;
        }).toList();
        break;
    }

    double totalRevenue = filteredRecords.fold(0, (sum, record) => sum + record.doanhThu);
    double totalCost = filteredRecords.fold(0, (sum, record) => sum + record.chiPhi);
    double totalProfit = totalRevenue - totalCost;

    return Report(
      totalRevenue: totalRevenue,
      totalCost: totalCost,
      totalProfit: totalProfit,
      typeReport: _selectedReportType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = _generateReport();
    final hasData = widget.records.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.bar_chart, size: 24),
            SizedBox(width: AppStyles.spacingS),
            Text('Báo Cáo Tài Chính'),
          ],
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundLight,
              AppColors.backgroundWhite,
            ],
          ),
        ),
        child: hasData ? _buildReportContent(report) : _buildEmptyState(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppStyles.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppStyles.spacingXL),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bar_chart,
                size: 64,
                color: AppColors.info,
              ),
            ),
            const SizedBox(height: AppStyles.spacingL),
            Text(
              'Chưa có dữ liệu báo cáo',
              style: AppStyles.headingMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppStyles.spacingM),
            Container(
              padding: const EdgeInsets.all(AppStyles.spacingL),
              decoration: AppStyles.cardDecoration,
              child: Column(
                children: [
                  Text(
                    'Để xem báo cáo tài chính, bạn cần:',
                    style: AppStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppStyles.spacingM),
                  _buildEmptyStateItem(
                    Icons.add_circle,
                    'Nhập dữ liệu tài chính',
                    'Thêm thông tin doanh thu và chi phí',
                  ),
                  const SizedBox(height: AppStyles.spacingS),
                  _buildEmptyStateItem(
                    Icons.smart_toy,
                    'Sử dụng AI Chat',
                    'Nói với AI về giao dịch của bạn',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppStyles.spacingS),
                       decoration: BoxDecoration(
               color: AppColors.mainColor.withOpacity(0.1),
               borderRadius: BorderRadius.circular(AppStyles.radiusS),
             ),
             child: Icon(icon, color: AppColors.mainColor, size: 20),
        ),
        const SizedBox(width: AppStyles.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
              Text(description, style: AppStyles.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportContent(Report report) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppStyles.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Card
          Container(
            decoration: AppStyles.cardDecoration,
            padding: const EdgeInsets.all(AppStyles.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppStyles.spacingS),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppStyles.radiusS),
                      ),
                      child: const Icon(
                        Icons.filter_list,
                        color: AppColors.info,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppStyles.spacingS),
                    Text(
                      'Bộ lọc báo cáo',
                      style: AppStyles.headingSmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppStyles.spacingL),
                _buildReportTypeSelector(),
                const SizedBox(height: AppStyles.spacingM),
                _buildPeriodSelector(),
                
                // Tax Toggle Button
                if (_businessUser != null) ...[
                  const SizedBox(height: AppStyles.spacingL),
                  _buildTaxToggleButton(),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppStyles.spacingL),

          // Report Title
          Container(
            decoration: AppStyles.elevatedCardDecoration,
            padding: const EdgeInsets.all(AppStyles.spacingL),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppStyles.spacingM),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppStyles.radiusM),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: AppColors.textOnPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppStyles.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getReportTitle(),
                        style: AppStyles.headingMedium,
                      ),
                      const SizedBox(height: AppStyles.spacingXS),
                      Text(
                        'Tổng hợp dữ liệu tài chính',
                        style: AppStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppStyles.spacingL),

          // Report Cards
          Row(
            children: [
              Expanded(
                child: _buildReportCard(
                  'Doanh Thu',
                  report.totalRevenue,
                  AppColors.success,
                  Icons.trending_up,
                  'VNĐ',
                ),
              ),
              const SizedBox(width: AppStyles.spacingM),
              Expanded(
                child: _buildReportCard(
                  'Chi Phí',
                  report.totalCost,
                  AppColors.error,
                  Icons.trending_down,
                  'VNĐ',
                ),
              ),
            ],
          ),

          const SizedBox(height: AppStyles.spacingM),

          // Profit Card
          _buildProfitCard(report),

          const SizedBox(height: AppStyles.spacingL),

          // Tax Calculation Card
          if (_showTaxCalculation && _businessUser != null && _taxCalculation != null && report.totalRevenue > 0) ...[
            _buildTaxCalculationCard(_taxCalculation!, _calculateActualAnnualRevenue()),
            const SizedBox(height: AppStyles.spacingL),
          ],

          // Summary Card
          if (report.totalRevenue > 0) _buildSummaryCard(report),
        ],
      ),
    );
  }

  Widget _buildReportTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppStyles.radiusM),
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppStyles.spacingM),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedReportType,
          onChanged: (value) {
            setState(() {
              _selectedReportType = value!;
            });
            _updateTaxCalculation();
          },
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.mainColor),
          style: AppStyles.bodyLarge,
          items: const [
            DropdownMenuItem(
              value: 'thang',
              child: Row(
                children: [
                  Icon(Icons.calendar_view_month, color: AppColors.mainColor, size: 20),
                  SizedBox(width: AppStyles.spacingS),
                  Text('Báo cáo theo tháng'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'quy',
              child: Row(
                children: [
                  Icon(Icons.calendar_view_week, color: AppColors.mainColor, size: 20),
                  SizedBox(width: AppStyles.spacingS),
                  Text('Báo cáo theo quý'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'nam',
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: AppColors.mainColor, size: 20),
                  SizedBox(width: AppStyles.spacingS),
                  Text('Báo cáo theo năm'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Wrap(
      spacing: AppStyles.spacingM,
      runSpacing: AppStyles.spacingS,
      children: [
        if (_selectedReportType == 'thang') ...[
          _buildDropdownContainer(
            'Tháng',
            _selectedMonth,
            List.generate(12, (index) => index + 1),
            (value) => setState(() => _selectedMonth = value),
            (value) => 'Tháng $value',
          ),
          _buildDropdownContainer(
            'Năm',
            _selectedYear,
            List.generate(5, (index) => DateTime.now().year - index),
            (value) => setState(() => _selectedYear = value),
            (value) => '$value',
          ),
        ],
        if (_selectedReportType == 'quy') ...[
          _buildDropdownContainer(
            'Quý',
            _selectedQuarter,
            [1, 2, 3, 4],
            (value) => setState(() => _selectedQuarter = value),
            (value) => 'Quý $value',
          ),
          _buildDropdownContainer(
            'Năm',
            _selectedYear,
            List.generate(5, (index) => DateTime.now().year - index),
            (value) => setState(() => _selectedYear = value),
            (value) => '$value',
          ),
        ],
        if (_selectedReportType == 'nam')
          _buildDropdownContainer(
            'Năm',
            _selectedYear,
            List.generate(5, (index) => DateTime.now().year - index),
            (value) => setState(() => _selectedYear = value),
            (value) => '$value',
          ),
      ],
    );
  }

  Widget _buildDropdownContainer(
    String label,
    int value,
    List<int> items,
    Function(int) onChanged,
    String Function(int) itemBuilder,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppStyles.radiusS),
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppStyles.spacingM, vertical: AppStyles.spacingXS),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: AppStyles.bodyMedium),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              onChanged: (newValue) {
                onChanged(newValue!);
                _updateTaxCalculation();
              },
              style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.mainColor, size: 20),
              items: items.map((item) {
                return DropdownMenuItem<int>(
                  value: item,
                  child: Text(itemBuilder(item)),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, double value, Color color, IconData icon, String unit) {
    return Container(
      decoration: AppStyles.cardDecoration,
      padding: const EdgeInsets.all(AppStyles.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppStyles.spacingS),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radiusS),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppStyles.spacingS),
              Expanded(
                child: Text(
                  title,
                  style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spacingM),
          Text(
            FormatUtils.formatCurrency(value),
            style: AppStyles.headingSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            unit,
            style: AppStyles.bodySmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitCard(Report report) {
    final isProfit = report.totalProfit >= 0;
    final color = isProfit ? AppColors.success : AppColors.error;
    final icon = isProfit ? Icons.arrow_upward : Icons.arrow_downward;

    return Container(
      decoration: AppStyles.elevatedCardDecoration,
      padding: const EdgeInsets.all(AppStyles.spacingL),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppStyles.spacingM),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppStyles.radiusM),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: AppStyles.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isProfit ? 'Lợi Nhuận' : 'Thua Lỗ',
                  style: AppStyles.headingSmall,
                ),
                const SizedBox(height: AppStyles.spacingXS),
                                    Text(
                      '${FormatUtils.formatCurrency(report.totalProfit)} VNĐ',
                      style: AppStyles.headingMedium.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Report report) {
    final profitMargin = (report.totalProfit / report.totalRevenue * 100);
    
    return Container(
      decoration: AppStyles.cardDecoration,
      padding: const EdgeInsets.all(AppStyles.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppStyles.spacingS),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radiusS),
                ),
                child: const Icon(
                  Icons.insights,
                  color: AppColors.info,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppStyles.spacingS),
              Text(
                'Phân tích chi tiết',
                style: AppStyles.headingSmall,
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spacingL),
          _buildSummaryRow(
            'Tỷ lệ lợi nhuận',
            '${profitMargin.toStringAsFixed(2)}%',
            profitMargin >= 0 ? AppColors.success : AppColors.error,
          ),
          const SizedBox(height: AppStyles.spacingS),
          _buildSummaryRow(
            'Tỷ lệ chi phí',
            '${(report.totalCost / report.totalRevenue * 100).toStringAsFixed(2)}%',
            AppColors.warning,
          ),
          const SizedBox(height: AppStyles.spacingS),
          _buildSummaryRow(
            'Số giao dịch',
            '${widget.records.length}',
            AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppStyles.bodyMedium),
        Text(
          value,
          style: AppStyles.bodyLarge.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTaxToggleButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppStyles.radiusM),
        border: Border.all(
          color: _showTaxCalculation ? AppColors.mainColor : AppColors.borderLight,
          width: _showTaxCalculation ? 2 : 1,
        ),
      ),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(
              Icons.account_balance,
              color: _showTaxCalculation ? AppColors.mainColor : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: AppStyles.spacingS),
            Text(
              'Hiển thị tính toán thuế',
              style: AppStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: _showTaxCalculation ? AppColors.mainColor : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        subtitle: Text(
          'Tính thuế dựa trên doanh thu thực tế',
          style: AppStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        value: _showTaxCalculation,
        onChanged: (value) {
          setState(() {
            _showTaxCalculation = value;
          });
          if (value) {
            _updateTaxCalculation();
          }
        },
        activeColor: AppColors.mainColor,
      ),
    );
  }

  Widget _buildTaxCalculationCard(TaxCalculationResult taxCalculation, double actualAnnualRevenue) {
    return Container(
      decoration: AppStyles.elevatedCardDecoration,
      padding: const EdgeInsets.all(AppStyles.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppStyles.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radiusM),
                ),
                child: const Icon(
                  Icons.account_balance,
                  color: AppColors.warning,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppStyles.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thuế phải nộp',
                      style: AppStyles.headingMedium,
                    ),
                    const SizedBox(height: AppStyles.spacingXS),
                    Text(
                      '${_getReportPeriodText()} (Dựa trên doanh thu thực tế)',
                      style: AppStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spacingL),

          // Business Info
          if (_businessUser != null) ...[
            Container(
              padding: const EdgeInsets.all(AppStyles.spacingM),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppStyles.radiusS),
              ),
              child: Row(
                children: [
                  const Icon(Icons.business, color: AppColors.info, size: 20),
                  const SizedBox(width: AppStyles.spacingS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _businessUser!.businessName,
                          style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _getSectorDisplayName(_businessUser!.businessSector),
                          style: AppStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppStyles.spacingM),
          ],

          // Tax Breakdown
          if (taxCalculation.isVATExempt)
            _buildTaxRow(
              'Thuế VAT',
              'MIỄN THUẾ',
              AppColors.success,
              'Doanh thu < 200 triệu/năm',
              Icons.check_circle,
            )
          else
            _buildTaxRow(
              'Thuế VAT (${_getVATRateText(taxCalculation.vatRate)})',
              FormatUtils.formatCurrency(taxCalculation.vatAmount),
              AppColors.warning,
              null,
              Icons.receipt,
            ),

          const SizedBox(height: AppStyles.spacingS),
          _buildTaxRow(
            'Thuế TNCN (${(taxCalculation.personalIncomeTaxRate * 100).toStringAsFixed(1)}%)',
            FormatUtils.formatCurrency(taxCalculation.personalIncomeTaxAmount),
            AppColors.info,
            'Theo ngành nghề kinh doanh',
            Icons.person,
          ),

          const SizedBox(height: AppStyles.spacingS),
          _buildTaxRow(
            'Thuế Môn bài',
            FormatUtils.formatCurrency(taxCalculation.businessLicenseTaxAmount),
            AppColors.mainColor,
            _getBusinessLicenseTaxNote(actualAnnualRevenue, _selectedReportType),
            Icons.business_center,
          ),

          const Divider(thickness: 2),
          _buildTaxRow(
            'Tổng thuế',
            FormatUtils.formatCurrency(taxCalculation.totalTaxAmount),
            AppColors.error,
            null,
            Icons.account_balance_wallet,
            isTotal: true,
          ),

          // Tax Notes
          if (taxCalculation.notes.isNotEmpty) ...[
            const SizedBox(height: AppStyles.spacingM),
            Container(
              padding: const EdgeInsets.all(AppStyles.spacingM),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppStyles.radiusS),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.warning, size: 16),
                  const SizedBox(width: AppStyles.spacingS),
                  Expanded(
                    child: Text(
                      taxCalculation.notes,
                      style: AppStyles.bodySmall.copyWith(color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Tax Recommendations
          if (_businessUser != null) ...[
            const SizedBox(height: AppStyles.spacingM),
            _buildTaxRecommendations(),
          ],
        ],
      ),
    );
  }

  Widget _buildTaxRow(
    String label,
    String value,
    Color color,
    String? subtitle,
    IconData icon, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: isTotal ? AppStyles.spacingS : AppStyles.spacingXS,
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppStyles.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: isTotal
                      ? AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)
                      : AppStyles.bodyMedium,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppStyles.spacingXS / 2),
                  Text(
                    subtitle,
                    style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          Text(
            value,
            style: (isTotal ? AppStyles.headingSmall : AppStyles.bodyLarge).copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxRecommendations() {
    final actualTotalIncome = _calculateActualAnnualRevenue();
    final recommendations = BusinessUserService.getTaxRecommendations(_businessUser!, actualTotalIncome);
    
    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppStyles.spacingM),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppStyles.radiusS),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: AppColors.info, size: 16),
              const SizedBox(width: AppStyles.spacingS),
              Text(
                'Gợi ý thuế',
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spacingS),
          ...recommendations.map((recommendation) => Padding(
            padding: const EdgeInsets.only(bottom: AppStyles.spacingXS),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.arrow_right, color: AppColors.info, size: 16),
                const SizedBox(width: AppStyles.spacingXS),
                Expanded(
                  child: Text(
                    recommendation,
                    style: AppStyles.bodySmall.copyWith(color: AppColors.info),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  String _getSectorDisplayName(BusinessSector sector) {
    switch (sector) {
      case BusinessSector.agriculture:
        return 'Nông nghiệp - Trồng trọt, chăn nuôi';
      case BusinessSector.aquaculture:
        return 'Thủy sản - Nuôi trồng thủy sản';
      case BusinessSector.forestry:
        return 'Lâm nghiệp - Rừng trồng';
      case BusinessSector.manufacturing:
        return 'Sản xuất - Chế biến';
      case BusinessSector.construction:
        return 'Xây dựng';
      case BusinessSector.trading:
        return 'Thương mại - Mua bán hàng hóa';
      case BusinessSector.agency:
        return 'Đại lý - Môi giới';
      case BusinessSector.transport:
        return 'Vận tải';
      case BusinessSector.restaurant:
        return 'Dịch vụ ăn uống';
      case BusinessSector.accommodation:
        return 'Lưu trú - Khách sạn, nhà nghỉ';
      case BusinessSector.entertainment:
        return 'Giải trí - Karaoke, massage';
      case BusinessSector.rental:
        return 'Cho thuê tài sản';
      case BusinessSector.other:
        return 'Ngành nghề khác';
    }
  }

  String _getVATRateText(VATRate rate) {
    switch (rate) {
      case VATRate.zero:
        return '0%';
      case VATRate.five:
        return '5%';
      case VATRate.eight:
        return '8%';
      case VATRate.ten:
        return '10%';
      case VATRate.exempt:
        return 'Miễn thuế';
    }
  }

  String _getReportPeriodText() {
    switch (_selectedReportType) {
      case 'thang':
        return 'Tháng $_selectedMonth/$_selectedYear';
      case 'quy':
        return 'Quý $_selectedQuarter/$_selectedYear';
      case 'nam':
        return 'Năm $_selectedYear';
      default:
        return 'Kỳ báo cáo';
    }
  }

  String _getBusinessLicenseTaxNote(double actualAnnualRevenue, String reportType) {
    String period = '';
    switch (reportType) {
      case 'thang':
        period = '/tháng';
        break;
      case 'quy':
        period = '/quý';
        break;
      case 'nam':
        period = '/năm';
        break;
    }

    if (actualAnnualRevenue < 100000000) {
      return 'Miễn thuế (DT năm: ${TaxHelper.formatCurrency(actualAnnualRevenue)} < 100 triệu)';
    } else if (actualAnnualRevenue < 300000000) {
      return 'DT năm: ${TaxHelper.formatCurrency(actualAnnualRevenue)} → 300k/năm${period}';
    } else if (actualAnnualRevenue < 500000000) {
      return 'DT năm: ${TaxHelper.formatCurrency(actualAnnualRevenue)} → 500k/năm${period}';
    } else {
      return 'DT năm: ${TaxHelper.formatCurrency(actualAnnualRevenue)} → 1 triệu/năm${period}';
    }
  }

  String _getReportTitle() {
    switch (_selectedReportType) {
      case 'thang':
        return 'Báo cáo tháng $_selectedMonth/$_selectedYear';
      case 'quy':
        return 'Báo cáo quý $_selectedQuarter/$_selectedYear';
      case 'nam':
        return 'Báo cáo năm $_selectedYear';
      default:
        return 'Báo cáo tài chính';
    }
  }
} 