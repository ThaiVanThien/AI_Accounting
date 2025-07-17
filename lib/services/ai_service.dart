import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/finance_record.dart';
import '../models/chat_message.dart';
import '../utils/format_utils.dart';
import 'storage_manager.dart';

class AIService {
  // API Keys từ Python.py
  final List<String> _apiKeys = [
    "AIzaSyBEfaLoEVOYc2Tft0m63Ae8HuxwaF8pCdA",
    "AIzaSyDmoMtVlGQqKQ8D1fHOxuP5ZBdEQvAgyO4",
    "AIzaSyBCSfatIlev3xZN9MrQlIhSu_dYrxoaExY"
  ];
  int _currentApiKeyIndex = 0;
  
  final StorageManager _storageManager = StorageManager();

  String _getPromptTypeInput(String userInput) {
    final now = DateTime.now();
    return '''Bạn là AI chuyên xử lý dữ liệu tài chính Việt Nam.
    DateTime: $now
    Context: Người dùng yêu cầu nhập hoặc báo cáo
    Task: Hãy xác định chính xác yêu cầu của người dùng và chuyển đổi thành JSON
    
    Examples:
    Input: 'Hôm nay bán được 500k, mua hàng hết 300k'
    Output: {"type_input": "entry"}
    
    Input: 'Báo cáo doanh thu quý 3'
    Output: {"type_input": "report", "report_type": "quy", "period": 3, "year": 2025}
    
    Input: 'Báo cáo tháng 7'
    Output: {"type_input": "report", "report_type": "thang", "period": 7, "year": 2025}
    
    Input: 'Báo cáo năm 2024'
    Output: {"type_input": "report", "report_type": "nam", "year": 2024}
    
    Input: 'Xem báo cáo hôm nay'
    Output: {"type_input": "report", "report_type": "ngay", "date": "${now.toString().split(' ')[0]}"}
    
    Input: 'Kế toán là gì'
    Output: {"type_input": "search"}
    
    Hãy phân tích dữ liệu sau: $userInput''';
  }

  String _getWritePromptText(String userInput) {
    final now = DateTime.now();
    return '''Bạn là AI chuyên xử lý dữ liệu tài chính Việt Nam.
Thời gian hiện tại: ${now.toString().split(' ')[0]}
Context: Người dùng sẽ nói về doanh thu và chi phí trong ngày. Nếu tiền nợ sẽ tính vào tiền chi phí
Task: Trích xuất chính xác số tiền và chuyển đổi thành JSON.
Examples: Input: 'Hôm nay bán được 500k, mua hàng hết 300k' 
Output: {"doanh_thu": 500000, "chi_phi": 300000,"ghi_chu": "Lấy thông tin từ input có thể để trống", "ngay_tao": "2024-01-15"} 
Input: "Thu về 2 triệu 5, chi tiêu 1 triệu 2"
Output: {"doanh_thu": 2500000, "chi_phi": 1200000,"ghi_chu": "Lấy thông tin từ input có thể để trống", "ngay_tao": "2024-01-15"} Response (JSON only) không có Json data:
Nếu dữ liệu không liên quan thì trả về 'Error'
Hãy phân tích dữ liệu sau: $userInput''';
  }

  String _cleanJsonText(String text) {
    String cleanJson = text.trim().replaceAll('`', '').replaceAll('\n', '');
    if (cleanJson.startsWith("json")) {
      cleanJson = cleanJson.substring(4);
    }
    return cleanJson;
  }

