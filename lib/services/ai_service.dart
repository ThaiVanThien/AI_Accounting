import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/finance_record.dart';
import '../models/chat_message.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../utils/format_utils.dart';
import 'storage_manager.dart';
import 'product_service.dart';

class AIService {
  // API Keys từ Python.py
  final List<String> _apiKeys = [
    "AIzaSyBEfaLoEVOYc2Tft0m63Ae8HuxwaF8pCdA",
    "AIzaSyDmoMtVlGQqKQ8D1fHOxuP5ZBdEQvAgyO4",
    "AIzaSyBCSfatIlev3xZN9MrQlIhSu_dYrxoaExY"
  ];
  int _currentApiKeyIndex = 0;
  
  final StorageManager _storageManager = StorageManager();
  final ProductService _productService = ProductService();

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
    
    Input: 'Bán 2 chai nước suối, 1 bánh mì'
    Output: {"type_input": "order"}
    
    Input: 'Tạo đơn hàng 3 bút bi, 5 gói mì tôm'
    Output: {"type_input": "order"}
    
    Hãy phân tích dữ liệu sau: $userInput''';
  }

  String _getWritePromptText(String userInput) {
    final now = DateTime.now();
    return '''Bạn là AI chuyên xử lý dữ liệu tài chính Việt Nam.
    Thời gian hiện tại: ${now.toString().split(' ')[0]}
    Context: Người dùng sẽ nói về doanh thu và chi phí trong ngày. Nếu tiền nợ sẽ tính vào tiền chi phí
    Task: Trích xuất chính xác số tiền và chuyển đổi thành JSON.
    Examples: Input: 'Hôm nay bán được 500k, mua hàng hết 300k' 
    Output: {"doanh_thu": 500000, "chi_phi": 300000,"ghi_chu": "", "ngay_tao": "2024-01-15"} //Ghi chú: ""
    Input: "Thu về 2 triệu 5, chi tiêu 1 triệu 2"
    Output: {"doanh_thu": 2500000, "chi_phi": 1200000,"ghi_chu": "", "ngay_tao": "2024-01-15"} Response (JSON only) không có Json data:  //Ghi chú: ""
    Nếu dữ liệu không liên quan thì trả về 'Error'
    Hãy phân tích dữ liệu sau: $userInput''';
  }

  String _getOrderPromptText(String userInput, List<Product> availableProducts) {
    final now = DateTime.now();
    final productList = availableProducts.map((p) => 
      '{"name": "${p.name}", "code": "${p.code}", "unit": "${p.unit}", "price": ${p.sellingPrice}}'
    ).join(', ');
    
    return '''Bạn là AI chuyên xử lý đơn hàng bán hàng Việt Nam.
    Thời gian hiện tại: ${now.toString().split(' ')[0]}
    Danh sách sản phẩm có sẵn: [$productList]
    
    Context: Người dùng mô tả đơn hàng bán hàng. Hãy phân tích và trích xuất thông tin sản phẩm.
    Task: Trích xuất thông tin sản phẩm và số lượng, khớp với sản phẩm có sẵn.
    
    Examples:
    Input: 'Bán 2 chai nước suối Lavie, 1 bánh mì sandwich'
    Output: {
      "success": true,
      "items": [
        {"product_name": "Nước suối Lavie 500ml", "quantity": 2, "unit": "Chai", "matched": true},
        {"product_name": "Bánh mì sandwich", "quantity": 1, "unit": "Cái", "matched": true}
      ],
      "customer_name": "",
      "note": ""
    }
    
    Input: 'Khách hàng Anh Minh mua 5 bút bi, 3 gói mì tôm, ghi chú: khách VIP'
    Output: {
      "success": true,
      "items": [
        {"product_name": "Bút bi", "quantity": 5, "unit": "Cái", "matched": false},
        {"product_name": "Mì tôm", "quantity": 3, "unit": "Gói", "matched": false}
      ],
      "customer_name": "Anh Minh",
      "note": "khách VIP"
    }
    
    Nếu không khớp sản phẩm thì matched = false, nếu khớp thì matched = true và dùng tên chính xác từ danh sách.
    Nếu dữ liệu không liên quan đến bán hàng thì trả về {"success": false, "reason": "not_order_related"}
    
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

