import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/finance_record.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../services/storage_manager.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../utils/format_utils.dart';
import 'chat_history_screen.dart';


class AIInputScreen extends StatefulWidget {
  final Function(FinanceRecord) onAddRecord;
  final List<FinanceRecord> records;

  const AIInputScreen({
    super.key,
    required this.onAddRecord,
    required this.records,
  });

  @override
  State<AIInputScreen> createState() => _AIInputScreenState();
}

class _AIInputScreenState extends State<AIInputScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _suggestionsScrollController = ScrollController();
  final AIService _aiService = AIService();
  final StorageManager _storageManager = StorageManager();
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isLoadingHistory = true;
  bool _isTyping = false;
  late AnimationController _typingAnimationController;
  late AnimationController _voiceAnimationController;

  // Danh sách gợi ý nhanh
  final List<String> _quickSuggestions = [
    'Báo cáo doanh thu tháng này',
    'Báo cáo doanh thu năm này',
    'Báo cáo doanh thu quý này',
    // 'Tổng lợi nhuận tháng này',
    // 'Phân tích xu hướng doanh thu',
    // 'So sánh doanh thu các tháng',
    // 'Doanh thu cao nhất là bao nhiều?',
    // 'Tháng nào lỗ nhiều nhất?',
  ];

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )
      ..repeat();
    _voiceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Không cần scroll listener với reverse ListView
    
    // Voice feature will be implemented in future updates
    _loadChatHistory();
  }

  void _scrollListener() {
    // Simple listener để maintain bottom position
  }

  void _jumpToBottom() {
    // Sử dụng SchedulerBinding để đảm bảo timing chính xác
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Thêm delay nhỏ để đảm bảo ListView đã render xong
      Future.delayed(const Duration(milliseconds: 50), () {
        if (_scrollController.hasClients && mounted) {
          final maxExtent = _scrollController.position.maxScrollExtent;
          if (maxExtent > 0) {
            _scrollController.jumpTo(maxExtent);
          }
        }
      });
    });
  }

  @override
  void didUpdateWidget(AIInputScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Với reverse ListView, không cần thêm logic scroll
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _suggestionsScrollController.dispose();
    _typingAnimationController.dispose();
    _voiceAnimationController.dispose();
    super.dispose();
  }

  void _showVoiceComingSoonDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.infoColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mic,
                color: AppColors.infoColor,
                size: 24,
              ),
            ),
            const SizedBox(width: AppStyles.spacingM),
            const Text('Tính năng giọng nói'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎤 Tính năng nhập liệu bằng giọng nói đang được phát triển',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppStyles.spacingM),
            Text(
              'Tính năng này sẽ cho phép bạn:',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppStyles.spacingS),
            Text(
              '• Nói thay vì gõ tin nhắn\n'
              '• Nhận diện giọng nói tiếng Việt\n'
              '• Chuyển đổi giọng nói thành text\n'
              '• Tương tác nhanh hơn với AI',
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            SizedBox(height: AppStyles.spacingM),
            Text(
              '⏰ Sẽ có trong bản cập nhật tiếp theo!',
              style: TextStyle(
                color: AppColors.successColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.infoColor,
              foregroundColor: AppColors.textOnMain,
            ),
            child: const Text('Đã hiểu'),
          ), 
        ],
      ),
    );
  }

  Future<void> _loadChatHistory() async {
    try {
      final history = await _storageManager.getChatHistory();
      setState(() {
        _messages = history;
        _isLoadingHistory = false;
      });
      
      // Với reverse ListView, không cần scroll nữa
    } catch (e) {
      print('Error loading chat history: $e');
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }



    void _scrollToBottom({bool delayed = false}) {
    // Chỉ sử dụng animation cho tin nhắn mới (smooth scroll)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _messages.isNotEmpty) {
        final maxExtent = _scrollController.position.maxScrollExtent;
        if (maxExtent > 0) {
          _scrollController.animateTo(
            maxExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  void _onSuggestionTap(String suggestion) {
    _messageController.text = suggestion;
    _sendMessage();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text
        .trim()
        .isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    // 1. Thêm tin nhắn user ngay lập tức
    final userChatMessage = ChatMessage(
      text: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
      type: 'user_input',
    );

    setState(() {
      _messages.add(userChatMessage);
      _isLoading = true;
      _isTyping = true;
    });

    // Debug: In ra để kiểm tra state
    print('User message added: ${_messages.length} messages');
    print('Typing started: _isTyping = $_isTyping, _isLoading = $_isLoading');

    try {
      // 2. Sử dụng processMessage từ AI service
      final aiResponse = await _aiService.processMessage(
          userMessage, widget.records);

      // 3. Thêm tin nhắn AI vào danh sách (thay vì reload toàn bộ)
      final aiChatMessage = ChatMessage(
        text: aiResponse.text,
        isUser: false,
        timestamp: DateTime.now(),
        type: aiResponse.type,
        metadata: aiResponse.metadata,
      );

      setState(() {
        _messages.add(aiChatMessage);
      });

             // 4. Lưu toàn bộ chat history vào storage
       await _storageManager.saveChatHistory(_messages);

      // Nếu là entry thành công, hiển thị dialog xác nhận
      if (aiResponse.type == 'entry' &&
          aiResponse.metadata != null &&
          aiResponse.metadata!['success'] == true) {
        final recordData = aiResponse.metadata!['record'];
        final record = FinanceRecord.fromJson(recordData);
        await _showSaveConfirmationDialog(record);
      }
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi gửi tin nhắn: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isTyping = false;
      });
      
      // Debug: In ra để kiểm tra state
      print('Typing finished: _isTyping = $_isTyping, _isLoading = $_isLoading');
      
      // Với reverse ListView, tin nhắn mới tự động hiển thị ở dưới
    }
  }

  Future<void> _showSaveConfirmationDialog(FinanceRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Không cho phép đóng bằng cách tap ngoài
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.successColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.save_outlined,
                color: AppColors.successColor,
                size: 24,
              ),
            ),
            const SizedBox(width: AppStyles.spacingM),
            const Text('Lưu giao dịch?'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI đã phân tích và tạo giao dịch sau:',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppStyles.spacingM),
              Container(
                padding: const EdgeInsets.all(AppStyles.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(AppStyles.radiusM),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRecordDetailRow(
                      '💰 Doanh thu:', 
                      FormatUtils.formatCurrencyVND(record.doanhThu),
                      AppColors.successColor,
                    ),
                    const SizedBox(height: AppStyles.spacingS),
                    _buildRecordDetailRow(
                      '💸 Chi phí:', 
                      FormatUtils.formatCurrencyVND(record.chiPhi),
                      AppColors.errorColor,
                    ),
                    const SizedBox(height: AppStyles.spacingS),
                    _buildRecordDetailRow(
                      '📊 Lợi nhuận:', 
                      FormatUtils.formatCurrencyVND(record.loiNhuan),
                      record.loiNhuan >= 0 ? AppColors.successColor : AppColors.errorColor,
                    ),
                    if (record.ghiChu.isNotEmpty) ...[
                      const SizedBox(height: AppStyles.spacingS),
                      _buildRecordDetailRow(
                        '📝 Ghi chú:', 
                        record.ghiChu,
                        AppColors.textSecondary,
                      ),
                    ],
                    const SizedBox(height: AppStyles.spacingS),
                    _buildRecordDetailRow(
                      '📅 Ngày:', 
                      FormatUtils.formatSimpleDate(record.ngayTao),
                      AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppStyles.spacingM),
              const Text(
                'Bạn có muốn lưu giao dịch này không?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text('Không lưu'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successColor,
              foregroundColor: AppColors.textOnMain,
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        widget.onAddRecord(record);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.textOnMain),
                  SizedBox(width: AppStyles.spacingS),
                  Text('Đã lưu giao dịch thành công!'),
                ],
              ),
              backgroundColor: AppColors.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi lưu giao dịch: $e'),
              backgroundColor: AppColors.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.textOnMain),
                SizedBox(width: AppStyles.spacingS),
                Text('Giao dịch không được lưu'),
              ],
            ),
            backgroundColor: AppColors.infoColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildRecordDetailRow(String label, String value, Color valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
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
      await _storageManager.clearChatHistory();
      setState(() {
        _messages.clear();
      });
    }
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final time = FormatUtils.formatTime(message.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: AppStyles.spacingL),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment
            .start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: AppStyles.spacingM),
              decoration: BoxDecoration(
                gradient: AppColors.mainGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.mainColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy,
                color: AppColors.textOnMain,
                size: 24,
              ),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery
                        .of(context)
                        .size
                        .width * 0.75,
                  ),
                  padding: const EdgeInsets.all(AppStyles.spacingL),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? AppColors.mainGradient
                        : LinearGradient(
                      colors: [
                        AppColors.backgroundCard,
                        AppColors.backgroundCard.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(AppStyles.radiusL),
                      topRight: const Radius.circular(AppStyles.radiusL),
                      bottomLeft: Radius.circular(
                          isUser ? AppStyles.radiusL : AppStyles.radiusS),
                      bottomRight: Radius.circular(
                          isUser ? AppStyles.radiusS : AppStyles.radiusL),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isUser
                            ? AppColors.mainColor.withOpacity(0.3)
                            : AppColors.shadowLight,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: isUser
                        ? null
                        : Border.all(
                      color: AppColors.mainColor.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          color: isUser ? AppColors.textOnMain : AppColors
                              .textPrimary,
                          fontSize: 15,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (message.type != null) ...[
                        const SizedBox(height: AppStyles.spacingXS),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppStyles.spacingS,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getTypeColor(message.type!),
                            borderRadius: BorderRadius.circular(
                                AppStyles.radiusS),
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
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppStyles.spacingS),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: AppColors.textSecondary.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isUser) ...[
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(left: AppStyles.spacingM),
              decoration: BoxDecoration(
                gradient: AppColors.mainGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.mainColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person,
                color: AppColors.textOnMain,
                size: 24,
              ),
            ),
          ],
        ],
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

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppStyles.spacingL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: AppStyles.spacingM),
            decoration: BoxDecoration(
              gradient: AppColors.mainGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.mainColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy,
              color: AppColors.textOnMain,
              size: 24,
            ),
          ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery
                    .of(context)
                    .size
                    .width * 0.75,
              ),
              padding: const EdgeInsets.all(AppStyles.spacingL),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.backgroundCard,
                    AppColors.backgroundCard.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppStyles.radiusL),
                  topRight: Radius.circular(AppStyles.radiusL),
                  bottomLeft: Radius.circular(AppStyles.radiusS),
                  bottomRight: Radius.circular(AppStyles.radiusL),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: AppColors.mainColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTypingDot(0),
                  const SizedBox(width: 4),
                  _buildTypingDot(1),
                  const SizedBox(width: 4),
                  _buildTypingDot(2),
                  const SizedBox(width: AppStyles.spacingS),
                  Text(
                    'AI đang trả lời...',
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.8),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedBuilder(
      animation: _typingAnimationController,
      builder: (context, child) {
        final animationValue = (_typingAnimationController.value -
            (index * 0.2)) % 1.0;
        final opacity = (animationValue < 0.5) ? animationValue * 2 : (1 -
            animationValue) * 2;
        final scale = 0.8 + (opacity * 0.4);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.mainColor.withOpacity(0.4 + (opacity * 0.6)),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionChips() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: AppStyles.spacingM),
      child: SingleChildScrollView(
        controller: _suggestionsScrollController,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _quickSuggestions.asMap().entries.map((entry) {
            final index = entry.key;
            final suggestion = entry.value;
            
            return Container(
              margin: EdgeInsets.only(
                left: index == 0 ? 0 : AppStyles.spacingS,
                right: index == _quickSuggestions.length - 1 ? 0 : 0,
              ), 
              child: Material(
                color: Colors.transparent,
                child: InkWell(  
                  onTap: () => _onSuggestionTap(suggestion),
                  borderRadius: BorderRadius.circular(AppStyles.radiusL),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppStyles.spacingM,
                      vertical: AppStyles.spacingS,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.mainColor.withOpacity(0.1),
                          AppColors.mainColor.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppStyles.radiusL),
                      border: Border.all(
                        color: AppColors.mainColor.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.mainColor.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getSuggestionIcon(suggestion),
                          size: 16,
                          color: AppColors.mainColor,
                        ),
                        const SizedBox(width: AppStyles.spacingXS),
                        Text(
                          suggestion,
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.mainColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  } 

  IconData _getSuggestionIcon(String suggestion) {
    if (suggestion.contains('báo cáo') || suggestion.contains('Báo cáo')) {
      return Icons.bar_chart;
    } else if (suggestion.contains('bán') || suggestion.contains('doanh thu')) {
      return Icons.trending_up;
    } else if (suggestion.contains('chi phí') || suggestion.contains('Chi phí')) {
      return Icons.trending_down;
    } else if (suggestion.contains('lợi nhuận')) {
      return Icons.account_balance_wallet;
    } else if (suggestion.contains('phân tích') || suggestion.contains('so sánh')) {
      return Icons.analytics;
    } else if (suggestion.contains('cao nhất') || suggestion.contains('nhiều nhất')) {
      return Icons.query_stats;
    } else {
      return Icons.chat_bubble_outline;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              gradient: AppColors.mainGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              color: AppColors.textOnMain,
              size: 40,
            ),
          ),
          const SizedBox(height: AppStyles.spacingL),
          Text(
            'Chào mừng đến với AI Chat!',
            style: AppStyles.headingMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppStyles.spacingM),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppStyles.spacingXL),
            child: Text(
              'Tôi có thể giúp bạn:\n'
                  '• Nhập dữ liệu tài chính\n'
                  '• Tạo báo cáo doanh thu\n'
                  '• Trả lời câu hỏi về kế toán\n'
                  '• Phân tích dữ liệu',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppStyles.spacingL),
          Container(
            padding: const EdgeInsets.all(AppStyles.spacingM),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(AppStyles.radiusM),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Text(
              'Hoặc chọn gợi ý bên dưới để bắt đầu',
              style: AppStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat'),
        backgroundColor: AppColors.mainColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history), 
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatHistoryScreen(),
                ),
              );
            },
            tooltip: 'Lịch sử chat',
          ),
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearHistory,
              tooltip: 'Xóa lịch sử',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoadingHistory
                ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.mainColor),
              ),
            )
                : _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppStyles.spacingM),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              reverse: true, // Đảo ngược để tin nhắn mới nhất ở dưới
              itemBuilder: (context, index) {
                if (_isTyping && index == 0) {
                  return _buildTypingIndicator();
                }
                
                // Handle edge case khi messages empty
                if (_messages.isEmpty) {
                  return const SizedBox.shrink();
                }
                
                final messageIndex = _isTyping ? index - 1 : index;
                final reversedIndex = _messages.length - 1 - messageIndex;
                
                // Đảm bảo index valid
                if (reversedIndex < 0 || reversedIndex >= _messages.length) {
                  return const SizedBox.shrink();
                }
                
                return _buildMessageBubble(_messages[reversedIndex]);
              },
            ),
          ),
          if (_isLoading && !_isTyping)
            Container(
              padding: const EdgeInsets.all(AppStyles.spacingM),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.mainColor),
                    ),
                  ),
                  const SizedBox(width: AppStyles.spacingS),
                  Text(
                    'Đang xử lý...',
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          // Suggestion chips
          if (!_isLoading && _messageController.text.isEmpty) ...[
            const SizedBox(height: AppStyles.spacingS),
            _buildSuggestionChips(),
          ],
          
          // Voice feature placeholder - will be implemented in future updates
          Container(
            padding: const EdgeInsets.all(AppStyles.spacingM),
            decoration: const BoxDecoration(
              color: AppColors.backgroundCard,
              border: Border(
                top: BorderSide(color: AppColors.borderLight),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // _buildVoiceButton(),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        enabled: !_isLoading,
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        onChanged: (value) {
                          // Rebuild để hiển thị/ẩn suggestion chips
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          hintText: 'Nhập tin nhắn ...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppStyles.radiusL),
                            borderSide: const BorderSide(
                              color: AppColors.borderLight,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppStyles.radiusL),
                            borderSide: const BorderSide(
                              color: AppColors.mainColor, 
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppStyles.spacingM,
                            vertical: AppStyles.spacingS,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppStyles.spacingS),
                    Container( 
                      decoration: const BoxDecoration(
                        gradient: AppColors.mainGradient,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send),
                        color: AppColors.textOnMain,
                        onPressed: _isLoading ? null : _sendMessage,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

} 