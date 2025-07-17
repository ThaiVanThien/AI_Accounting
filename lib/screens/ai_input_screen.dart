import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/finance_record.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
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
  final AIService _aiService = AIService();
  final SpeechToText _speechToText = SpeechToText();
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isLoadingHistory = true;
  bool _isTyping = false;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _wordsSpoken = "";
  double _confidenceLevel = 0;
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
    _initSpeech();
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

  Future<void> _initSpeech() async {
    try {
      // Kiểm tra và yêu cầu quyền microphone
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        print('Microphone permission denied');
        return;
      }

      _speechEnabled = await _speechToText.initialize(
        onStatus: (status) {
          print('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            setState(() {
              _isListening = false;
            });
            _voiceAnimationController.stop();
          }
        },
        onError: (error) {
          print('Speech error: $error');
          setState(() {
            _isListening = false;
          });
          _voiceAnimationController.stop();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi nhận diện giọng nói: ${error.errorMsg}'),
                backgroundColor: AppColors.errorColor,
              ),
            );
          }
        },
      );
      setState(() {});
    } catch (e) {
      print('Error initializing speech: $e');
      setState(() {
        _speechEnabled = false;
      });
    }
  }

  Future<void> _startListening() async {
    if (!_speechEnabled) {
      await _initSpeech();
      if (!_speechEnabled) return;
    }

    setState(() {
      _isListening = true;
      _wordsSpoken = "";
      _confidenceLevel = 0;
    });

    _voiceAnimationController.repeat();

    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _wordsSpoken = result.recognizedWords;
          _confidenceLevel = result.confidence;
        });
        
        // Cập nhật text field với từ đã nhận diện
        _messageController.text = _wordsSpoken;
        _messageController.selection = TextSelection.fromPosition(
          TextPosition(offset: _messageController.text.length),
        );
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: 'vi_VN', // Tiếng Việt
      cancelOnError: true,
      listenMode: ListenMode.confirmation,
    );
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
    _voiceAnimationController.stop();
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
    return AnimatedBuilder(
      animation: _voiceAnimationController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(right: AppStyles.spacingS),
          child: GestureDetector(
            onTap: _isListening ? _stopListening : _startListening,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: _isListening 
                    ? LinearGradient(
                        colors: [
                          AppColors.errorColor,
                          AppColors.errorColor.withOpacity(0.8),
                        ],
                      )
                    : AppColors.mainGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isListening ? AppColors.errorColor : AppColors.mainColor)
                        .withOpacity(0.3),
                    blurRadius: _isListening ? 12 + (_voiceAnimationController.value * 8) : 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isListening) ...[
                    // Pulse animation rings
                    for (int i = 0; i < 3; i++)
                      Container(
                        width: 48 + (i * 10) + (_voiceAnimationController.value * 20),
                        height: 48 + (i * 10) + (_voiceAnimationController.value * 20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.errorColor.withOpacity(
                              (1 - _voiceAnimationController.value) * 0.3 / (i + 1)
                            ),
                            width: 2,
                          ),
                        ),
                      ),
                  ],
                  Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: AppColors.textOnMain,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
          // Voice listening indicator
          if (_isListening)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppStyles.spacingM,
                vertical: AppStyles.spacingS,
              ),
              decoration: BoxDecoration(
                color: AppColors.errorColor.withOpacity(0.1),
                border: const Border(
                  top: BorderSide(color: AppColors.borderLight),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.errorColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppStyles.spacingS),
                  const Text(
                    'Đang nghe...',
                    style: TextStyle(
                      color: AppColors.errorColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (_confidenceLevel > 0)
                    Text(
                      'Độ tin cậy: ${(_confidenceLevel * 100).toInt()}%',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
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
                    if (_speechEnabled) _buildVoiceButton(),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        enabled: !_isLoading,
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: _isListening 
                              ? 'Đang nghe giọng nói...' 
                              : 'Nhập tin nhắn hoặc dùng giọng nói...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppStyles.radiusL),
                            borderSide: BorderSide(
                              color: _isListening 
                                  ? AppColors.errorColor 
                                  : AppColors.borderLight,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppStyles.radiusL),
                            borderSide: BorderSide(
                              color: _isListening 
                                  ? AppColors.errorColor 
                                  : AppColors.mainColor, 
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
                        onPressed: (_isLoading || _isListening) ? null : _sendMessage,
                      ),
                    ),
                  ],
                ),
                if (!_speechEnabled && _speechToText.isNotListening)
                  Padding(
                    padding: const EdgeInsets.only(top: AppStyles.spacingS),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppStyles.spacingXS),
                        Text(
                          'Chức năng giọng nói chưa sẵn sàng',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
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
    );
  }

} 