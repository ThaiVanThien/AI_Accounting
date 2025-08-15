import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/finance_record.dart';
import '../models/chat_message.dart';
import '../models/order.dart';
import '../services/ai_service.dart';
import '../services/order_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../utils/format_utils.dart';
import 'chat_history_screen.dart';
import '../main.dart'; // Import để sử dụng CommonScreenMixin


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

class _AIInputScreenState extends State<AIInputScreen> with TickerProviderStateMixin, CommonScreenMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIService _aiService = AIService();
  final OrderService _orderService = OrderService();
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isLoadingHistory = true;
  bool _isTyping = false;
  late AnimationController _typingAnimationController;
  late AnimationController _voiceAnimationController;

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
    // Voice feature will be implemented in future updates
    _loadChatHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
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
      final history = await _aiService.getChatHistory();
      setState(() {
        _messages = history;
        _isLoadingHistory = false;
      });
      _scrollToBottom();
    } catch (e) {
      print('Error loading chat history: $e');
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text
        .trim()
        .isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _isLoading = true;
      _isTyping = true;
    });

    // Scroll to bottom to show typing indicator
    _scrollToBottom();

    try {
      // Sử dụng processMessage từ AI service
      final aiResponse = await _aiService.processMessage(
          userMessage, widget.records);

      // Reload lại lịch sử chat để có messages mới
      await _loadChatHistory();

      // Nếu là entry thành công, hiển thị dialog xác nhận
      if (aiResponse.type == 'entry' &&
          aiResponse.metadata != null &&
          aiResponse.metadata!['success'] == true) {
        final recordData = aiResponse.metadata!['record'];
        final record = FinanceRecord.fromJson(recordData);
        await _showSaveConfirmationDialog(record);
      }
      
      // Nếu là order preview thành công, hiển thị popup xác nhận
      if (aiResponse.type == 'order' &&
          aiResponse.metadata != null &&
          aiResponse.metadata!['order_preview'] == true &&
          aiResponse.metadata!['dialog_data'] != null) {
        final dialogData = aiResponse.metadata!['dialog_data'] as Map<String, dynamic>?;
        final previewData = aiResponse.metadata!['preview_data'] as Map<String, dynamic>?;
        if (dialogData != null && previewData != null) {
          await _showOrderConfirmationDialog(dialogData, previewData);
        }
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
      _scrollToBottom();
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
      await _aiService.clearChatHistory();
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

  Widget _buildVoiceButton() {
    return Container(
      margin: const EdgeInsets.only(right: AppStyles.spacingS),
      child: GestureDetector(
        onTap: _showVoiceComingSoonDialog,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.infoColor,
                AppColors.infoColor.withOpacity(0.8),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.infoColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.mic,
                color: AppColors.textOnMain,
                size: 24,
              ),
              // "Coming soon" indicator
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.warningColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.textOnMain,
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      '!',
                      style: TextStyle(
                        color: AppColors.textOnMain,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
              'Hãy thử: "Hôm nay bán được 500k, mua hàng 300k"',
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
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
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

  Future<void> _showOrderConfirmationDialog(Map<String, dynamic> dialogData, Map<String, dynamic> previewData) async {
    final title = dialogData["title"] as String? ?? "Xác nhận";
    final content = dialogData["content"] as String? ?? "";
    final positiveButton = dialogData["positive_button"] as String? ?? "Đồng ý";
    final negativeButton = dialogData["negative_button"] as String? ?? "Hủy";
    
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
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
                Icons.shopping_cart,
                color: AppColors.infoColor,
                size: 24,
              ),
            ),
            const SizedBox(width: AppStyles.spacingM),
            Text(title),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppStyles.spacingM),
              Container(
                padding: const EdgeInsets.all(AppStyles.spacingS),
                decoration: BoxDecoration(
                  color: AppColors.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radiusS),
                  border: Border.all(color: AppColors.warningColor.withOpacity(0.3)),
                ),
                child: const Text(
                  '⚠️ Vui lòng kiểm tra kỹ thông tin trước khi xác nhận tạo đơn hàng.',
                  style: TextStyle(
                    color: AppColors.warningColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(negativeButton),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successColor,
              foregroundColor: Colors.white,
            ),
            child: Text(positiveButton),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _handleOrderConfirmation(true, previewData);
    }
  }

  // Xử lý xác nhận đơn hàng qua AI Service
  Future<void> _handleOrderConfirmation(bool confirmed, Map<String, dynamic> previewData) async {
    try {
      final aiResponse = await _aiService.handleOrderConfirmation(confirmed, previewData);
      
      setState(() {
        _messages.add(aiResponse);
      });
      
      // Cuộn xuống cuối
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
      
      // Hiển thị snackbar thành công nếu tạo đơn hàng
      if (confirmed && aiResponse.metadata?['order_created'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ Đã tạo đơn hàng thành công!'),
              backgroundColor: AppColors.successColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xử lý đơn hàng: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _createOrderFromData(Map<String, dynamic> orderData) async {
    try {
      final items = orderData["items"] as List<Map<String, dynamic>>;
      final customerName = orderData["customer_name"] as String;
      final note = orderData["note"] as String;
      
      // Tạo order items từ matched products
      final List<OrderItem> orderItems = [];
      for (final item in items) {
        final product = item["product"];
        final quantity = item["quantity"];
        final matched = item["matched"];
        
        if (matched && product != null) {
          orderItems.add(OrderItem.fromProduct(product, quantity));
        }
      }
      
      if (orderItems.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không có sản phẩm nào khớp để tạo đơn hàng'),
              backgroundColor: AppColors.warningColor,
            ),
          );
        }
        return;
      }
      
      // Tạo đơn hàng
      final order = Order(
        id: '',
        orderNumber: '',
        orderDate: DateTime.now(),
        status: OrderStatus.draft,
        items: orderItems,
        note: note,
      );
      
      final success = await _orderService.addOrder(order);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã tạo đơn hàng thành công với ${orderItems.length} sản phẩm'),
            backgroundColor: AppColors.successColor,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tạo đơn hàng'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } catch (e) {
      print('Error creating order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tạo đơn hàng: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }
} 