  Future<String> callGeminiAPI(String prompt) async {
    for (int attempt = 0; attempt < _apiKeys.length; attempt++) {
      try {
        final model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: _apiKeys[_currentApiKeyIndex],
        );

        final content = [Content.text(prompt)];
        final response = await model.generateContent(content);

        if (response.text != null && response.text!.isNotEmpty) {
          return response.text!;
        } else {
          throw Exception("Empty response from API");
        }
      } catch (e) {
        print('Lỗi API key ${_currentApiKeyIndex + 1}: $e');
        _currentApiKeyIndex = (_currentApiKeyIndex + 1) % _apiKeys.length;
        if (attempt == _apiKeys.length - 1) {
          throw Exception("Đã thử hết tất cả API keys nhưng vẫn lỗi: $e");
        }
      }
    }
    throw Exception("Không thể gọi API");
  }

  Future<Map<String, dynamic>> analyzeUserInput(String userInput) async {
    final typeResponse = await callGeminiAPI(_getPromptTypeInput(userInput));
    final cleanTypeJson = _cleanJsonText(typeResponse);
    return jsonDecode(cleanTypeJson);
  }

  Future<FinanceRecord?> extractFinanceData(String userInput) async {
    final entryResponse = await callGeminiAPI(_getWritePromptText(userInput));
    final cleanEntryJson = _cleanJsonText(entryResponse);
    
    if (cleanEntryJson == "Error") {
      return null;
    }
    
    final data = jsonDecode(cleanEntryJson);
    return FinanceRecord(
      id: 0,
      doanhThu: (data["doanh_thu"] ?? 0).toDouble(),
      chiPhi: (data["chi_phi"] ?? 0).toDouble(),
      ghiChu: data["ghi_chu"] ?? "",
      ngayTao: DateTime.parse(data["ngay_tao"]),
    );
  }

  String generateReport(Map<String, dynamic> analysis, List<FinanceRecord> records) {
    final reportType = analysis["report_type"];
    final year = analysis["year"] ?? DateTime.now().year;
    
    List<FinanceRecord> filteredRecords = [];
    
    switch (reportType) {
      case "thang":
        final month = analysis["period"] ?? DateTime.now().month;
        filteredRecords = records.where((record) {
          return record.ngayTao.month == month && record.ngayTao.year == year;
        }).toList();
        break;
      case "quy":
        final quarter = analysis["period"] ?? ((DateTime.now().month - 1) ~/ 3) + 1;
        final startMonth = (quarter - 1) * 3 + 1;
        final endMonth = quarter * 3;
        filteredRecords = records.where((record) {
          return record.ngayTao.month >= startMonth &&
              record.ngayTao.month <= endMonth &&
              record.ngayTao.year == year;
        }).toList();
        break;
      case "nam":
        filteredRecords = records.where((record) {
          return record.ngayTao.year == year;
        }).toList();
        break;
      case "ngay":
        final date = DateTime.parse(analysis["date"]);
        filteredRecords = records.where((record) {
          return record.ngayTao.year == date.year &&
              record.ngayTao.month == date.month &&
              record.ngayTao.day == date.day;
        }).toList();
        break;
    }

    double totalRevenue = filteredRecords.fold(0, (sum, record) => sum + record.doanhThu);
    double totalCost = filteredRecords.fold(0, (sum, record) => sum + record.chiPhi);
    double totalProfit = totalRevenue - totalCost;

    String reportTitle = "";
    switch (reportType) {
      case "thang":
        reportTitle = "Báo cáo tháng ${analysis["period"]}/$year";
        break;
      case "quy":
        reportTitle = "Báo cáo quý ${analysis["period"]}/$year";
        break;
      case "nam":
        reportTitle = "Báo cáo năm $year";
        break;
      case "ngay":
        reportTitle = "Báo cáo ngày ${analysis["date"]}";
        break;
    }

    return '''$reportTitle
�� Tổng doanh thu: ${FormatUtils.formatCurrency(totalRevenue)} VNĐ
💸 Tổng chi phí: ${FormatUtils.formatCurrency(totalCost)} VNĐ
📊 Lợi nhuận: ${FormatUtils.formatCurrency(totalProfit)} VNĐ
📈 Số giao dịch: ${filteredRecords.length} 
${totalRevenue > 0 ? '📋 Tỷ lệ lợi nhuận: ${(totalProfit / totalRevenue * 100).toStringAsFixed(2)}%' : ''}''';
  }

  // Xử lý tin nhắn và lưu lịch sử
  Future<ChatMessage> processMessage(String userMessage, List<FinanceRecord> records) async {
    // Lưu tin nhắn của user
    final userChatMessage = ChatMessage(
      text: userMessage,
      isUser: true,
      type: 'user_input',
    );
    await _storageManager.addChatMessage(userChatMessage);

    try {
      // Phân tích loại input
      final analysis = await analyzeUserInput(userMessage);
      String aiResponse = "";
      String messageType = "general";
      Map<String, dynamic>? metadata;

      if (analysis["type_input"] == "entry") {
        // Xử lý nhập liệu
        final record = await extractFinanceData(userMessage);
        messageType = "entry";
        
        if (record == null) {
          aiResponse = "Dữ liệu không liên quan đến tài chính. Vui lòng nhập thông tin về doanh thu và chi phí.";
          metadata = {"success": false, "reason": "invalid_data"};
        } else {
          aiResponse = '''📝 Dữ liệu đã được xử lý:
💰 Doanh thu: ${FormatUtils.formatCurrency(record.doanhThu)} VNĐ
💸 Chi phí: ${FormatUtils.formatCurrency(record.chiPhi)} VNĐ
📊 Lợi nhuận: ${FormatUtils.formatCurrency(record.loiNhuan)} VNĐ
📅 Ngày: ${FormatUtils.formatSimpleDate(record.ngayTao)}
✏️ Ghi chú: ${record.ghiChu}
          ''';
          metadata = {
            "success": true,
            "record": record.toJson(),
            "revenue": record.doanhThu,
            "cost": record.chiPhi,
            "profit": record.loiNhuan,
          };
        }
      } else if (analysis["type_input"] == "report") {
        // Xử lý báo cáo
        messageType = "report";
        aiResponse = generateReport(analysis, records);
        metadata = {
          "report_type": analysis["report_type"],
          "period": analysis["period"],
          "year": analysis["year"],
          "date": analysis["date"],
        };
      } else {
        // Xử lý câu hỏi chung
        messageType = "search";
        final generalResponse = await callGeminiAPI("$userMessage Giải thích ngắn gọn về kế toán và tài chính");
        aiResponse = generalResponse;
        metadata = {"query": userMessage};
      }

      // Tạo và lưu tin nhắn phản hồi của AI
      final aiChatMessage = ChatMessage(
        text: aiResponse,
        isUser: false,
        type: messageType,
        metadata: metadata,
      );
      await _storageManager.addChatMessage(aiChatMessage);

      return aiChatMessage;
    } catch (e) {
      final errorMessage = ChatMessage(
        text: "Lỗi khi xử lý: $e",
        isUser: false,
        type: "error",
        metadata: {"error": e.toString()},
      );
              await _storageManager.addChatMessage(errorMessage);
      return errorMessage;
    }
  }

  // Lấy lịch sử chat
  Future<List<ChatMessage>> getChatHistory() async {
    return await _storageManager.getChatHistory();
  }

  // Xóa lịch sử chat
  Future<void> clearChatHistory() async {
    await _storageManager.clearChatHistory();
  }

  // Lấy thống kê chat
  Future<Map<String, dynamic>> getChatStatistics() async {
    final chatHistory = await getChatHistory();
    final userMessages = chatHistory.where((msg) => msg.isUser).length;
    final aiMessages = chatHistory.where((msg) => !msg.isUser).length;
    
    // Đếm theo loại tin nhắn
    final entryMessages = chatHistory.where((msg) => msg.type == 'entry').length;
    final reportMessages = chatHistory.where((msg) => msg.type == 'report').length;
    final searchMessages = chatHistory.where((msg) => msg.type == 'search').length;
    final errorMessages = chatHistory.where((msg) => msg.type == 'error').length;

    return {
      'totalMessages': chatHistory.length,
      'userMessages': userMessages,
      'aiMessages': aiMessages,
      'entryMessages': entryMessages,
      'reportMessages': reportMessages,
      'searchMessages': searchMessages,
      'errorMessages': errorMessages,
      'lastMessageTime': chatHistory.isNotEmpty ? chatHistory.last.timestamp.toIso8601String() : null,
    };
  }
} 