import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../models/report.dart';
import '../services/order_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../utils/format_utils.dart';
import '../main.dart'; // Import để sử dụng CommonScreenMixin

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> with CommonScreenMixin {
  String _selectedReportType = 'thang';
  int _selectedMonth = DateTime.now().month;
  int _selectedQuarter = ((DateTime.now().month - 1) ~/ 3) + 1;
  int _selectedYear = DateTime.now().year;
  
  final OrderService _orderService = OrderService();
  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    
    try {
      final orders = await _orderService.getOrders();
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải dữ liệu: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Report _generateReport() {
    List<Order> filteredOrders = [];

    switch (_selectedReportType) {
      case 'thang':
        filteredOrders = _orders.where((order) {
          return order.orderDate.month == _selectedMonth &&
              order.orderDate.year == _selectedYear;
        }).toList();
        break;
      case 'quy':
        int startMonth = (_selectedQuarter - 1) * 3 + 1;
        int endMonth = _selectedQuarter * 3;
        filteredOrders = _orders.where((order) {
          return order.orderDate.month >= startMonth &&
              order.orderDate.month <= endMonth &&
              order.orderDate.year == _selectedYear;
        }).toList();
        break;
      case 'nam':
        filteredOrders = _orders.where((order) {
          return order.orderDate.year == _selectedYear;
        }).toList();
        break;
    }

    double totalRevenue = filteredOrders.fold(0, (sum, order) {
      double orderTotal = order.items.fold(0, (itemSum, item) => itemSum + (item.unitPrice * item.quantity));
      return sum + orderTotal;
    });
    
    double totalCost = filteredOrders.fold(0, (sum, order) {
      double orderCost = order.items.fold(0, (itemSum, item) => itemSum + (item.costPrice * item.quantity));
      return sum + orderCost;
    });
    
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
    final hasData = _orders.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.bar_chart, size: 24),
            SizedBox(width: AppStyles.spacingS),
            Text('Báo Cáo Đơn Hàng'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
            tooltip: 'Làm mới dữ liệu',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'shop_info':
                  showShopInfo();
                  break;
                case 'logout':
                  logout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'shop_info',
                child: Row(
                  children: [
                    Icon(Icons.store),
                    SizedBox(width: AppStyles.spacingS),
                    Text('Thông tin cửa hàng'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppColors.errorColor),
                    SizedBox(width: AppStyles.spacingS),
                    Text('Đăng xuất', style: TextStyle(color: AppColors.errorColor)),
                  ],
                ),
              ),
            ],
          ),
        ],
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
        child: _isLoading ? _buildLoadingState() : (hasData ? _buildReportContent(report) : _buildEmptyState()),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primaryBlue),
          const SizedBox(height: AppStyles.spacingM),
          Text('Đang tải dữ liệu báo cáo...', style: AppStyles.bodyLarge),
        ],
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
                    Icons.receipt_long,
                    'Tạo đơn hàng',
                    'Tạo đơn hàng với sản phẩm và giá cả',
                  ),
                  const SizedBox(height: AppStyles.spacingS),
                  _buildEmptyStateItem(
                    Icons.inventory,
                    'Quản lý sản phẩm',
                    'Thêm sản phẩm với giá vốn và giá bán',
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
              onChanged: (newValue) => onChanged(newValue!),
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
            'Số đơn hàng',
            '${_orders.length}',
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