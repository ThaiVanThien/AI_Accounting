import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../services/storage_manager.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../utils/format_utils.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  final AIService _aiService = AIService();
  final StorageManager _storageManager = StorageManager();
  List<ChatMessage> _messages = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  String _selectedFilter = 'all'; // 'all', 'entry', 'report', 'search', 'error'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final messages = await _aiService.getChatHistory();
      final chatStats = await _aiService.getChatStatistics();
      final storageStats = await _storageManager.getStatistics();

      setState(() {
        _messages = messages;
        _statistics = {
          ...chatStats,
          ...storageStats,
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading chat history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<ChatMessage> get _filteredMessages {
    if (_selectedFilter == 'all') return _messages;
    return _messages.where((msg) => msg.type == _selectedFilter).toList();
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn xóa toàn bộ lịch sử chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _aiService.clearChatHistory();
      await _loadData();
    }
  }

  Future<void> _exportData() async {
    try {
      final data = await _storageManager.exportData();
      // Hiển thị dialog với JSON data
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xuất dữ liệu'),
          content: SingleChildScrollView(
            child: SelectableText(
              const JsonEncoder.withIndent('  ').convert(data),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi xuất dữ liệu: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Widget _buildStatisticsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: AppColors.mainColor),
                const SizedBox(width: AppStyles.spacingS),
                Text(
                  'Thống kê',
                  style: AppStyles.headingSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppStyles.spacingM),
            _buildStatItem('Tổng tin nhắn', '${_statistics['totalMessages'] ?? 0}'),
            _buildStatItem('Tin nhắn người dùng', '${_statistics['userMessages'] ?? 0}'),
            _buildStatItem('Tin nhắn AI', '${_statistics['aiMessages'] ?? 0}'),
            const Divider(),
            _buildStatItem('Nhập liệu', '${_statistics['entryMessages'] ?? 0}'),
            _buildStatItem('Báo cáo', '${_statistics['reportMessages'] ?? 0}'),
            _buildStatItem('Tìm kiếm', '${_statistics['searchMessages'] ?? 0}'),
            _buildStatItem('Lỗi', '${_statistics['errorMessages'] ?? 0}'),
            const Divider(),
            _buildStatItem('Tổng giao dịch', '${_statistics['totalRecords'] ?? 0}'),
            _buildStatItem('Tổng doanh thu', 
              FormatUtils.formatCurrencyVND(_statistics['totalRevenue'] ?? 0)),
            _buildStatItem('Tổng chi phí', 
              FormatUtils.formatCurrencyVND(_statistics['totalCost'] ?? 0)),
            _buildStatItem('Lợi nhuận', 
              FormatUtils.formatCurrencyVND(_statistics['totalProfit'] ?? 0)),
                          if (_statistics['lastUpdate'] != null)
                _buildStatItem('Cập nhật cuối', 
                  FormatUtils.formatDateTime(DateTime.parse(_statistics['lastUpdate']))),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = {
      'all': 'Tất cả',
      'entry': 'Nhập liệu',
      'report': 'Báo cáo',
      'search': 'Tìm kiếm',
      'error': 'Lỗi',
    };

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: AppStyles.spacingM),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: filters.entries.map((entry) {
          final isSelected = _selectedFilter == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: AppStyles.spacingS),
            child: FilterChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = entry.key;
                });
              },
              backgroundColor: AppColors.backgroundCard,
              selectedColor: AppColors.mainColor.withOpacity(0.2),
              checkmarkColor: AppColors.mainColor,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.mainColor : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    final isUser = message.isUser;
    final time = FormatUtils.formatDateTime(message.timestamp);
    
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppStyles.spacingM,
        vertical: AppStyles.spacingS,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppStyles.spacingS),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.mainColor : AppColors.backgroundSecondary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isUser ? Icons.person : Icons.smart_toy,
                    size: 16,
                    color: isUser ? AppColors.textOnMain : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppStyles.spacingS),
                Text(
                  isUser ? 'Bạn' : 'AI',
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (message.type != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppStyles.spacingS,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getTypeColor(message.type!),
                      borderRadius: BorderRadius.circular(AppStyles.radiusS),
                    ),
                    child: Text(
                      _getTypeLabel(message.type!),
                      style: const TextStyle(
                        color: AppColors.textOnMain,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppStyles.spacingS),
                ],
                Text(
                  time,
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppStyles.spacingS),
            Text(
              message.text,
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            if (message.metadata != null && message.metadata!.isNotEmpty) ...[
              const SizedBox(height: AppStyles.spacingS),
              Container(
                padding: const EdgeInsets.all(AppStyles.spacingS),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(AppStyles.radiusS),
                ),
                child: Text(
                  'Metadata: ${message.metadata.toString()}',
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'entry':
        return AppColors.successColor;
      case 'report':
        return AppColors.warningColor;
      case 'search':
        return AppColors.infoColor;
      case 'error':
        return AppColors.errorColor;
      default:
        return AppColors.mainColor;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'entry':
        return 'NHẬP LIỆU';
      case 'report':
        return 'BÁO CÁO';
      case 'search':
        return 'TÌM KIẾM';
      case 'error':
        return 'LỖI';
      case 'user_input':
        return 'NGƯỜI DÙNG';
      default:
        return type.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử Chat'),
        backgroundColor: AppColors.mainColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportData,
            tooltip: 'Xuất dữ liệu',
          ),
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearHistory,
              tooltip: 'Xóa lịch sử',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.mainColor),
              ),
            )
          : Column(
              children: [
                _buildStatisticsCard(),
                _buildFilterChips(),
                Expanded(
                  child: _filteredMessages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.history,
                                size: 64,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(height: AppStyles.spacingM),
                              Text(
                                'Chưa có lịch sử chat',
                                style: AppStyles.headingSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredMessages.length,
                          itemBuilder: (context, index) {
                            return _buildMessageItem(_filteredMessages[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }
} 