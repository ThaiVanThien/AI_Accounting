import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/finance_record.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../utils/format_utils.dart';

class RecordListScreen extends StatefulWidget {
  final List<FinanceRecord> records;
  final Function(int)? onDeleteRecord;
  final Function(FinanceRecord)? onUpdateRecord;

  const RecordListScreen({
    super.key, 
    required this.records,
    this.onDeleteRecord,
    this.onUpdateRecord,
  });

  @override
  State<RecordListScreen> createState() => _RecordListScreenState();
}

class _RecordListScreenState extends State<RecordListScreen> {
  String _sortBy = 'date'; // 'date', 'revenue', 'cost', 'profit'
  bool _isAscending = false;
  String _filterBy = 'all'; // 'all', 'profit', 'loss'

  List<FinanceRecord> get _filteredAndSortedRecords {
    List<FinanceRecord> filtered = List.from(widget.records);

    // Filter
    switch (_filterBy) {
      case 'profit':
        filtered = filtered.where((record) => record.loiNhuan >= 0).toList();
        break;
      case 'loss':
        filtered = filtered.where((record) => record.loiNhuan < 0).toList();
        break;
    }

    // Sort
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'date':
          comparison = a.ngayTao.compareTo(b.ngayTao);
          break;
        case 'revenue':
          comparison = a.doanhThu.compareTo(b.doanhThu);
          break;
        case 'cost':
          comparison = a.chiPhi.compareTo(b.chiPhi);
          break;
        case 'profit':
          comparison = a.loiNhuan.compareTo(b.loiNhuan);
          break;
      }
      return _isAscending ? comparison : -comparison;
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredRecords = _filteredAndSortedRecords;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.list_alt, size: 24),
            SizedBox(width: AppStyles.spacingS),
            Text('Danh Sách Giao Dịch'),
          ],
        ),
        backgroundColor: AppColors.mainColor,
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
        child: widget.records.isEmpty
            ? _buildEmptyState()
            : Column(
                children: [
                  _buildSummaryHeader(),
                  _buildFilterChips(),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(AppStyles.spacingM),
                      itemCount: filteredRecords.length,
                      itemBuilder: (context, index) {
                        final record = filteredRecords[index];
                        return _buildRecordCard(record, index);
                      },
                    ),
                  ),
                ],
              ),
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
                Icons.receipt_long,
                size: 64,
                color: AppColors.info,
              ),
            ),
            const SizedBox(height: AppStyles.spacingL),
            Text(
              'Chưa có giao dịch nào',
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
                    'Bắt đầu theo dõi tài chính của bạn:',
                    style: AppStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppStyles.spacingM),
                  _buildEmptyStateItem(
                    Icons.add_circle,
                    'Nhập dữ liệu thủ công',
                    'Thêm giao dịch qua form nhập liệu',
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

  Widget _buildSummaryHeader() {
    final totalRevenue = widget.records.fold(0.0, (sum, record) => sum + record.doanhThu);
    final totalCost = widget.records.fold(0.0, (sum, record) => sum + record.chiPhi);
    final totalProfit = totalRevenue - totalCost;

    return Container(
      margin: const EdgeInsets.all(AppStyles.spacingM),
      decoration: AppStyles.elevatedCardDecoration,
      padding: const EdgeInsets.all(AppStyles.spacingL),
      child: Column(
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
                  Icons.analytics,
                  color: AppColors.info,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppStyles.spacingS),
              Text(
                'Tổng quan ${widget.records.length} giao dịch',
                style: AppStyles.headingSmall,
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spacingL),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Doanh thu',
                  totalRevenue,
                  AppColors.success,
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: AppStyles.spacingM),
              Expanded(
                child: _buildSummaryItem(
                  'Chi phí',
                  totalCost,
                  AppColors.error,
                  Icons.trending_down,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spacingM),
          _buildSummaryItem(
            totalProfit >= 0 ? 'Lợi nhuận' : 'Thua lỗ',
            totalProfit,
            totalProfit >= 0 ? AppColors.success : AppColors.error,
            totalProfit >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, double value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppStyles.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppStyles.radiusM),
        border: Border.all(color: color.withOpacity(0.3)),
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
                  title,
                  style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${FormatUtils.formatCurrency(value)} VNĐ',
                  style: AppStyles.bodyLarge.copyWith(
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

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppStyles.spacingM),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              'Tất cả',
              _filterBy == 'all',
              () => setState(() => _filterBy = 'all'),
              AppColors.info,
            ),
            const SizedBox(width: AppStyles.spacingS),
            _buildFilterChip(
              'Lợi nhuận',
              _filterBy == 'profit',
              () => setState(() => _filterBy = 'profit'),
              AppColors.success,
            ),
            const SizedBox(width: AppStyles.spacingS),
            _buildFilterChip(
              'Thua lỗ',
              _filterBy == 'loss',
              () => setState(() => _filterBy = 'loss'),
              AppColors.error,
            ),
            const SizedBox(width: AppStyles.spacingM),
            Container(
              width: 1,
              height: 32,
              color: AppColors.borderLight,
            ),
            const SizedBox(width: AppStyles.spacingM),
            _buildSortChip(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyles.spacingM,
          vertical: AppStyles.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(AppStyles.radiusL),
          border: Border.all(
            color: isSelected ? color : AppColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: AppStyles.bodyMedium.copyWith(
            color: isSelected ? AppColors.textOnPrimary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSortChip() {
    return GestureDetector(
      onTap: _showSortDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyles.spacingM,
          vertical: AppStyles.spacingS,
        ),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(AppStyles.radiusL),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
                                       color: AppColors.mainColor,
            ),
            const SizedBox(width: AppStyles.spacingXS),
            Text(
              _getSortLabel(),
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(FinanceRecord record, int index) {
    final isProfit = record.loiNhuan >= 0;
    final profitColor = isProfit ? AppColors.success : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: AppStyles.spacingM),
      decoration: AppStyles.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppStyles.radiusL),
          onTap: () => _showRecordDetails(record),
          child: Padding(
            padding: const EdgeInsets.all(AppStyles.spacingL),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppStyles.spacingS),
                      decoration: BoxDecoration(
                        color: profitColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppStyles.radiusS),
                      ),
                      child: Icon(
                        isProfit ? Icons.trending_up : Icons.trending_down,
                        color: profitColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppStyles.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            FormatUtils.formatDate(record.ngayTao),
                            style: AppStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (record.ghiChu.isNotEmpty) ...[
                            const SizedBox(height: AppStyles.spacingXS),
                            Text(
                              record.ghiChu,
                              style: AppStyles.bodyMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${FormatUtils.formatCurrency(record.loiNhuan)} VNĐ',
                          style: AppStyles.bodyLarge.copyWith(
                            color: profitColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isProfit ? 'Lợi nhuận' : 'Thua lỗ',
                          style: AppStyles.bodySmall.copyWith(
                            color: profitColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppStyles.spacingM),
                Row(
                  children: [
                    Expanded(
                      child: _buildRecordDetail(
                        'Doanh thu',
                        record.doanhThu,
                        AppColors.success,
                        Icons.add_circle_outline,
                      ),
                    ),
                    const SizedBox(width: AppStyles.spacingM),
                    Expanded(
                      child: _buildRecordDetail(
                        'Chi phí',
                        record.chiPhi,
                        AppColors.error,
                        Icons.remove_circle_outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordDetail(String title, double value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppStyles.spacingS),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppStyles.radiusS),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: AppStyles.spacingXS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppStyles.bodySmall.copyWith(color: color),
                ),
                Text(
                  FormatUtils.formatCurrency(value),
                  style: AppStyles.bodyMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppStyles.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sắp xếp theo',
              style: AppStyles.headingSmall,
            ),
            const SizedBox(height: AppStyles.spacingL),
            ...['date', 'revenue', 'cost', 'profit'].map((sort) {
              return ListTile(
                title: Text(_getSortLabelForType(sort)),
                trailing: _sortBy == sort
                    ? Icon(
                        _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        color: AppColors.mainColor,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    if (_sortBy == sort) {
                      _isAscending = !_isAscending;
                    } else {
                      _sortBy = sort;
                      _isAscending = false;
                    }
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _showRecordDetails(FinanceRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết giao dịch'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Ngày', FormatUtils.formatDate(record.ngayTao)),
            _buildDetailRow('Doanh thu', '${FormatUtils.formatCurrency(record.doanhThu)} VNĐ'),
            _buildDetailRow('Chi phí', '${FormatUtils.formatCurrency(record.chiPhi)} VNĐ'),
            _buildDetailRow('Lợi nhuận', '${FormatUtils.formatCurrency(record.loiNhuan)} VNĐ'),
            if (record.ghiChu.isNotEmpty)
              _buildDetailRow('Ghi chú', record.ghiChu),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppStyles.spacingXS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _getSortLabel() {
    return _getSortLabelForType(_sortBy);
  }

  String _getSortLabelForType(String type) {
    switch (type) {
      case 'date':
        return 'Ngày';
      case 'revenue':
        return 'Doanh thu';
      case 'cost':
        return 'Chi phí';
      case 'profit':
        return 'Lợi nhuận';
      default:
        return 'Ngày';
    }
  }
} 