  Future<Map<String, dynamic>?> extractOrderData(String userInput) async {
    final products = await _productService.getActiveProducts();
    final orderResponse = await callGeminiAPI(_getOrderPromptText(userInput, products));
    final cleanOrderJson = _cleanJsonText(orderResponse);
    
    try {
      final data = jsonDecode(cleanOrderJson);
      if (data["success"] != true) {
        return null;
      }
      
      // Match products with available products
      final List<Map<String, dynamic>> processedItems = [];
      for (final item in data["items"]) {
        final productName = item["product_name"];
        final quantity = item["quantity"];
        final unit = item["unit"] ?? "Cái";
        final matched = item["matched"] ?? false;
        
        Product? matchedProduct;
        if (matched) {
          // Find exact match
          matchedProduct = products.firstWhere(
            (p) => p.name.toLowerCase() == productName.toLowerCase(),
            orElse: () => products.firstWhere(
              (p) => p.name.toLowerCase().contains(productName.toLowerCase()) ||
                     productName.toLowerCase().contains(p.name.toLowerCase()),
              orElse: () => Product(
                id: '',
                code: '',
                name: productName,
                sellingPrice: 0,
                costPrice: 0,
                unit: unit,
              ),
            ),
          );
        } else {
          // Try fuzzy matching
          matchedProduct = _findBestProductMatch(productName, products);
        }
        
        processedItems.add({
          "product": matchedProduct,
          "quantity": quantity,
          "original_name": productName,
          "matched": matchedProduct?.id.isNotEmpty == true,
        });
      }
      
      return {
        "success": true,
        "items": processedItems,
        "customer_name": data["customer_name"] ?? "",
        "note": data["note"] ?? "",
      };
    } catch (e) {
      print('Error parsing order data: $e');
      return null;
    }
  }

  Product? _findBestProductMatch(String searchName, List<Product> products) {
    final searchLower = searchName.toLowerCase();
    
    // Exact match
    for (final product in products) {
      if (product.name.toLowerCase() == searchLower) {
        return product;
      }
    }
    
    // Contains match
    for (final product in products) {
      if (product.name.toLowerCase().contains(searchLower) ||
          searchLower.contains(product.name.toLowerCase())) {
        return product;
      }
    }
    
    // Keyword match
    final searchWords = searchLower.split(' ');
    for (final product in products) {
      final productWords = product.name.toLowerCase().split(' ');
      int matchCount = 0;
      for (final word in searchWords) {
        if (productWords.any((pw) => pw.contains(word) || word.contains(pw))) {
          matchCount++;
        }
      }
      if (matchCount >= searchWords.length ~/ 2) {
        return product;
      }
    }
    
    return null;
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
      } else if (analysis["type_input"] == "order") {
        // Xử lý đơn hàng
        final orderData = await extractOrderData(userMessage);
        messageType = "order";
        
        if (orderData == null || orderData["success"] != true) {
          aiResponse = "Không thể trích xuất thông tin đơn hàng. Vui lòng mô tả rõ sản phẩm và số lượng.";
          metadata = {"success": false, "reason": "invalid_order_data"};
        } else {
          final items = orderData["items"] as List<Map<String, dynamic>>;
          final customerName = orderData["customer_name"] as String;
          final note = orderData["note"] as String;
          
          String itemsText = "";
          double estimatedTotal = 0;
          int matchedCount = 0;
          
          for (int i = 0; i < items.length; i++) {
            final item = items[i];
            final product = item["product"];
            final quantity = item["quantity"];
            final matched = item["matched"];
            final originalName = item["original_name"];
            
            if (matched && product != null) {
              final lineTotal = quantity * product.sellingPrice;
              estimatedTotal += lineTotal;
              matchedCount++;
              itemsText += "✅ ${product.name}: ${quantity} ${product.unit} × ${FormatUtils.formatCurrency(product.sellingPrice)} = ${FormatUtils.formatCurrency(lineTotal)} VNĐ\n";
            } else {
              itemsText += "❓ ${originalName}: ${quantity} (chưa khớp sản phẩm)\n";
            }
          }
          
          aiResponse = '''🛒 Đơn hàng đã được phân tích:
${customerName.isNotEmpty ? '👤 Khách hàng: $customerName\n' : ''}$itemsText
📊 Tổng ước tính: ${FormatUtils.formatCurrency(estimatedTotal)} VNĐ
✅ Khớp sản phẩm: $matchedCount/${items.length}
${note.isNotEmpty ? '📝 Ghi chú: $note\n' : ''}
${matchedCount < items.length ? '\n⚠️ Một số sản phẩm chưa khớp với kho hàng. Vui lòng kiểm tra và điều chỉnh.' : ''}''';
          
          metadata = {
            "success": true,
            "order_data": orderData,
            "estimated_total": estimatedTotal,
            "matched_count": matchedCount,
            "total_items": items.length,
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