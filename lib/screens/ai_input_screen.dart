import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
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

class _AIInputScreenState extends State<AIInputScreen>
    with TickerProviderStateMixin, CommonScreenMixin {
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

  // Speech Recognition
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _speechListening = false;
  String _speechText = '';
  double _confidenceLevel = 0;

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _voiceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _initializeSpeech();
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

  // Initialize speech recognition
  Future<void> _initializeSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );
    } catch (e) {
      print('Error initializing speech: $e');
      _speechEnabled = false;
    }
    if (mounted) {
      setState(() {});
    }
  }

  // Handle speech status changes
  void _onSpeechStatus(String status) {
    print('Speech status: $status');
    if (mounted) {
      setState(() {
        _speechListening = status == 'listening';
      });
    }
  }

  // Handle speech errors
  void _onSpeechError(dynamic error) {
    print('Speech error: $error');
    if (mounted) {
      setState(() {
        _speechListening = false;
      });

      String errorMessage = 'Lỗi không xác định';
      if (error.toString().contains('network')) {
        errorMessage = 'Lỗi kết nối mạng. Vui lòng kiểm tra internet.';
      } else if (error.toString().contains('permission')) {
        errorMessage =
            'Vui lòng cấp quyền microphone để sử dụng tính năng này.';
      } else if (error.toString().contains('not_available')) {
        errorMessage =
            'Tính năng nhận diện giọng nói không khả dụng trên thiết bị này.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  // Start speech recognition
  Future<void> _startListening() async {
    if (!_speechEnabled) {
      _showPermissionDialog();
      return;
    }

    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        localeId: 'vi_VN', // Vietnamese locale
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        onSoundLevelChange: _onSoundLevelChange,
      );

      if (mounted) {
        setState(() {
          _speechListening = true;
          _speechText = '';
        });
      }
    } catch (e) {
      print('Error starting speech recognition: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể khởi động nhận diện giọng nói: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  // Stop speech recognition
  Future<void> _stopListening() async {
    await _speechToText.stop();
    if (mounted) {
      setState(() {
        _speechListening = false;
      });
    }
  }

  // Handle speech results
  void _onSpeechResult(dynamic result) {
    if (mounted) {
      setState(() {
        _speechText = result.recognizedWords;
        _confidenceLevel = result.confidence;
      });

      // Update text field with recognized speech
      _messageController.text = _speechText;
    }
  }

  // Handle sound level changes for animation
  void _onSoundLevelChange(double level) {
    // You can use this for visual feedback
    if (mounted && _speechListening) {
      // Animate based on sound level
      _voiceAnimationController.animateTo(level / 100);
    }
  }

  // Show permission dialog
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusXL),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppStyles.spacingS),
              decoration: BoxDecoration(
                color: AppColors.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppStyles.radiusS),
              ),
              child: const Icon(
                Icons.mic_off,
                color: AppColors.warningColor,
                size: 24,
              ),
            ),
            const SizedBox(width: AppStyles.spacingM),
            const Expanded(
              child: Text(
                'Cần quyền microphone',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Để sử dụng tính năng nhập liệu bằng giọng nói, ứng dụng cần quyền truy cập microphone.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppStyles.spacingM),
            Container(
              padding: const EdgeInsets.all(AppStyles.spacingM),
              decoration: BoxDecoration(
                color: AppColors.infoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppStyles.radiusM),
                border: Border.all(color: AppColors.infoColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: AppColors.infoColor,
                        size: 20,
                      ),
                      const SizedBox(width: AppStyles.spacingS),
                      const Text(
                        'Tính năng này sẽ giúp bạn:',
                        style: TextStyle(
                          color: AppColors.infoColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppStyles.spacingS),
                  const Text(
                    '🎤 Nói thay vì gõ tin nhắn\n'
                    '🇻🇳 Nhận diện giọng nói tiếng Việt\n'
                    '⚡ Tương tác nhanh hơn với AI',
                    style: TextStyle(
                      color: AppColors.infoColor,
                      height: 1.5,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppStyles.spacingL,
                vertical: AppStyles.spacingM,
              ),
            ),
            child: const Text(
              'Để sau',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final status = await Permission.microphone.request();
              if (status.isGranted) {
                await _initializeSpeech();
                await _startListening();
              }
            },
            icon: const Icon(Icons.mic, size: 18),
            label: const Text('Cấp quyền'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppStyles.spacingL,
                vertical: AppStyles.spacingM,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.radiusM),
              ),
            ),
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
    if (_messageController.text.trim().isEmpty) return;

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
        userMessage,
        widget.records,
      );

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
        final dialogData =
            aiResponse.metadata!['dialog_data'] as Map<String, dynamic>?;
        final previewData =
            aiResponse.metadata!['preview_data'] as Map<String, dynamic>?;
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusXL),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppStyles.spacingS),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.successColor,
                    AppColors.successColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppStyles.radiusS),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.successColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.save_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: AppStyles.spacingM),
            const Expanded(
              child: Text(
                'Lưu giao dịch?',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
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
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
                      record.loiNhuan >= 0
                          ? AppColors.successColor
                          : AppColors.errorColor,
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
              padding: const EdgeInsets.symmetric(
                horizontal: AppStyles.spacingL,
                vertical: AppStyles.spacingM,
              ),
            ),
            child: const Text(
              'Không lưu',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Lưu giao dịch'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppStyles.spacingL,
                vertical: AppStyles.spacingM,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.radiusM),
              ),
            ),
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusXL),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppStyles.spacingS),
              decoration: BoxDecoration(
                color: AppColors.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppStyles.radiusS),
              ),
              child: const Icon(
                Icons.clear_all,
                color: AppColors.errorColor,
                size: 24,
              ),
            ),
            const SizedBox(width: AppStyles.spacingM),
            const Expanded(
              child: Text(
                'Xóa lịch sử chat',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bạn có chắc muốn xóa toàn bộ lịch sử chat?',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppStyles.spacingM),
            Container(
              padding: const EdgeInsets.all(AppStyles.spacingM),
              decoration: BoxDecoration(
                color: AppColors.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppStyles.radiusM),
                border: Border.all(color: AppColors.warningColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: AppColors.warningColor,
                    size: 20,
                  ),
                  const SizedBox(width: AppStyles.spacingS),
                  const Expanded(
                    child: Text(
                      'Hành động này không thể hoàn tác!',
                      style: TextStyle(
                        color: AppColors.warningColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppStyles.spacingL,
                vertical: AppStyles.spacingM,
              ),
            ),
            child: const Text(
              'Hủy',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_forever, size: 18),
            label: const Text('Xóa lịch sử'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppStyles.spacingL,
                vertical: AppStyles.spacingM,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.radiusM),
              ),
            ),
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
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
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
                    maxWidth:
                        MediaQuery.of(context).size.width *
                        (MediaQuery.of(context).size.width < 600 ? 0.85 : 0.75),
                  ),
                  padding: EdgeInsets.all(
                    MediaQuery.of(context).size.width < 600
                        ? AppStyles.spacingM
                        : AppStyles.spacingL,
                  ),
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
                        isUser ? AppStyles.radiusL : AppStyles.radiusS,
                      ),
                      bottomRight: Radius.circular(
                        isUser ? AppStyles.radiusS : AppStyles.radiusL,
                      ),
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
                          color: isUser
                              ? AppColors.textOnMain
                              : AppColors.textPrimary,
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
                              AppStyles.radiusS,
                            ),
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
                maxWidth:
                    MediaQuery.of(context).size.width *
                    (MediaQuery.of(context).size.width < 600 ? 0.85 : 0.75),
              ),
              padding: EdgeInsets.all(
                MediaQuery.of(context).size.width < 600
                    ? AppStyles.spacingM
                    : AppStyles.spacingL,
              ),
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
        final animationValue =
            (_typingAnimationController.value - (index * 0.2)) % 1.0;
        final opacity = (animationValue < 0.5)
            ? animationValue * 2
            : (1 - animationValue) * 2;
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
        onTap: _speechListening ? _stopListening : _startListening,
        child: AnimatedBuilder(
          animation: _voiceAnimationController,
          builder: (context, child) {
            return Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _speechListening
                      ? [
                          AppColors.errorColor,
                          AppColors.errorColor.withOpacity(0.8),
                        ]
                      : _speechEnabled
                      ? [
                          AppColors.successColor,
                          AppColors.successColor.withOpacity(0.8),
                        ]
                      : [
                          AppColors.textSecondary,
                          AppColors.textSecondary.withOpacity(0.8),
                        ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:
                        (_speechListening
                                ? AppColors.errorColor
                                : _speechEnabled
                                ? AppColors.successColor
                                : AppColors.textSecondary)
                            .withOpacity(0.3),
                    blurRadius: _speechListening ? 12 : 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedScale(
                    scale: _speechListening
                        ? 1.0 + (_voiceAnimationController.value * 0.2)
                        : 1.0,
                    duration: const Duration(milliseconds: 100),
                    child: Icon(
                      _speechListening ? Icons.mic : Icons.mic_none,
                      color: AppColors.textOnMain,
                      size: 24,
                    ),
                  ),
                  // Listening indicator
                  if (_speechListening)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.textOnMain,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.errorColor,
                            width: 1,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.circle,
                            color: AppColors.errorColor,
                            size: 6,
                          ),
                        ),
                      ),
                    ),
                  // Disabled indicator
                  if (!_speechEnabled && !_speechListening)
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
            );
          },
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
              horizontal: AppStyles.spacingXL,
            ),
            child: Text(
              'Tôi có thể giúp bạn:\n'
              '• Nhập dữ liệu tài chính\n'
              '• Tạo báo cáo doanh thu\n'
              '• Trả lời câu hỏi về kế toán\n'
              '• Phân tích dữ liệu\n'
              '🎤 Sử dụng giọng nói để tương tác',
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
          Theme(
            data: Theme.of(context).copyWith(
              popupMenuTheme: PopupMenuThemeData(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
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
                PopupMenuItem(
                  value: 'shop_info',
                  child: Row(
                    children: const [
                      Icon(Icons.store, color: Colors.grey),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Thông tin cửa hàng',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Divider tùy chỉnh
                PopupMenuItem(
                  enabled: false,
                  height: 0,
                  padding: EdgeInsets.zero,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    height: 1,
                    color: Colors.grey.shade300,
                  ),
                ),

                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: const [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Đăng xuất',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoadingHistory
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.mainColor,
                      ),
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
                        AppColors.mainColor,
                      ),
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
              border: Border(top: BorderSide(color: AppColors.borderLight)),
            ),
            child: Column(
              children: [
                // Speech recognition feedback
                if (_speechListening)
                  Container(
                    padding: const EdgeInsets.all(AppStyles.spacingS),
                    margin: const EdgeInsets.only(bottom: AppStyles.spacingS),
                    decoration: BoxDecoration(
                      color: AppColors.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppStyles.radiusM),
                      border: Border.all(
                        color: AppColors.successColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        AnimatedBuilder(
                          animation: _voiceAnimationController,
                          builder: (context, child) {
                            return Icon(
                              Icons.mic,
                              color: AppColors.successColor,
                              size: 16,
                            );
                          },
                        ),
                        const SizedBox(width: AppStyles.spacingS),
                        Expanded(
                          child: Text(
                            _speechText.isEmpty
                                ? 'Đang nghe... Hãy nói điều gì đó'
                                : 'Đã nhận diện: "$_speechText"',
                            style: TextStyle(
                              color: AppColors.successColor,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        if (_confidenceLevel > 0)
                          Text(
                            '${(_confidenceLevel * 100).toInt()}%',
                            style: TextStyle(
                              color: AppColors.successColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    _buildVoiceButton(),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        enabled: !_isLoading && !_speechListening,
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: _speechListening
                              ? 'Đang nghe giọng nói...'
                              : 'Nhập tin nhắn hoặc nhấn mic để nói...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppStyles.radiusL,
                            ),
                            borderSide: BorderSide(
                              color: _speechListening
                                  ? AppColors.successColor
                                  : AppColors.borderLight,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppStyles.radiusL,
                            ),
                            borderSide: const BorderSide(
                              color: AppColors.mainColor,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppStyles.radiusL,
                            ),
                            borderSide: BorderSide(
                              color: _speechListening
                                  ? AppColors.successColor
                                  : AppColors.borderLight,
                              width: _speechListening ? 2 : 1,
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

  Future<void> _showOrderConfirmationDialog(
    Map<String, dynamic> dialogData,
    Map<String, dynamic> previewData,
  ) async {
    final title = dialogData["title"] as String? ?? "Xác nhận";
    final content = dialogData["content"] as String? ?? "";
    final positiveButton = dialogData["positive_button"] as String? ?? "Đồng ý";
    final negativeButton = dialogData["negative_button"] as String? ?? "Hủy";

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusXL),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppStyles.spacingS),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.infoColor,
                    AppColors.infoColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppStyles.radiusS),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.infoColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shopping_cart,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: AppStyles.spacingM),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.044,
                  fontWeight: FontWeight.w700,
                  color: AppColors.infoColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
                  border: Border.all(
                    color: AppColors.warningColor.withOpacity(0.3),
                  ),
                ),
                child:  Text(
                  '⚠️ Vui lòng kiểm tra kỹ thông tin trước khi xác nhận tạo đơn hàng.',
                  style: TextStyle(color: AppColors.warningColor, fontSize: MediaQuery.of(context).size.width * 0.03),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppStyles.spacingL,
                vertical: AppStyles.spacingM,
              ),
            ),
            child: Text(
              negativeButton,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.035,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check_circle, size: 18),
            label: Text(
              positiveButton,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.035,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppStyles.spacingL,
                vertical: AppStyles.spacingM,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.radiusM),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _handleOrderConfirmation(true, previewData);
    }
  }

  // Xử lý xác nhận đơn hàng qua AI Service
  Future<void> _handleOrderConfirmation(
    bool confirmed,
    Map<String, dynamic> previewData,
  ) async {
    try {
      final aiResponse = await _aiService.handleOrderConfirmation(
        confirmed,
        previewData,
      );

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
          // Convert quantity to double to handle both int and double types
          final quantityValue = quantity is int ? quantity.toDouble() : (quantity as double);
          orderItems.add(OrderItem.fromProduct(product, quantityValue));
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
            content: Text(
              'Đã tạo đơn hàng thành công với ${orderItems.length} sản phẩm',
            ),
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
